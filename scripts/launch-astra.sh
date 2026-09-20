#!/usr/bin/env bash
# Thin wrapper: cd into the Astra worktree and start a Codex/GPT session.
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"
ASTRA_DIR="$PARENT_DIR/${REPO_NAME}-astra"

if [ ! -d "$ASTRA_DIR" ]; then
  echo "Error: $ASTRA_DIR does not exist yet." >&2
  echo "Run scripts/setup-worktrees.sh first." >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: the 'codex' CLI was not found on your PATH." >&2
  echo "Install the OpenAI Codex CLI: https://github.com/openai/codex" >&2
  exit 1
fi

echo "Entering $ASTRA_DIR and launching Codex..."
cd "$ASTRA_DIR"
exec codex "$@"
