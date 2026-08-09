"""Roadmap/Changelog -> GitHub Project (V2) backlog synchronizer.

Parses ``docs/moon/ROADMAP.md`` and ``docs/moon/CHANGELOG.md``, asks Gemini 2.5 Pro to
reconcile the described work against the current board snapshot, and applies
the resulting diff via the ``ProjectV2`` GraphQL API using the primitives in
:mod:`agent_tools`.

Ported from Visual-Graph-Programming's git/scripts/sync_backlog.py (via
Image-Toolkit's own copy), adapted for Project-Mobile-Fortress.

Design goals:
    - Never let the LLM call the GitHub API directly. It only ever returns
      structured JSON describing an intended diff; this script validates
      that diff against ``automation_rules.yaml`` (circuit breaker, allowed
      auto-transitions) before executing any mutation.
    - Idempotent: re-running with no doc changes should produce an empty
      diff and touch nothing.

A deterministic (non-LLM) mode is tracked as future work -- see
docs/moon/roadmaps/repo_automation.md's RA4 -- rather than implemented here;
this script currently always calls Gemini.

Usage:
    python git/scripts/sync_backlog.py --repo-owner ACFHarbinger \\
        --repo-name Project-Mobile-Fortress --project-id PVT_kwHOAV-XTM4BfYSx

Environment:
    GH_PROJECT_TOKEN: token with repo + project scopes (falls back to
        GITHUB_TOKEN, see agent_tools.get_client).
    GEMINI_API_KEY: API key for `google-genai`.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml
from google import genai

from .agent_tools import (
    initialize_ticket,
    transition_ticket,
    close_ticket,
    resolve_status_field,
    resolve_priority_field,
    resolve_project_id,
    list_project_items,
    load_json_config,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("sync_backlog")

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
CONFIG_DIR = REPO_ROOT / "git" / "config"

SYSTEM_PROMPT = """You are a backlog reconciliation agent for a software \
project's GitHub Project board. You will be given the contents of \
docs/moon/ROADMAP.md and docs/moon/CHANGELOG.md, plus a JSON snapshot of the current \
board. Return ONLY a JSON object (no prose, no markdown fences) matching \
this schema:

{
  "creates": [
    {"title": str, "body": str, "component": str, "priority": str | null}
  ],
  "transitions": [
    {"issue_number": int, "new_status": str}
  ],
  "closes": [
    {"issue_number": int, "reason": "COMPLETED" | "NOT_PLANNED"}
  ],
  "ambiguous": [
    {"description": str, "reason": str}
  ]
}

