# Task Board

This file is the single source of truth for **who owns what**. Every agent
(and every human) working in this repo must check this table before editing
a file. If a file or directory isn't listed as owned by you, don't touch it —
open a PR against the owner instead, or add a row here and get it agreed
first.

Update this table whenever work is split up or reassigned. Keep branches and
worktrees (see [scripts/setup-worktrees.sh](scripts/setup-worktrees.sh)) in
sync with the "Branch" column.

| Task | Owner | Branch | Status | Files/Directories owned |
|------|-------|--------|--------|--------------------------|
| Build REST API for sample app | Claude | `feature/claude-work` | In Progress | `examples/sample-app/src/api/`, `examples/sample-app/test/api/` |
| Build CLI/frontend for sample app | Astra | `feature/astra-work` | In Progress | `examples/sample-app/src/cli/`, `examples/sample-app/test/cli/` |
| Review + merge PRs | Human | `main` | Ongoing | `.github/`, repo-wide config |

## Adding a new task

1. Add a row above with a clear, narrow file/directory scope.
2. Create (or reuse) a branch/worktree for the owner via `scripts/setup-worktrees.sh`.
3. Have the agent update `Status` as it progresses: `Not Started` -> `In Progress` -> `In Review` -> `Done`.
4. Land the work via a PR into `main`; CI (`.github/workflows/ci.yml`) runs lint + test before merge.

## Rules of thumb

- Two owners should never share the same file path in the "owned" column. If
  work genuinely overlaps a shared file, call it out explicitly in a row of
  its own with both owners named, and coordinate before editing.
- Prefer splitting by directory (e.g. `src/api/` vs `src/cli/`) over splitting
  by line ranges within the same file — worktrees make directory-level splits
  conflict-free, but the same file edited in two worktrees will still conflict
  at merge time.
- If you finish your scope early, update this table and pick up (or ask for)
  a new row rather than drifting into someone else's files.
