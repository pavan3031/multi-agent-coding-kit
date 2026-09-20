#!/usr/bin/env bash
# Integration test for scripts/setup-worktrees.sh, launch-*.sh, and
# cleanup-worktrees.sh. Runs against a disposable clone of this repo so it
# never touches the caller's real worktrees or branches.
#
# Usage: tests/integration.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
CLONE="$WORK/multi-agent-coding-kit"

pass=0
fail=0

check() {
  local desc="$1"
  shift
  if "$@"; then
    echo "  PASS: $desc"
    pass=$((pass + 1))
  else
    echo "  FAIL: $desc" >&2
    fail=$((fail + 1))
  fi
}

cleanup() {
  rm -rf "$WORK" "${CLONE}-claude" "${CLONE}-codex" 2>/dev/null || true
}
trap cleanup EXIT

echo "== setting up disposable clone in $WORK =="
git clone -q "$REPO_ROOT" "$CLONE"
cd "$CLONE"
git config user.email "test@example.com"
git config user.name "Integration Test"

echo "== running setup-worktrees.sh =="
./scripts/setup-worktrees.sh test/claude-ci test/codex-ci

CLAUDE_DIR="${CLONE}-claude"
CODEX_DIR="${CLONE}-codex"

check "claude worktree directory exists" test -d "$CLAUDE_DIR"
check "codex worktree directory exists" test -d "$CODEX_DIR"

CLAUDE_BRANCH="$(git -C "$CLAUDE_DIR" symbolic-ref --short HEAD)"
CODEX_BRANCH="$(git -C "$CODEX_DIR" symbolic-ref --short HEAD)"
check "claude worktree is on test/claude-ci" [ "$CLAUDE_BRANCH" = "test/claude-ci" ]
check "codex worktree is on test/codex-ci" [ "$CODEX_BRANCH" = "test/codex-ci" ]

CLAUDE_SHA="$(git -C "$CLAUDE_DIR" rev-parse HEAD)"
CODEX_SHA="$(git -C "$CODEX_DIR" rev-parse HEAD)"
check "both worktrees start from the identical base commit" [ "$CLAUDE_SHA" = "$CODEX_SHA" ]

echo "== re-running setup-worktrees.sh (idempotency) =="
check "re-run is idempotent" ./scripts/setup-worktrees.sh test/claude-ci test/codex-ci

echo "== running setup-worktrees.sh from inside a worktree (regression test) =="
( cd "$CLAUDE_DIR" && ./scripts/setup-worktrees.sh test/claude-ci test/codex-ci )
check "no doubled -claude-claude directory was created" test ! -d "${CLAUDE_DIR}-claude"
check "no doubled -codex-codex directory was created" test ! -d "${CODEX_DIR}-codex"

echo "== testing launch scripts resolve the correct worktree from any cwd =="
FAKE_BIN="$WORK/fakebin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/claude" <<'EOF'
#!/usr/bin/env bash
pwd
EOF
cat > "$FAKE_BIN/codex" <<'EOF'
#!/usr/bin/env bash
pwd
EOF
chmod +x "$FAKE_BIN/claude" "$FAKE_BIN/codex"

RESULT="$(cd "$CODEX_DIR" && PATH="$FAKE_BIN:$PATH" "$CLONE/scripts/launch-claude.sh" | tail -1)"
check "launch-claude.sh run from the codex worktree still lands in the claude worktree" \
  [ "$RESULT" = "$CLAUDE_DIR" ]

echo "== testing cleanup refuses to remove a dirty worktree without --force =="
echo "dirty" >> "$CLAUDE_DIR/README.md"
if ./scripts/cleanup-worktrees.sh > /tmp/cleanup_out.$$ 2>&1; then
  echo "  FAIL: cleanup should have exited non-zero on a dirty worktree" >&2
  fail=$((fail + 1))
else
  check "cleanup output mentions the dirty file" grep -q "README.md" /tmp/cleanup_out.$$
fi
check "dirty claude worktree was NOT removed" test -d "$CLAUDE_DIR"
rm -f /tmp/cleanup_out.$$

echo "== running cleanup-worktrees.sh --force =="
./scripts/cleanup-worktrees.sh --force
check "claude worktree removed" test ! -d "$CLAUDE_DIR"
check "codex worktree removed" test ! -d "$CODEX_DIR"

echo ""
echo "== results: $pass passed, $fail failed =="
if [ "$fail" -ne 0 ]; then
  exit 1
fi