Rules:
- "component" must be one of the component:* labels provided in the taxonomy.
- "priority", if set, must be one of the exact option names on the board's \
native Priority field, given in "board_fields" below (e.g. "P0") -- it is \
NOT a label.
- "new_status" must be exactly one of the option names on the board's \
native Status field, given in "board_fields" below (e.g. "In progress") -- \
it is NOT a label and must match verbatim, including capitalization and \
spacing.
- If a roadmap item's disposition is unclear, put it in "ambiguous" instead \
of guessing -- do not invent creates/transitions/closes for it.
- Never propose closing an issue that is not clearly marked done in the \
changelog.
- "body" MUST be a thin pointer, not a restated spec: one line linking to \
the source roadmap file and item ID (e.g. "See `docs/moon/roadmaps/<file>.md` \
-- `<ID>` -- for the current deliverable description, effort, and status."), \
plus one sentence noting it is a pointer, not a spec copy. Do NOT restate the \
roadmap item's implementation details, technology choices, or effort in the \
body -- this is a per-issue drift-prevention rule adopted 2026-08-09 after \
the roadmap's shared-core language changed (Rust to C++) and several issue \
bodies (S1-S7, P2, P5, Q3, IOS3, IOS7) kept describing Rust/hecs/UniFFI/rkyv \
for multiple commits because only ticket titles/statuses were being \
reconciled, never restated body prose. See \
`docs/moon/roadmaps/repo_automation.md` RA5.
"""


@dataclass(frozen=True)
class SyncPlan:
    """Structured diff proposed by the LLM, pre-validation.

    Attributes:
        creates: New tickets to open.
        transitions: Status moves for existing tickets.
        closes: Issues to close, with a closure reason.
        ambiguous: Items the model declined to resolve automatically.
    """

    creates: list[dict[str, Any]]
    transitions: list[dict[str, Any]]
    closes: list[dict[str, Any]]
    ambiguous: list[dict[str, Any]]

    @classmethod
    def from_json(cls, payload: dict[str, Any]) -> "SyncPlan":
        """Build a :class:`SyncPlan` from parsed LLM JSON output.

        Args:
            payload: Parsed JSON dict matching the documented schema.

        Returns:
            A populated :class:`SyncPlan`.
        """
        return cls(
            creates=payload.get("creates", []),
            transitions=payload.get("transitions", []),
            closes=payload.get("closes", []),
            ambiguous=payload.get("ambiguous", []),
        )

    def total_mutations(self) -> int:
        """Count destructive/creative mutations (excludes ``ambiguous``).

        Returns:
            Sum of pending creates, transitions, and closes.
        """
        return len(self.creates) + len(self.transitions) + len(self.closes)


def load_rules() -> dict[str, Any]:
    """Load ``automation_rules.yaml``.

    Returns:
        Parsed YAML config as a dict.
    """
    return yaml.safe_load((CONFIG_DIR / "automation_rules.yaml").read_text(encoding="utf-8"))


def load_source_documents(rules: dict[str, Any]) -> str:
    """Concatenate the configured source-of-truth markdown docs.

    Args:
        rules: Parsed ``automation_rules.yaml`` content.

    Returns:
        Concatenated markdown, each doc prefixed with a ``# FILE:`` marker.

    Raises:
        FileNotFoundError: If a configured source document is missing.
    """
    chunks: list[str] = []
    for relative_path in rules["sync"]["source_documents"]:
        doc_path = REPO_ROOT / relative_path
        if not doc_path.exists():
            raise FileNotFoundError(f"Configured source document missing: {doc_path}")
        chunks.append(f"# FILE: {relative_path}\n\n{doc_path.read_text(encoding='utf-8')}")
    return "\n\n---\n\n".join(chunks)


def request_plan(
    client: genai.Client,
    model: str,
    source_text: str,
    board_snapshot: dict[str, Any],
    taxonomy: dict[str, Any],
    board_fields: dict[str, Any],
) -> SyncPlan:
    """Ask Gemini to reconcile source docs against the board snapshot.

    Args:
        client: Configured ``google-genai`` client.
        model: Model identifier, e.g. ``"gemini-2.5-pro"``.
        source_text: Concatenated roadmap/changelog markdown.
        board_snapshot: JSON-serializable snapshot of current board items.
        taxonomy: Contents of ``project_labels.json`` (component/agent labels).
        board_fields: ``{"status": [...option names...], "priority": [...]}``
            -- the board's native single-select field option names, so the
            model proposes values that will actually resolve (see
            ``apply_plan``'s direct, non-fuzzy lookups).

    Returns:
        A validated :class:`SyncPlan`.

    Raises:
        ValueError: If the model's response is not valid JSON.
    """
    prompt = (
        f"{SYSTEM_PROMPT}\n\n"
        f"## Label taxonomy\n{json.dumps(taxonomy, indent=2)}\n\n"
        f"## Board fields (native Status/Priority option names)\n{json.dumps(board_fields, indent=2)}\n\n"
        f"## Current board snapshot\n{json.dumps(board_snapshot, indent=2)}\n\n"
        f"## Source documents\n{source_text}"
    )
    response = client.models.generate_content(
        model=model,
        contents=prompt,
        config={"temperature": 0.1, "max_output_tokens": 4096},
    )
    try:
        payload = json.loads(response.text)
    except (json.JSONDecodeError, TypeError) as exc:
        raise ValueError(f"Gemini did not return valid JSON: {response.text!r}") from exc
    return SyncPlan.from_json(payload)


def enforce_circuit_breaker(plan: SyncPlan, rules: dict[str, Any]) -> None:
    """Refuse to proceed if the plan exceeds the configured mutation budget.

    Args:
        plan: Proposed sync plan.
        rules: Parsed ``automation_rules.yaml`` content.

    Raises:
        RuntimeError: If ``plan.total_mutations()`` exceeds
            ``sync.conflict_resolution.max_auto_mutations_per_run``.
    """
    budget = rules["sync"]["conflict_resolution"]["max_auto_mutations_per_run"]
    if plan.total_mutations() > budget:
        raise RuntimeError(
            f"Refusing to apply {plan.total_mutations()} mutations; "
            f"exceeds configured budget of {budget}. Review manually."
        )


def apply_plan(
    plan: SyncPlan,
    rules: dict[str, Any],
    repo_owner: str,
    repo_name: str,
    project_id: str,
    issue_lookup: dict[int, dict[str, Any]],
) -> None:
    """Execute a validated :class:`SyncPlan` against the live board.

    Args:
        plan: The validated plan to apply.
        rules: Parsed ``automation_rules.yaml`` content, used to check which
            status transitions are permitted without human confirmation.
        repo_owner: GitHub org/user owning the repository.
        repo_name: Repository name.
        project_id: ``ProjectV2`` node ID.
        issue_lookup: Map of issue number -> ``{"issue_id", "item_id"}``
            for existing board items, used to resolve transitions/closes.
    """
    allowed_transitions = set(rules["sync"]["auto_transition_allowed"])
    status_options = resolve_status_field(project_id)

    for item in plan.creates:
        logger.info("Creating ticket: %s", item["title"])
        initialize_ticket(
            repo_owner=repo_owner,
            repo_name=repo_name,
            title=item["title"],
            body=item["body"],
            component=item["component"],
            priority=item.get("priority"),
            project_id=project_id,
        )

    for item in plan.transitions:
        new_status = item["new_status"]
        if new_status not in allowed_transitions:
            logger.warning(
                "Skipping transition to %s for #%s -- requires human confirmation",
                new_status,
                item["issue_number"],
            )
            continue
        target = issue_lookup.get(item["issue_number"])
        if not target:
            logger.warning("Unknown issue #%s in transition plan; skipping", item["issue_number"])
            continue
        # Direct lookup -- new_status is expected to already be an exact
        # board option name (e.g. "In progress"), not a "status:*" label,
        # per SYSTEM_PROMPT's schema rules. No string-mangling fallback:
        # a mismatch here means the model didn't follow the schema and
        # should be logged loudly, not silently coerced into something
        # that happens to match.
        option_id = status_options.get(new_status)
        if not option_id:
            logger.warning(
                "No matching board Status option for %r (valid: %s); skipping #%s",
                new_status,
                sorted(k for k in status_options if k != "__field_id__"),
                item["issue_number"],
            )
            continue
        transition_ticket(
            project_id=project_id,
            item_id=target["item_id"],
            status_field_id=status_options["__field_id__"],
            status_option_id=option_id,
            new_status=new_status,
        )

    for item in plan.closes:
        target = issue_lookup.get(item["issue_number"])
        if not target:
            logger.warning("Unknown issue #%s in close plan; skipping", item["issue_number"])
            continue
        logger.info("Closing #%s (%s)", item["issue_number"], item["reason"])
        close_ticket(issue_id=target["issue_id"], reason=item["reason"])

    for item in plan.ambiguous:
        logger.info("Ambiguous, flagged for human: %s -- %s", item["description"], item["reason"])


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments.

    Each flag falls back to the environment variable used by the GitHub
    Actions/Forgejo/Gitea/GitLab CI invocations (``GITHUB_REPOSITORY``,
    ``GITHUB_PROJECT_OWNER``, ``PROJECT_NUMBER``) so the script can be run
    either as ``sync_backlog.py --repo-owner ... --project-id ...`` locally
    or bare (env-driven) in CI, matching how ``check_commit_ref.py`` and the
    legacy backend/scripts/github/sync_backlog.py were invoked.

    Returns:
        Parsed argument namespace.
    """
    owner_repo = os.environ.get("GITHUB_REPOSITORY", "")
    env_owner, _, env_repo = owner_repo.partition("/")

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-owner", default=env_owner or None, required=not env_owner)
    parser.add_argument("--repo-name", default=env_repo or None, required=not env_repo)
    parser.add_argument(
        "--project-id",
        default=None,
        help="ProjectV2 node ID. If omitted, resolved from --project-owner/--project-number "
        "(or GITHUB_PROJECT_OWNER/PROJECT_NUMBER).",
    )
    parser.add_argument(
        "--project-owner",
        default=os.environ.get("GITHUB_PROJECT_OWNER") or env_owner or None,
    )
    parser.add_argument(
        "--project-number",
        type=int,
        default=int(os.environ["PROJECT_NUMBER"]) if os.environ.get("PROJECT_NUMBER") else None,
    )
    parser.add_argument("--dry-run", action="store_true", help="Print the plan, apply nothing")
    args = parser.parse_args()

    if not args.project_id and not (args.project_owner and args.project_number):
        parser.error(
            "either --project-id, or both --project-owner/--project-number "
            "(or GITHUB_PROJECT_OWNER/PROJECT_NUMBER), must be provided"
        )
    return args


def build_board_state(project_id: str) -> tuple[dict[str, Any], dict[int, dict[str, Any]]]:
    """Fetch the current board and derive both the LLM snapshot and lookup.

    Args:
        project_id: ``ProjectV2`` node ID.

    Returns:
        A ``(board_snapshot, issue_lookup)`` tuple:
        ``board_snapshot`` is a JSON-serializable summary handed to the LLM
        as context; ``issue_lookup`` maps issue number to
        ``{"issue_id": ..., "item_id": ...}`` for applying transitions/closes.
    """
    items = list_project_items(project_id)
    board_snapshot = {
        "items": [
            {"issue_number": i["issue_number"], "title": i["title"], "state": i["state"]}
            for i in items
        ]
    }
    issue_lookup = {
        i["issue_number"]: {"issue_id": i["issue_id"], "item_id": i["item_id"]} for i in items
    }
    return board_snapshot, issue_lookup


def main() -> None:
    """Entry point: parse docs, request a plan, validate, and apply it."""
    args = parse_args()
    rules = load_rules()
    taxonomy = load_json_config("project_labels.json")
    source_text = load_source_documents(rules)

    project_id = args.project_id or resolve_project_id(args.project_owner, args.project_number)
    board_snapshot, issue_lookup = build_board_state(project_id)
    status_options = resolve_status_field(project_id)
    priority_options = resolve_priority_field(project_id)
    board_fields = {
        "status": sorted(k for k in status_options if k != "__field_id__"),
        "priority": sorted(k for k in priority_options if k != "__field_id__"),
    }

    client = genai.Client()
    plan = request_plan(
        client=client,
        model=rules["llm"]["model"],
        source_text=source_text,
        board_snapshot=board_snapshot,
        taxonomy=taxonomy,
        board_fields=board_fields,
    )

    enforce_circuit_breaker(plan, rules)

    if args.dry_run:
        logger.info("Dry run -- proposed plan:\n%s", json.dumps(plan.__dict__, indent=2))
        return

    apply_plan(
        plan=plan,
        rules=rules,
        repo_owner=args.repo_owner,
        repo_name=args.repo_name,
        project_id=project_id,
        issue_lookup=issue_lookup,
    )


if __name__ == "__main__":
    main()
