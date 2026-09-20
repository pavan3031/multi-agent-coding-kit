# multi-agent-coding-kit

**Run Claude Code and an OpenAI Codex/GPT-based agent side-by-side on the same project — in isolated git worktrees — without them stepping on each other's files.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/pavan3031/multi-agent-coding-kit?style=social)](https://github.com/pavan3031/multi-agent-coding-kit/stargazers)
[![CI](https://github.com/pavan3031/multi-agent-coding-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/pavan3031/multi-agent-coding-kit/actions/workflows/ci.yml)

## Why

Running two coding agents on the same checkout is a recipe for lost work: one agent's edit clobbers the other's mid-write, or you spend more time reconciling diffs than either agent spent writing code. `multi-agent-coding-kit` gives each agent its own **git worktree** — a separate working directory backed by the same repo — so they can edit files in parallel with zero risk of overwriting each other, and merge their work back through ordinary pull requests.

## Quickstart

```bash
# 1. Clone the template
git clone https://github.com/pavan3031/multi-agent-coding-kit.git
cd multi-agent-coding-kit

# 2. Create isolated worktrees for each agent (idempotent, safe to re-run)
scripts/setup-worktrees.sh
# or with custom branch names:
# scripts/setup-worktrees.sh feature/claude-work feature/astra-work

# 3. Edit TASKS.md to define who owns what (files/directories, not just tasks)

# 4. Launch each agent in its own worktree
scripts/launch-claude.sh   # cd's into ../multi-agent-coding-kit-claude and runs `claude`
scripts/launch-astra.sh    # cd's into ../multi-agent-coding-kit-astra and runs `codex`

# 5. When a task is done, open a PR from that branch into main.
#    CI lints + tests every PR the same way, regardless of which agent wrote it.
gh pr create --base main --head feature/claude-work
```

When you're done, tear the worktrees down (branches are kept):

```bash
scripts/cleanup-worktrees.sh
```

## Example session

`claude` and `codex`, each in their own worktree, each doing their `TASKS.md`-assigned scope, merged with zero conflicts:

```console
$ ./scripts/setup-worktrees.sh
Creating worktree ../multi-agent-coding-kit-claude on new branch feature/claude-work (from main)
Creating worktree ../multi-agent-coding-kit-astra on new branch feature/astra-work (from main)

Worktrees ready:
   Claude: ../multi-agent-coding-kit-claude   (branch: feature/claude-work)
   Astra:  ../multi-agent-coding-kit-astra    (branch: feature/astra-work)

$ cd ../multi-agent-coding-kit-claude
$ claude -p "Create examples/sample-app/src/api/health.js exporting a health() \
    function returning 'ok'. ES module syntax." --allowedTools Write
Created `examples/sample-app/src/api/health.js` exporting a `health` function
that returns `'ok'`.

$ cd ../multi-agent-coding-kit-astra
$ codex exec --sandbox workspace-write "Create examples/sample-app/src/cli/index.js \
    exporting a cli() function returning 'cli'. ES module syntax."
Created only `examples/sample-app/src/cli/index.js`:

  export function cli() {
    return 'cli';
  }

$ cd ../multi-agent-coding-kit
$ git merge --no-edit feature/claude-work && git merge --no-edit feature/astra-work
$ git log --oneline --graph --all
*   a847f3f Merge branch 'feature/astra-work'
|\
| * a6ef2d7 Add CLI entrypoint to sample-app
* |   67f6969 Merge branch 'feature/claude-work'
|\ \
| * | ed09f52 Add health check endpoint to sample-app
| |/
* / 3ca0df2 Fix eslint flat config to actually enable eslint:recommended rules
|/
* 0fcedcf Initial commit: multi-agent-coding-kit starter template
```

Zero merge conflicts, both agents' files present, `npm run lint && npm test` still green afterward. `docs/demo.tape` is a [VHS](https://github.com/charmbracelet/vhs) script that replays this exact session — see [Rendering the demo GIF](#rendering-the-demo-gif) to turn it into a video.

## Architecture

Each agent gets its own working directory, checked out from the same `.git`, on its own branch. Nothing is shared except the object database — so file edits in one worktree can never race with edits in another.

```mermaid
flowchart LR
    subgraph Repo["multi-agent-coding-kit/ (main worktree)"]
        G[(.git object database)]
    end

    subgraph ClaudeWT["../multi-agent-coding-kit-claude"]
        CB["branch: feature/claude-work"]
        CF["Claude Code session"]
        CF -->|edits| CB
    end

    subgraph AstraWT["../multi-agent-coding-kit-astra"]
        AB["branch: feature/astra-work"]
        AF["Codex/Astra session"]
        AF -->|edits| AB
    end

    CB -.shared object store.-> G
    AB -.shared object store.-> G

    CB -->|PR| M["main"]
    AB -->|PR| M
    M --> CI["CI: lint + test\n(.github/workflows/ci.yml)"]
```

- **TASKS.md** is the contract: it maps tasks to owner, branch, status, and owned files/directories, so each agent (and any human reviewer) knows the boundaries.
- **CLAUDE.md** and **AGENTS.md** carry the same shared rules (coding style, test commands, "stay in your scope") so both agents behave consistently — Claude Code reads `CLAUDE.md`, Codex/GPT-based agents read `AGENTS.md`.
- **scripts/** automate creating, launching, and tearing down the worktrees.
- **examples/sample-app/** is a tiny Node app that exists purely so the scripts and CI have something real to operate on.

## Requirements

- [git](https://git-scm.com/) 2.5+ (worktree support)
- [GitHub CLI (`gh`)](https://cli.github.com/) for creating/merging PRs from the terminal
- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) (`claude` CLI)
- [OpenAI Codex CLI](https://github.com/openai/codex) or an equivalent GPT-based coding agent (`codex` CLI) — swap in whatever agent you use, as long as it reads `AGENTS.md`
- Node.js 20+ (only needed to run/lint/test `examples/sample-app`)

## Rendering the demo GIF

The repo ships a [VHS](https://github.com/charmbracelet/vhs) script at [docs/demo.tape](docs/demo.tape) that scripts the whole quickstart flow. To render it:

```bash
# macOS
brew install vhs

# Windows
winget install charmbracelet.vhs Gyan.FFmpeg tsl0922.ttyd

# Linux — see https://github.com/charmbracelet/vhs#installation

vhs docs/demo.tape   # writes docs/demo.gif
```

Then add `![Demo](docs/demo.gif)` near the top of this README.

Prefer a terminal recording over a scripted one? Use [asciinema](https://asciinema.org/) and [agg](https://github.com/asciinema/agg):

```bash
asciinema rec demo.cast
agg demo.cast docs/demo.gif
```

## FAQ

**Can I use 3+ agents?**
Yes. `scripts/setup-worktrees.sh` takes two branch names as a convenience default, but the underlying pattern (`git worktree add ../repo-<agent> <branch>`) works for any number of agents. Copy the script's `create_worktree`/`copy_shared_files` calls for a third, fourth, etc., and add corresponding rows to `TASKS.md`.

**What if both agents touch the same file?**
Don't let them — that's what `TASKS.md`'s ownership column and the "never edit files outside your assigned scope" rule in `CLAUDE.md`/`AGENTS.md` are for. If a change genuinely needs to touch a shared file (e.g. `package.json`), keep the diff minimal and call it out explicitly in the PR description so a human can review the overlap.

**How does CI catch conflicts?**
Worktrees prevent *working-directory* conflicts (two processes writing the same file on disk at once). They don't prevent *merge* conflicts, which are a normal git problem solved the normal way: `.github/workflows/ci.yml` runs lint + test on every PR into `main`, so a bad merge or a semantic conflict between the two agents' branches is caught before it lands, regardless of which agent (or human) opened the PR.

**Do the agents need to know about each other?**
Not directly — each only needs to read its own file (`CLAUDE.md` or `AGENTS.md`) and `TASKS.md`. The shared-rules block in both files is kept identical so behavior is consistent even though the agents never communicate directly.

## Contributing

Issues and PRs welcome. If you're proposing a change to the shared rules, edit the block between `<!-- SHARED-RULES-START -->` and `<!-- SHARED-RULES-END -->` in **both** `CLAUDE.md` and `AGENTS.md` so they stay in sync.

## License

[MIT](LICENSE)
