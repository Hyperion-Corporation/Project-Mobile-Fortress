# Code Review Rules

- Review for correctness first, then simplification, then style — don't bikeshed formatting on a PR with a real bug.
- Flag missing test coverage for new branches/edge cases explicitly, with a concrete failing scenario, not just "add more tests."
- Call out anything allocating inside the `GameLoop` update/render path, and anything touching I/O or `Context` from `engine/` — these are the two most common ways an otherwise-correct PR degrades frame pacing or breaks testability.
- Call out security-sensitive changes (signing config, backend auth, `local.properties` handling) even if outside the PR's stated scope.
- Prefer suggesting the specific fix over describing the problem abstractly — reviewers should be able to act on a comment without re-deriving it.
- Approve when the change is a net improvement, not only when it is perfect.
