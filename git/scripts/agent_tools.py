"""Callable tool library for LLM-based repository agents.

This module exposes a small set of pure(ish) functions intended to be
registered as function-calling / MCP tools for an LLM agent that manages
this repository's GitHub Project (V2) board. Each function:

- Has a fully type-hinted signature and a docstring in Google style, so it
  can be introspected automatically for tool schemas (e.g. via
  ``inspect.signature`` + docstring parsing) or fed to `google-genai`'s
  automatic function calling.
- Talks to GitHub exclusively through the GraphQL ``ProjectV2`` API via
  :class:`GitHubProjectClient`, never the older REST Projects API (deprecated).
- Is side-effect-isolated: network calls live behind ``GitHubProjectClient``
  so this module can be unit-tested with a fake client.

Ported from Visual-Graph-Programming's git/scripts/agent_tools.py (via
Image-Toolkit's own copy), adapted for Project-Mobile-Fortress: status and
priority are tracked via this repo's GitHub Project (17)'s native
``ProjectV2SingleSelectField``s rather than labels -- see
``resolve_status_field``/``resolve_priority_field`` -- so ``TicketStatus``
below matches the *exact* option names configured on that field
(``gh project field-list 17 --owner ACFHarbinger``), not an invented
``status:*`` label scheme.

Environment:
    GH_PROJECT_TOKEN: A token with ``repo`` and ``project`` scopes (falls
        back to ``GITHUB_TOKEN`` if unset, for compatibility with plain
        ``gh`` / Actions-default token setups that don't need the
        project-scoped PAT this suite normally requires -- see
        ../README.md's Setup section for why a PAT is needed at all).
    GITHUB_REPOSITORY: ``owner/name``, injected automatically in Actions.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal

import requests

GRAPHQL_ENDPOINT = "https://api.github.com/graphql"
CONFIG_DIR = Path(__file__).resolve().parent.parent / "config"

# Must match this repo's Project 17 "Status" single-select field options
# exactly (`gh project field-list 17 --owner ACFHarbinger`).
TicketStatus = Literal[
    "Backlog",
    "Ready",
    "In progress",
    "Rejected",
    "In review",
    "Done",
]


class GitHubAPIError(RuntimeError):
    """Raised when the GitHub GraphQL API returns an error payload."""


@dataclass(frozen=True)
class GitHubProjectClient:
    """Thin GraphQL client scoped to ProjectV2 mutations/queries.

    Attributes:
        token: GitHub personal access token or Actions ``GITHUB_TOKEN``.
        session: Injectable ``requests.Session`` for testability.
    """

    token: str
    session: requests.Session | None = None

    def _session(self) -> requests.Session:
        return self.session or requests.Session()

    def execute(self, query: str, variables: dict[str, Any]) -> dict[str, Any]:
        """Execute a GraphQL query/mutation against the GitHub API.

        Args:
            query: A GraphQL document string.
            variables: GraphQL variables for the document.

        Returns:
            The ``data`` object from the GraphQL response.

        Raises:
            GitHubAPIError: If the response contains an ``errors`` array
                or a non-2xx HTTP status.
        """
        response = self._session().post(
            GRAPHQL_ENDPOINT,
            json={"query": query, "variables": variables},
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json",
            },
            timeout=30,
        )
        payload = response.json()
        if response.status_code >= 300 or "errors" in payload:
            raise GitHubAPIError(json.dumps(payload.get("errors", payload)))
        return payload["data"]


def load_json_config(filename: str) -> dict[str, Any]:
    """Load a JSON config file from ``git/config``.

    Args:
        filename: Basename of the config file, e.g. ``"project_labels.json"``.

    Returns:
        Parsed JSON content.
    """
    path = CONFIG_DIR / filename
    return json.loads(path.read_text(encoding="utf-8"))


def get_client() -> GitHubProjectClient:
    """Build a :class:`GitHubProjectClient` from the environment.

    Prefers ``GH_PROJECT_TOKEN`` (the project-scoped PAT this suite's CI
    workflow and ``git/README.md``'s setup instructions use), falling back
    to ``GITHUB_TOKEN`` for callers that already export that name.

    Returns:
        A configured client instance.

    Raises:
        RuntimeError: If neither env var is set.
    """
    token = os.environ.get("GH_PROJECT_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if not token:
        raise RuntimeError("GH_PROJECT_TOKEN (or GITHUB_TOKEN) is not set in the environment")
    return GitHubProjectClient(token=token)


def initialize_ticket(
    repo_owner: str,
    repo_name: str,
    title: str,
    body: str,
    component: str,
    project_id: str,
    priority: str | None = None,
    client: GitHubProjectClient | None = None,
) -> dict[str, Any]:
    """Create a GitHub issue and add it to the ProjectV2 board.

    This is the canonical entry point an agent should call when the backlog
    document describes new, unscoped work. It creates the issue, attaches
    the ``component:*`` label from ``project_labels.json``, adds the
    resulting node to the target project, and -- if ``priority`` is given --
    sets the board's native ``Priority`` field (see
    :func:`resolve_priority_field`; NOT a label).

    Args:
        repo_owner: GitHub org or user that owns the repository.
        repo_name: Repository name.
        title: Issue title, ideally mirroring the roadmap bullet text.
        body: Markdown issue body (should include a "Source" link back to
            the roadmap/changelog line it was derived from).
        component: One of the ``component:*`` labels from
            ``project_labels.json``.
        project_id: The ``ProjectV2`` node ID (not the human-facing number).
        priority: Exact option name on the board's native ``Priority``
            field (e.g. ``"P0"``), or ``None`` to leave it unset.
        client: Optional injected client for testing.

    Returns:
        A dict with ``issue_id``, ``issue_number``, and ``project_item_id``.
    """
    client = client or get_client()
    labels = _validated_labels(component)

    repo_query = """
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) { id }
    }
    """
    repo_data = client.execute(repo_query, {"owner": repo_owner, "name": repo_name})
    repository_id = repo_data["repository"]["id"]

    create_mutation = """
    mutation($repositoryId: ID!, $title: String!, $body: String!, $labelIds: [ID!]) {
      createIssue(input: {
        repositoryId: $repositoryId, title: $title, body: $body, labelIds: $labelIds
      }) {
        issue { id number }
      }
    }
    """
    label_ids = _resolve_label_ids(client, repo_owner, repo_name, labels)
    created = client.execute(
        create_mutation,
        {
            "repositoryId": repository_id,
            "title": title,
            "body": body,
            "labelIds": label_ids,
        },
    )
    issue = created["createIssue"]["issue"]

    add_to_project_mutation = """
    mutation($projectId: ID!, $contentId: ID!) {
      addProjectV2ItemById(input: { projectId: $projectId, contentId: $contentId }) {
        item { id }
      }
    }
    """
    project_data = client.execute(
        add_to_project_mutation, {"projectId": project_id, "contentId": issue["id"]}
    )
    project_item_id = project_data["addProjectV2ItemById"]["item"]["id"]

    if priority is not None:
        priority_options = resolve_priority_field(project_id, client)
        option_id = priority_options.get(priority)
        if option_id is None:
            raise GitHubAPIError(f"Unknown Priority option: {priority!r}")
        set_field_option(
            project_id=project_id,
            item_id=project_item_id,
            field_id=priority_options["__field_id__"],
            option_id=option_id,
            client=client,
        )

    return {
        "issue_id": issue["id"],
        "issue_number": issue["number"],
        "project_item_id": project_item_id,
    }


def set_field_option(
    project_id: str,
    item_id: str,
    field_id: str,
    option_id: str,
    client: GitHubProjectClient | None = None,
) -> dict[str, Any]:
    """Set a single-select field's value on a project item.

    Field-agnostic primitive shared by :func:`transition_ticket` (Status)
    and priority assignment (Priority) -- both are the same mutation
    against a different field/option ID pair.

    Args:
        project_id: ``ProjectV2`` node ID.
        item_id: ``ProjectV2Item`` node ID for the target ticket.
        field_id: Node ID of the target single-select field.
        option_id: Node ID of the target option.
        client: Optional injected client for testing.

    Returns:
        A dict with the updated item's ``project_item_id``.
    """
    client = client or get_client()
    mutation = """
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId,
        itemId: $itemId,
        fieldId: $fieldId,
        value: { singleSelectOptionId: $optionId }
      }) {
        projectV2Item { id }
      }
    }
    """
    data = client.execute(
        mutation,
        {
            "projectId": project_id,
            "itemId": item_id,
            "fieldId": field_id,
            "optionId": option_id,
        },
    )
    return {"project_item_id": data["updateProjectV2ItemFieldValue"]["projectV2Item"]["id"]}


def transition_ticket(
    project_id: str,
    item_id: str,
    status_field_id: str,
    status_option_id: str,
    new_status: TicketStatus,
    client: GitHubProjectClient | None = None,
) -> dict[str, Any]:
    """Move a project item to a new single-select status option.

    Callers are expected to have already resolved ``status_field_id`` and
    ``status_option_id`` via :func:`resolve_status_field` -- this function
    performs the mutation only, keeping it a minimal, auditable unit that
    an LLM agent can invoke repeatedly without re-deriving IDs.

    Args:
        project_id: ``ProjectV2`` node ID.
        item_id: ``ProjectV2Item`` node ID for the target ticket.
        status_field_id: Node ID of the "Status" single-select field.
        status_option_id: Node ID of the target option (e.g. ``"In progress"``).
        new_status: Status option name, used only for the return payload /
            logging -- not sent to the API (the ID is what's authoritative).
        client: Optional injected client for testing.

    Returns:
        A dict confirming the applied ``new_status`` and updated item id.
    """
    result = set_field_option(project_id, item_id, status_field_id, status_option_id, client)
    return {"new_status": new_status, "project_item_id": result["project_item_id"]}


def close_ticket(
    issue_id: str,
    reason: Literal["COMPLETED", "NOT_PLANNED"] = "COMPLETED",
    client: GitHubProjectClient | None = None,
) -> dict[str, Any]:
    """Close a GitHub issue.

    Args:
        issue_id: The issue's GraphQL node ID.
        reason: GitHub's closure reason enum.
        client: Optional injected client for testing.

    Returns:
        A dict with the closed issue's ``state``.
    """
    client = client or get_client()
    mutation = """
    mutation($issueId: ID!, $reason: IssueClosedStateReason!) {
      closeIssue(input: { issueId: $issueId, stateReason: $reason }) {
        issue { state }
      }
    }
    """
    data = client.execute(mutation, {"issueId": issue_id, "reason": reason})
    return {"state": data["closeIssue"]["issue"]["state"]}


def resolve_single_select_field(
    project_id: str, field_name: str, client: GitHubProjectClient | None = None
) -> dict[str, Any]:
    """Fetch a named single-select field and its option IDs for a project.

    Args:
        project_id: ``ProjectV2`` node ID.
        field_name: Exact field name as configured on the board (e.g.
            ``"Status"``, ``"Priority"``).
        client: Optional injected client for testing.

    Returns:
        A dict mapping option name -> option node ID, plus the field's own
        node ID under the ``"__field_id__"`` key.

    Raises:
        GitHubAPIError: If no single-select field with that exact name
            exists on the project.
    """
    client = client or get_client()
    query = """
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 50) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
                options { id name }
              }
            }
          }
        }
      }
    }
    """
    data = client.execute(query, {"projectId": project_id})
    for field in data["node"]["fields"]["nodes"]:
        if field and field.get("name") == field_name:
            result = {opt["name"]: opt["id"] for opt in field["options"]}
            result["__field_id__"] = field["id"]
            return result
    raise GitHubAPIError(f"No {field_name!r} single-select field found on project")


def resolve_status_field(
    project_id: str, client: GitHubProjectClient | None = None
) -> dict[str, Any]:
    """Fetch the "Status" single-select field and its option IDs for a project.

    Args:
        project_id: ``ProjectV2`` node ID.
        client: Optional injected client for testing.

    Returns:
        A dict mapping option name -> option node ID, plus the field's own
        node ID under the ``"__field_id__"`` key.
    """
    return resolve_single_select_field(project_id, "Status", client)


def resolve_priority_field(
    project_id: str, client: GitHubProjectClient | None = None
) -> dict[str, Any]:
    """Fetch the "Priority" single-select field and its option IDs for a project.

    This repo's Project 17 board has a native ``Priority`` field (``P0``,
    ``P1``, ``P2`` as of writing) -- prefer it over an invented
    ``priority:*`` label scheme, same rationale as ``resolve_status_field``.

    Args:
        project_id: ``ProjectV2`` node ID.
        client: Optional injected client for testing.

    Returns:
        A dict mapping option name -> option node ID, plus the field's own
        node ID under the ``"__field_id__"`` key.
    """
    return resolve_single_select_field(project_id, "Priority", client)


def _validated_labels(component: str) -> list[str]:
    """Validate a component label against ``project_labels.json``.

    Priority is not a label in this repo's taxonomy (see the native
    ``Priority`` field via :func:`resolve_priority_field`), so only
    ``component`` is validated here.

    Args:
        component: A ``component:*`` label name.

    Returns:
        ``[component]`` if recognized.

    Raises:
        ValueError: If the label is not present in the taxonomy.
    """
    taxonomy = load_json_config("project_labels.json")
    known_components = {item["name"] for item in taxonomy["components"]}
    if component not in known_components:
        raise ValueError(f"Unknown component label: {component}")
    return [component]


def _resolve_label_ids(
    client: GitHubProjectClient, owner: str, name: str, label_names: list[str]
) -> list[str]:
    """Resolve label name strings to GraphQL node IDs, creating missing ones.

    Args:
        client: Active GraphQL client.
        owner: Repository owner.
        name: Repository name.
        label_names: Label names to resolve.

    Returns:
        List of label node IDs in the same order as ``label_names``.
    """
    query = """
    query($owner: String!, $name: String!, $labelName: String!) {
      repository(owner: $owner, name: $name) {
        label(name: $labelName) { id }
        id
      }
    }
    """
    label_ids: list[str] = []
    for label_name in label_names:
        data = client.execute(
            query, {"owner": owner, "name": name, "labelName": label_name}
        )
        existing = data["repository"]["label"]
        if existing:
            label_ids.append(existing["id"])
            continue
        label_ids.append(
            _create_label(client, data["repository"]["id"], label_name)
        )
    return label_ids


def resolve_project_id(
    owner: str, number: int, client: GitHubProjectClient | None = None
) -> str:
    """Resolve a ``ProjectV2`` node ID from its human-facing owner + number.

    GitHub's GraphQL schema exposes ``ProjectV2Owner`` polymorphically as
    either a ``user`` or an ``organization`` root, so both are queried and
    whichever resolves is used.

    Args:
        owner: Login of the project owner (user or organization).
        number: The ``ProjectV2`` number shown in its URL (e.g. the ``16``
            in ``.../users/ACFHarbinger/projects/17``, this repo's board).
        client: Optional injected client for testing.

    Returns:
        The ``ProjectV2`` node ID.

    Raises:
        GitHubAPIError: If neither a user nor an organization named
            ``owner`` has a project numbered ``number``.
    """
    client = client or get_client()
    query = """
    query($owner: String!, $number: Int!) {
      user(login: $owner) { projectV2(number: $number) { id } }
      organization(login: $owner) { projectV2(number: $number) { id } }
    }
    """
    data = client.execute(query, {"owner": owner, "number": number})
    project = (data.get("organization") or {}).get("projectV2") or (
        data.get("user") or {}
    ).get("projectV2")
    if project is None:
        raise GitHubAPIError(f"Could not resolve ProjectV2 #{number} for owner {owner!r}")
    return project["id"]


def find_issue_node_id(
    repo_owner: str, repo_name: str, issue_number: int, client: GitHubProjectClient | None = None
) -> str:
    """Resolve an issue's GraphQL node ID from its human-facing number.

    Args:
        repo_owner: GitHub org or user that owns the repository.
        repo_name: Repository name.
        issue_number: The GitHub issue number (e.g. 42 for issue "#42").
        client: Optional injected client for testing.

    Returns:
        The issue's node ID.

    Raises:
        GitHubAPIError: If no such issue exists in the repository.
    """
    client = client or get_client()
    query = """
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        issue(number: $number) { id }
      }
    }
    """
    data = client.execute(query, {"owner": repo_owner, "name": repo_name, "number": issue_number})
    issue = data["repository"]["issue"]
    if issue is None:
        raise GitHubAPIError(f"Issue #{issue_number} not found in {repo_owner}/{repo_name}")
    return issue["id"]


def add_item_to_project(
    project_id: str, content_node_id: str, client: GitHubProjectClient | None = None
) -> str:
    """Add an existing issue (or PR) to a ``ProjectV2`` board.

    Idempotent: calling this again for an issue already on the board
    returns the existing item's ID rather than duplicating it.

    Args:
        project_id: ``ProjectV2`` node ID.
        content_node_id: Node ID of the issue/PR to add.
        client: Optional injected client for testing.

    Returns:
        The ``ProjectV2Item`` node ID.
    """
    client = client or get_client()
    mutation = """
    mutation($projectId: ID!, $contentId: ID!) {
      addProjectV2ItemById(input: { projectId: $projectId, contentId: $contentId }) {
        item { id }
      }
    }
    """
    data = client.execute(mutation, {"projectId": project_id, "contentId": content_node_id})
    return data["addProjectV2ItemById"]["item"]["id"]


def list_project_items(
    project_id: str, client: GitHubProjectClient | None = None
) -> list[dict[str, Any]]:
    """List every item currently on a ``ProjectV2`` board.

    Used to build both the LLM's board-state context and the
    issue-number -> node-ID lookup table needed to apply transitions/closes
    against existing tickets.

    Args:
        project_id: ``ProjectV2`` node ID.
        client: Optional injected client for testing.

    Returns:
        A list of dicts, one per board item, each with ``item_id``,
        ``issue_id``, ``issue_number``, ``title``, and ``state`` (issue
        items only -- non-issue content, e.g. draft items, is skipped).
    """
    client = client or get_client()
    query = """
    query($projectId: ID!, $after: String) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100, after: $after) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              content {
                ... on Issue { id number title state }
              }
            }
          }
        }
      }
    }
    """
    items: list[dict[str, Any]] = []
    after: str | None = None
    while True:
        data = client.execute(query, {"projectId": project_id, "after": after})
        page = data["node"]["items"]
        for node in page["nodes"]:
            content = node.get("content")
            if not content or "number" not in content:
                continue  # skip draft items / PRs without an issue number
            items.append(
                {
                    "item_id": node["id"],
                    "issue_id": content["id"],
                    "issue_number": content["number"],
                    "title": content["title"],
                    "state": content["state"],
                }
            )
        if not page["pageInfo"]["hasNextPage"]:
            break
        after = page["pageInfo"]["endCursor"]
    return items


def _create_label(client: GitHubProjectClient, repository_id: str, label_name: str) -> str:
    """Create a repository label from the taxonomy's configured color.

    Args:
        client: Active GraphQL client.
        repository_id: Repository node ID.
        label_name: Label name to create, must exist in ``project_labels.json``.

    Returns:
        The newly created label's node ID.
    """
    taxonomy = load_json_config("project_labels.json")
    all_labels = [entry for group in ("components", "agent") for entry in taxonomy[group]]
    match = next(item for item in all_labels if item["name"] == label_name)

    mutation = """
    mutation($repositoryId: ID!, $name: String!, $color: String!, $description: String!) {
      createLabel(input: {
        repositoryId: $repositoryId, name: $name, color: $color, description: $description
      }) {
        label { id }
      }
    }
    """
    data = client.execute(
        mutation,
        {
            "repositoryId": repository_id,
            "name": match["name"],
            "color": match["color"],
            "description": match["description"],
        },
    )
    return data["createLabel"]["label"]["id"]
