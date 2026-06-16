---
title: I wired Claude into zsh's command_not_found_handler
published: true
description: How I built ccline to turn forgotten shell commands into AI answers using zsh's command_not_found_handler hook
tags: zsh, ai, shell, claude
---

I forgot the `tar` flags again. `tar -xzf`? `tar -xvzf`? `tar -cvf`? I always mix them up.

I'd been googling the same twenty shell commands for years. So I built something to stop that.

## The hook you probably don't know about

zsh has a function called `command_not_found_handler`. If you define it in your `.zshrc`, zsh calls it every time you type something that isn't a recognized command.

Most people have never heard of it. Here's the default behavior — zsh prints an error:

```
$ untar this file
zsh: command not found: untar
```

But if you define the handler:

```bash
command_not_found_handler() {
  echo "You typed: $*"
  return 127
}
```

Now zsh calls *your* function instead. The return code of 127 tells zsh the command wasn't found.

## Making it call Claude

The idea clicked: what if the handler called an AI?

```bash
command_not_found_handler() {
  local prompt="$*"
  claude -p \
    --system-prompt "You are a command-line assistant. Be concise. Put runnable commands in \`\`\`bash blocks." \
    --tools "" \
    --setting-sources "" \
    --output-format text \
    "$prompt"
  return 127
}
```

Now this works:

```
$ find all log files older than 7 days
find . -name "*.log" -mtime +7
```

```
$ kill the process on port 3000
lsof -ti :3000 | xargs kill -9
```

## What I built on top of that

The basic idea was promising, but needed polish. I ended up building **ccline** — a ~300-line bash script that wraps this idea with:

**Syntax-highlighted output** — uses `glow` if installed, falls back to a minimal Perl renderer that handles bold, code blocks, and colors.

**A spinner** — shows a braille animation while waiting for the AI (drawn to `/dev/tty` so it doesn't interfere with stdout capture).

**An interactive menu** — if the answer contains bash commands, you get an arrow-key menu to run any of them. The selected command runs in your actual shell — so `cd`, `export`, and history all work.

**Backend detection** — uses the `claude` CLI by default, falls back to OpenAI's `codex` CLI if Claude isn't installed.

Here's what it looks like in practice:

```
$ undo last git commit but keep changes

**Solution**:
Use `git reset --soft` to move HEAD back one commit while keeping your changes staged:

    git reset --soft HEAD~1

Commands found — ↑/↓ to choose, Enter to run, q to cancel:
❯ git reset --soft HEAD~1
  ✗ Cancel
```

## The system prompt matters

The system prompt is what makes it useful vs. annoying:

```
You are a command-line assistant answering a quick question typed directly at a
macOS zsh prompt. Be concise — a few sentences at most. If your answer involves
shell commands the user can run, put each runnable command in its own fenced
```bash code block. Never put example output, file contents, or non-runnable
snippets in a bash/sh/shell block. Prefer safe, non-destructive commands; if a
command is destructive, say so plainly.
```

The key constraint: **only runnable commands go in bash blocks**. This lets the tool reliably extract the commands to run. If you put example output or config files in bash blocks, the tool would try to run them.

## The `--tools ""` flag

One thing worth explaining: I pass `--tools ""` and `--setting-sources ""` to the claude CLI. This is intentional.

I don't want the AI to browse the web, read my files, or use any agents when answering a quick shell question. I want a clean, isolated call that produces exactly what I need.

This also makes it significantly faster — no tool setup overhead.

## Installation

```bash
# Via Homebrew
brew install jianshuo/tap/ccline

# Or manual
git clone https://github.com/jianshuo/ccline
echo 'source ~/ccline/ccline.zsh' >> ~/.config/zsh/.zshrc
source ~/.config/zsh/.zshrc
```

The Homebrew formula installs the main `ccline` script and `ccline.zsh` (the hook). Sourcing `ccline.zsh` registers the `command_not_found_handler`.

## What I use it for most

- `tar` and `zip` flags (I will never memorize these)
- `awk` and `sed` one-liners
- `git` history manipulation (`cherry-pick`, `rebase`, `stash`, etc.)
- macOS-specific `defaults write` commands
- Docker commands when I can't remember the exact syntax
- "How do I list all files sorted by size in this directory?"

## One edge case to know about

If you have a typo in a real command, ccline will kick in. `gti status` becomes an AI query instead of "command not found". This is mostly fine (the AI usually says "did you mean `git status`?"), but it's worth knowing about.

You can always `Ctrl-C` to cancel the AI call.

---

The full source is at **https://github.com/jianshuo/ccline** — ~300 lines of bash with no external dependencies beyond the AI CLI.

If you use zsh and have the Claude Code CLI installed, it's one `brew install` away.
