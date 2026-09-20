#!/usr/bin/env bash
# Thin wrapper: cd into the Claude worktree and start a Claude Code session.
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
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
