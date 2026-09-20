#!/usr/bin/env bash
# Thin wrapper: cd into the Codex worktree and start a Codex/GPT session.
# Safe to run from the main repo or from either worktree.
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

# Resolve the canonical main repo directory even when invoked from inside
# one of the worktrees (git rev-parse --show-toplevel would otherwise
# return the worktree's own path, producing a doubled -codex-codex dir).
COMMON_GIT_DIR="$(git rev-parse --git-common-dir)"
COMMON_GIT_DIR="$(cd "$COMMON_GIT_DIR" && pwd)"
REPO_ROOT="$(dirname "$COMMON_GIT_DIR")"
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"
CODEX_DIR="$PARENT_DIR/${REPO_NAME}-codex"

if [ ! -d "$CODEX_DIR" ]; then
  echo "Error: $CODEX_DIR does not exist yet." >&2
  echo "Run scripts/setup-worktrees.sh first." >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: the 'codex' CLI was not found on your PATH." >&2
  echo "Install the OpenAI Codex CLI: https://github.com/openai/codex" >&2
  exit 1
fi

echo "Entering $CODEX_DIR and launching Codex..."
cd "$CODEX_DIR"
exec codex "$@"
