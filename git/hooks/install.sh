#!/usr/bin/env bash
#
# install.sh -- symlink git/hooks/post-commit into .git/hooks/ so it
# actually runs.
#
# `.git/hooks/` is local-only and untracked by design (git will not let a
# repo ship hooks that execute automatically on clone, for security
# reasons). This script is the one-time, explicit opt-in step a contributor
# runs to wire our tracked post-commit hook into their local git.
#
# pre-commit is deliberately NOT handled here: this repo already uses the
# Python `pre-commit` framework (.pre-commit-config.yaml, installed via
# `pre-commit install`) for its pre-commit stage — including the blocking
# keystore-file guard and ktlint/Android-Lint checks. A second mechanism
# symlinking into the same .git/hooks/pre-commit path would silently race
# with (and could disable) that framework's hook depending on install
# order. Run `pre-commit install` separately; this script only ever touches
# .git/hooks/post-commit.
#
# Usage:
#   bash git/hooks/install.sh

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_SRC="${REPO_ROOT}/git/hooks"
HOOKS_DST="${REPO_ROOT}/.git/hooks"

ln -sf "../../git/hooks/post-commit" "${HOOKS_DST}/post-commit"
chmod +x "${HOOKS_SRC}/post-commit"
echo "Linked post-commit -> .git/hooks/post-commit"

echo "Done. Also run 'pre-commit install' if you haven't (see .pre-commit-config.yaml)."
echo "Set PROJECT_ID and GH_PROJECT_TOKEN in your shell env to enable live board updates from post-commit."
