# VHS tape script for the multi-agent-coding-kit demo GIF.
# Scripts a session with real `claude` and `codex` CLIs, each doing their
# assigned task from TASKS.md in their own isolated worktree. The final
# merge step simulates the human maintainer landing both PRs locally --
# agents themselves open PRs and never merge to main directly.
#
# Install VHS: https://github.com/charmbracelet/vhs
# Render with:  vhs docs/demo.tape
# (outputs docs/demo.gif)

Output docs/demo.gif

Set Shell "bash"
Set FontSize 15
Set Width 1200
Set Height 760
Set Theme "Dracula"
Set Padding 20
Set TypingSpeed 35ms

Type "cd multi-agent-coding-kit"
Enter
Sleep 500ms
Type "clear"
Enter

Type `# Give each agent its own isolated git worktree, from the same base commit`
Enter
Type "./scripts/setup-worktrees.sh"
Enter
Sleep 3s

Type "clear"
Enter
Type `# Claude Code works in its own worktree...`
Enter
Type `cd ../multi-agent-coding-kit-claude`
Enter
Type `claude -p "Create examples/sample-app/src/api/health.js exporting a health() function returning 'ok'. ES module syntax." --allowedTools Write`
Enter
Sleep 15s

Type "clear"
Enter
Type `# ...while Codex works in its own, at the same time, no filesystem conflicts`
Enter
Type `cd ../multi-agent-coding-kit-codex`
Enter
Type `codex exec --sandbox workspace-write "Create examples/sample-app/src/cli/index.js exporting a cli() function returning 'cli'. ES module syntax."`
Enter
Sleep 20s

Type "clear"
Enter
Type `# Human maintainer: land both PRs locally (agents open PRs, don't merge themselves)`
Enter
Type `cd ../multi-agent-coding-kit`
Enter
Type `git -C ../multi-agent-coding-kit-claude add -A && git -C ../multi-agent-coding-kit-claude commit -q -m "claude: add health endpoint"`
Enter
Sleep 1s
Type `git -C ../multi-agent-coding-kit-codex add -A && git -C ../multi-agent-coding-kit-codex commit -q -m "codex: add cli entrypoint"`
Enter
Sleep 1s
Type `git merge -q --no-edit feature/claude-work && git merge -q --no-edit feature/codex-work`
Enter
Sleep 1s
Type `git log --oneline --graph --all`
Enter
Sleep 3s

Screenshot docs/demo-final.png
Sleep 2s
