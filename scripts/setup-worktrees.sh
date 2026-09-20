#!/usr/bin/env bash
# Creates isolated git worktrees for Claude and Astra so they never touch
# each other's working directory. Idempotent — safe to re-run.
#
# Usage: scripts/setup-worktrees.sh [claude-branch] [astra-branch]
set -euo pipefail

CLAUDE_BRANCH="${1:-feature/claude-work}"
ASTRA_BRANCH="${2:-feature/astra-work}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository. Run this from within the repo (or a clone of it)." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"

CLAUDE_DIR="$PARENT_DIR/${REPO_NAME}-claude"
ASTRA_DIR="$PARENT_DIR/${REPO_NAME}-astra"

cd "$REPO_ROOT"

# Drop stale worktree registrations (e.g. a user ran `rm -rf` on a worktree
# dir instead of scripts/cleanup-worktrees.sh) so we don't mistake a dangling
# registration for a real, usable worktree below.
git worktree prune

create_worktree() {
  local dir="$1"
  local branch="$2"

  if git worktree list --porcelain | grep -Fxq "worktree $dir"; then
    if [ -d "$dir" ]; then
      echo "OK: worktree already exists: $dir (branch: $branch)"
      return
    fi
    echo "Error: git still has a worktree registered at $dir but the directory is missing." >&2
    echo "Run 'git worktree prune' manually, then re-run this script." >&2
    exit 1
  fi

  if [ -d "$dir" ]; then
    echo "Error: $dir already exists but is not a registered git worktree. Remove or rename it and re-run." >&2
    exit 1
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Creating worktree $dir on existing branch $branch"
    git worktree add "$dir" "$branch"
  else
    echo "Creating worktree $dir on new branch $branch (from $(git rev-parse --abbrev-ref HEAD))"
    git worktree add -b "$branch" "$dir"
  fi
}

copy_shared_files() {
  local dir="$1"
  for f in CLAUDE.md AGENTS.md TASKS.md; do
    if [ -f "$REPO_ROOT/$f" ] && [ ! -f "$dir/$f" ]; then
      cp "$REPO_ROOT/$f" "$dir/$f"
      echo "  copied $f into $dir"
    fi
  done
}

create_worktree "$CLAUDE_DIR" "$CLAUDE_BRANCH"
copy_shared_files "$CLAUDE_DIR"

create_worktree "$ASTRA_DIR" "$ASTRA_BRANCH"
copy_shared_files "$ASTRA_DIR"

cat <<EOF

Worktrees ready:
   Claude: $CLAUDE_DIR   (branch: $CLAUDE_BRANCH)
   Astra:  $ASTRA_DIR    (branch: $ASTRA_BRANCH)

Next steps:
  1. Review/update TASKS.md so each agent's file scope is clear.
  2. Launch each agent in its own worktree:
       scripts/launch-claude.sh
       scripts/launch-astra.sh
  3. When a task is done, open a PR from its branch into main.
     CI (.github/workflows/ci.yml) will lint + test the PR automatically.

To remove the worktrees later, run scripts/cleanup-worktrees.sh.
EOF
