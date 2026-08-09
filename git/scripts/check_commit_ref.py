"""Commit-message ticket reference checker and board updater.

Invoked by ``git/hooks/post-commit`` (see that file for the wiring
strategy). Reads the just-made commit message, checks it against the regex
patterns configured in ``automation_rules.yaml``, and -- if a ticket
reference is found -- transitions that issue to the board status configured
as ``commit_ref.transition_to`` (``"In progress"`` by default) on the
ProjectV2 board via :mod:`agent_tools`.

Ported from Visual-Graph-Programming's git/scripts/check_commit_ref.py (via
Image-Toolkit's own copy), adapted for Project-Mobile-Fortress.

This script is deliberately fail-open: any network/API error is logged and
swallowed so that a flaky GitHub API call never blocks a local commit.

Usage:
    python git/scripts/check_commit_ref.py --commit-msg-file .git/COMMIT_EDITMSG

Environment:
    GH_PROJECT_TOKEN: token with repo + project scopes (falls back to
        GITHUB_TOKEN, see agent_tools.get_client). Both PROJECT_ID and this
        must be set for the live board update to run at all -- otherwise
        this script only does the local regex check.
    PROJECT_ID: ProjectV2 node ID to update (see git/README.md's Setup).
    GITHUB_REPOSITORY: ``owner/name``. Falls back to parsing
        ``git remote get-url origin`` for local (non-Actions) use.
"""

from __future__ import annotations

import argparse
import logging
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml

from .agent_tools import add_item_to_project, find_issue_node_id, resolve_status_field, transition_ticket

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger("check_commit_ref")

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
CONFIG_PATH = REPO_ROOT / "git" / "config" / "automation_rules.yaml"


def load_patterns() -> tuple[list[re.Pattern[str]], bool]:
    """Load commit-ref regex patterns and the block-on-missing policy.

    Returns:
        Tuple of (compiled patterns, ``block_commit_on_missing_ref`` flag).
    """
    rules = yaml.safe_load(CONFIG_PATH.read_text(encoding="utf-8"))
    commit_ref = rules["commit_ref"]
    patterns = [re.compile(p) for p in commit_ref["patterns"]]
    return patterns, bool(commit_ref["block_commit_on_missing_ref"])


def load_transition_status() -> str:
    """Load the board status a found ticket reference should transition to.

    Returns:
        The exact Status field option name from
        ``commit_ref.transition_to`` (defaults to ``"In progress"`` if
        unset, matching ``automation_rules.yaml``'s shipped default).
    """
    rules = yaml.safe_load(CONFIG_PATH.read_text(encoding="utf-8"))
    return rules.get("commit_ref", {}).get("transition_to", "In progress")


def resolve_repo_slug() -> tuple[str, str] | None:
    """Resolve ``(owner, name)`` from ``GITHUB_REPOSITORY`` or the git remote.

    Returns:
        A ``(owner, name)`` tuple, or ``None`` if neither source resolves
        (e.g. no ``origin`` remote, or it's not a GitHub URL).
    """
    env_repo = os.environ.get("GITHUB_REPOSITORY", "")
    if "/" in env_repo:
        owner, _, name = env_repo.partition("/")
        return owner, name

    try:
        url = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True, text=True, check=True, cwd=REPO_ROOT,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

    match = re.search(r"github\.com[:/]([^/]+)/([^/.]+?)(?:\.git)?$", url)
    return (match.group(1), match.group(2)) if match else None


def extract_issue_number(message: str, patterns: list[re.Pattern[str]]) -> int | None:
    """Find the first ticket/issue number referenced in a commit message.

    Args:
        message: Full commit message text.
        patterns: Compiled regex patterns, each expected to capture the
            issue number in its last capture group.

    Returns:
        The referenced issue number, or ``None`` if no pattern matched.
    """
    for pattern in patterns:
        match = pattern.search(message)
        if match:
            return int(match.group(match.lastindex or 1))
    return None


def update_board_best_effort(issue_number: int, project_id: str) -> None:
    """Attempt to move the referenced issue to the configured board status.

    Failures are logged, never raised -- this must never block `git commit`.

    Args:
        issue_number: The issue number parsed from the commit message.
        project_id: ``ProjectV2`` node ID to update.
    """
    try:
        repo_slug = resolve_repo_slug()
        if repo_slug is None:
            logger.warning("Could not resolve owner/repo (no GITHUB_REPOSITORY, no origin remote); skipping")
            return
        owner, name = repo_slug

        new_status = load_transition_status()
        status_options = resolve_status_field(project_id)
        option_id = status_options.get(new_status)
        if not option_id:
            logger.warning("commit_ref.transition_to=%r is not a valid Status option; skipping", new_status)
            return

        issue_node_id = find_issue_node_id(owner, name, issue_number)
        # Idempotent: returns the existing item if the issue is already on
        # the board, adds it otherwise -- either way we get an item_id to
        # transition.
        item_id = add_item_to_project(project_id, issue_node_id)
        transition_ticket(
            project_id=project_id,
            item_id=item_id,
            status_field_id=status_options["__field_id__"],
            status_option_id=option_id,
            new_status=new_status,
        )
        logger.info("Transitioned issue #%s to %r on project %s", issue_number, new_status, project_id)
    except Exception:  # noqa: BLE001 - fail-open by design, see module docstring
        logger.exception("Board update failed (non-blocking); continuing")


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments.

    Returns:
        Parsed argument namespace.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--commit-msg-file",
        default=".git/COMMIT_EDITMSG",
        help="Path to the commit message file written by git",
    )
    return parser.parse_args()


def main() -> int:
    """Entry point: check the last commit message for a ticket reference.

    Returns:
        Always ``0`` unless ``block_commit_on_missing_ref`` is enabled and
        no reference was found, in which case ``1`` is returned so the
        calling hook can abort the commit.
    """
    args = parse_args()
    message_path = Path(args.commit_msg_file)
    if not message_path.exists():
        logger.warning("Commit message file not found: %s; skipping check", message_path)
        return 0

    message = message_path.read_text(encoding="utf-8")
    patterns, block_on_missing = load_patterns()
    issue_number = extract_issue_number(message, patterns)

    if issue_number is None:
        logger.warning("No ticket reference found in commit message")
        return 1 if block_on_missing else 0

    logger.info("Found ticket reference: #%s", issue_number)
    project_id = os.environ.get("PROJECT_ID")
    token = os.environ.get("GH_PROJECT_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if project_id and token:
        update_board_best_effort(issue_number, project_id)
    else:
        logger.info("GH_PROJECT_TOKEN/PROJECT_ID not set; skipping live board update")
    return 0


if __name__ == "__main__":
    sys.exit(main())
