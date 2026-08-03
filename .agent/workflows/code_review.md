# Workflow: Code Review

1. Read the diff for correctness first: does it do what the PR description claims, and does it handle the edge cases in `.agent/rules/testing_qa.md`?
2. Check the `GameLoop`/`engine/` hot path specifically for new allocations or blocking calls — grep the diff for `new`, list/map literals, and I/O calls inside `update()`/`render()`.
3. Check lifecycle-affecting diffs against `.agent/rules/android_lifecycle.md` — thread start/stop pairing, save/restore correctness.
4. Verify test coverage matches the change's risk (see `.agent/rules/code_review.md`) — request a concrete missing scenario, not a vague "add tests."
5. Leave actionable comments (suggested diff, not just a description of the problem) and approve once the change is a net improvement.
