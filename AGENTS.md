# AGENTS.md

This repo is set up for **multiple coding agents to work side by side** in
isolated git worktrees, so they never overwrite each other's files. If you're
an OpenAI/Codex-based agent (e.g. GPT-6 Astra) reading this: you are likely
running inside `../<repo>-astra` (see
[scripts/setup-worktrees.sh](scripts/setup-worktrees.sh)), on the branch
assigned to you in [TASKS.md](TASKS.md). A second agent (e.g. Claude Code,
see [CLAUDE.md](CLAUDE.md)) may be working in a sibling worktree on a
different branch at the same time. Stay inside your assigned scope so your
work merges cleanly.

<!-- SHARED-RULES-START — keep this block identical in CLAUDE.md and AGENTS.md -->

## Shared rules (apply to every agent)

### 1. Check your scope before editing

Before touching any file, check the **Files/Directories owned** column in
[TASKS.md](TASKS.md) for your assigned row. Only edit files inside your
scope. If you need something outside it (a shared interface, a config file),
say so explicitly and coordinate rather than editing it directly.

### 2. Coding style

- JavaScript/TypeScript: match the existing formatting in the file you're
  editing; no semicolon/quote-style holy wars — run the linter, don't
  hand-format.
- Python: follow PEP 8; prefer type hints on new functions.
- Keep functions small and single-purpose. No speculative abstractions —
  build what the current task needs.
- No commented-out code, no TODO-and-abandon. If something is unfinished,
  say so in the PR description, not in a stray comment.

### 3. Test and lint commands

Run these from the relevant package directory (e.g. `examples/sample-app/`)
before committing:

```bash
npm install
npm run lint
npm test
```

CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs the same two
commands on every PR into `main` — a PR from either agent's branch is
validated identically, so don't skip this locally.

### 4. Never edit files outside your assigned scope

This is the most important rule in this file. Two agents editing the same
file in two different worktrees is exactly the conflict this setup exists to
prevent. If your task requires a change outside your scope:

- Update [TASKS.md](TASKS.md) to reflect the real ownership, or
- Flag it in your PR description and let a human/the owning agent make the
  change, or
- If it's a genuinely shared file (e.g. `package.json` dependencies), make
  the smallest possible change and call it out clearly in the commit message.

### 5. Commits and PRs

- Commit to your assigned branch only (see [TASKS.md](TASKS.md)).
- Write commit messages that explain *why*, not just *what*.
- Open a PR into `main` when your task is done or ready for review; don't
  merge directly to `main` yourself.
- Update your row's `Status` in TASKS.md as you go.

<!-- SHARED-RULES-END -->

## Codex/Astra-specific notes

- Use `scripts/launch-astra.sh` to enter your worktree and start a session.
- If you're unsure whether a file is in scope, ask before editing rather than
  guessing.
