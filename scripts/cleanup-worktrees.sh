#!/usr/bin/env bash
# Removes the Claude and Codex worktrees created by setup-worktrees.sh.
# Does NOT delete the branches, only the worktree directories.
#
# Usage: scripts/cleanup-worktrees.sh [--force]
set -euo pipefail

FORCE_FLAG=""
if [ "${1:-}" = "--force" ]; then
  FORCE_FLAG="--force"
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

COMMON_GIT_DIR="$(git rev-parse --git-common-dir)"
COMMON_GIT_DIR="$(cd "$COMMON_GIT_DIR" && pwd -P)"
REPO_ROOT="$(dirname "$COMMON_GIT_DIR")"
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"

FAILED=0

for dir in "$PARENT_DIR/${REPO_NAME}-claude" "$PARENT_DIR/${REPO_NAME}-codex"; do
  # Check the directory itself rather than string-matching paths against
  # `git worktree list` output -- see setup-worktrees.sh for why.
  if [ ! -d "$dir" ] || ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "No worktree registered at $dir, skipping"
    continue
  fi
  dir_common_git="$(cd "$(git -C "$dir" rev-parse --git-common-dir)" && pwd -P)"
  if [ "$dir_common_git" != "$COMMON_GIT_DIR" ]; then
    echo "No worktree registered at $dir, skipping"
    continue
  fi

  if [ -z "$FORCE_FLAG" ]; then
    DIRTY="$(git -C "$dir" status --porcelain 2>/dev/null || true)"
    if [ -n "$DIRTY" ]; then
      echo "ERROR: $dir has uncommitted changes, refusing to remove it:" >&2
      while IFS= read -r line; do
        echo "  $line" >&2
      done <<< "$DIRTY"
      echo "Commit or stash those changes, or re-run with --force to discard them." >&2
      FAILED=1
      continue
    fi
  fi

  echo "Removing worktree $dir"
  if ! git -C "$REPO_ROOT" worktree remove $FORCE_FLAG "$dir"; then
    echo "  FAILED to remove $dir" >&2
    FAILED=1
  fi
done

echo "Done. Branches were left intact; delete them manually with 'git branch -d <branch>' if no longer needed."

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
