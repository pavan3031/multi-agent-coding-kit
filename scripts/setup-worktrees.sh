#!/usr/bin/env bash
# Creates isolated git worktrees for Claude and Codex so they never touch
# each other's working directory. Idempotent -- safe to re-run.
#
# Usage: scripts/setup-worktrees.sh [claude-branch] [codex-branch]
#
# Both worktrees are created from the same resolved commit (BASE_REF,
# default "main"), so the two agents always start from an identical
# baseline regardless of what happens to main afterward. Override the
# base with: BASE_REF=origin/main scripts/setup-worktrees.sh
set -euo pipefail

CLAUDE_BRANCH="${1:-feature/claude-work}"
CODEX_BRANCH="${2:-feature/codex-work}"
BASE_REF="${BASE_REF:-main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository. Run this from within the repo (or a clone of it)." >&2
  exit 1
fi

# Resolve the canonical main repo directory even when this script is run
# from inside one of the worktrees it created (git rev-parse --show-toplevel
# would otherwise return the worktree's own path, not the main repo's).
COMMON_GIT_DIR="$(git rev-parse --git-common-dir)"
COMMON_GIT_DIR="$(cd "$COMMON_GIT_DIR" && pwd)"
REPO_ROOT="$(dirname "$COMMON_GIT_DIR")"
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"

CLAUDE_DIR="$PARENT_DIR/${REPO_NAME}-claude"
CODEX_DIR="$PARENT_DIR/${REPO_NAME}-codex"

cd "$REPO_ROOT"

# Drop stale worktree registrations (e.g. a user ran `rm -rf` on a worktree
# dir instead of scripts/cleanup-worktrees.sh) so we don't mistake a dangling
# registration for a real, usable worktree below.
git worktree prune

if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
  echo "Error: base ref '$BASE_REF' does not exist. Pass BASE_REF=<branch> to override." >&2
  exit 1
fi
BASE_SHA="$(git rev-parse "$BASE_REF")"

create_worktree() {
  local dir="$1"
  local branch="$2"

  if git worktree list --porcelain | grep -Fxq "worktree $dir"; then
    if [ ! -d "$dir" ]; then
      echo "Error: git still has a worktree registered at $dir but the directory is missing." >&2
      echo "Run 'git worktree prune' manually, then re-run this script." >&2
      exit 1
    fi
    local actual_branch
    actual_branch="$(git -C "$dir" symbolic-ref --quiet --short HEAD || true)"
    if [ "$actual_branch" != "$branch" ]; then
      echo "Error: $dir already exists but is on branch '$actual_branch', not the expected '$branch'." >&2
      echo "Resolve manually (e.g. rename/remove the worktree) and re-run." >&2
      exit 1
    fi
    echo "OK: worktree already exists: $dir (branch: $branch)"
    return
  fi

  if [ -d "$dir" ]; then
    echo "Error: $dir already exists but is not a registered git worktree. Remove or rename it and re-run." >&2
    exit 1
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Creating worktree $dir on existing branch $branch"
    git worktree add "$dir" "$branch"
  else
    echo "Creating worktree $dir on new branch $branch (from $BASE_REF @ ${BASE_SHA:0:7})"
    git worktree add -b "$branch" "$dir" "$BASE_SHA"
  fi
}

create_worktree "$CLAUDE_DIR" "$CLAUDE_BRANCH"
create_worktree "$CODEX_DIR" "$CODEX_BRANCH"

cat <<EOF

Worktrees ready (base: $BASE_REF @ ${BASE_SHA:0:7}):
   Claude: $CLAUDE_DIR   (branch: $CLAUDE_BRANCH)
   Codex:  $CODEX_DIR    (branch: $CODEX_BRANCH)

Next steps:
  1. Review/update TASKS.md so each agent's file scope is clear.
  2. Launch each agent in its own worktree:
       scripts/launch-claude.sh
       scripts/launch-codex.sh
  3. When a task is done, open a PR from its branch into main.
     CI (.github/workflows/ci.yml) will lint + test the PR automatically.

To remove the worktrees later, run scripts/cleanup-worktrees.sh.
EOF
