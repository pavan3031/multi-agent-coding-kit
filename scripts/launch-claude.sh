#!/usr/bin/env bash
# Thin wrapper: cd into the Claude worktree and start a Claude Code session.
# Safe to run from the main repo or from either worktree.
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

# Resolve the canonical main repo directory even when invoked from inside
# one of the worktrees (git rev-parse --show-toplevel would otherwise
# return the worktree's own path, producing a doubled -claude-claude dir).
COMMON_GIT_DIR="$(git rev-parse --git-common-dir)"
COMMON_GIT_DIR="$(cd "$COMMON_GIT_DIR" && pwd -P)"
REPO_ROOT="$(dirname "$COMMON_GIT_DIR")"
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"
CLAUDE_DIR="$PARENT_DIR/${REPO_NAME}-claude"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo "Error: $CLAUDE_DIR does not exist yet." >&2
  echo "Run scripts/setup-worktrees.sh first." >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "Error: the 'claude' CLI was not found on your PATH." >&2
  echo "Install Claude Code: https://docs.claude.com/en/docs/claude-code/overview" >&2
  exit 1
fi

echo "Entering $CLAUDE_DIR and launching Claude Code..."
cd "$CLAUDE_DIR"
exec claude "$@"
