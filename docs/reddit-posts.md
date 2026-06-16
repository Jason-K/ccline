# Reddit Posts — ready to copy-paste

## r/commandline

**Title**: I built ccline — type plain English at your zsh prompt, get an AI shell answer (uses command_not_found_handler)

**Body**:

I kept Googling the same shell commands over and over. `tar` flags, `rsync` options, `awk` one-liners. Every time.

So I built **ccline**. It hooks into zsh's `command_not_found_handler` — that function zsh calls when you type something it doesn't recognize. Instead of an error, it asks Claude.

**Demo**:

```
$ find all .log files older than 7 days
```
→ `find . -name "*.log" -mtime +7`

```
$ kill all processes on port 3000
```
→ `lsof -ti :3000 | xargs kill -9`

```
$ git command to undo last commit but keep changes
```
→ `git reset --soft HEAD~1`

After printing the answer, it offers to run any `bash` commands it found. Arrow keys to choose, Enter to run.

**How it works**:

zsh's `command_not_found_handler` fires whenever you type something unrecognized. ccline uses this hook to call `claude -p` with your input as the prompt — clean, isolated, no agents or MCP servers. The answer is rendered with syntax highlighting, and any bash code blocks become runnable options.

**Install**:

```bash
# Via Homebrew
brew install jianshuo/tap/ccline

# Or manual (just source a file)
git clone https://github.com/jianshuo/ccline
echo 'source ~/ccline/ccline.zsh' >> ~/.config/zsh/.zshrc
```

**GitHub**: https://github.com/jianshuo/ccline

Works with `claude` CLI (Claude Code) or OpenAI Codex as fallback.

---

## r/zsh

**Title**: ccline — hook command_not_found_handler to Claude for instant shell AI help

**Body**:

Built a small zsh plugin that hooks `command_not_found_handler` to the Claude CLI.

When you type something that isn't a command, instead of `zsh: command not found: ...` you get an AI answer with syntax highlighting and an interactive menu to run any suggested commands.

```
$ how do I list only directories sorted by size
→ du -sh */ | sort -rh
```

```
$ rsync command to copy preserving permissions and symlinks
→ rsync -avz --links src/ dest/
```

The core is a ~30-line zsh function. The rest (~270 lines) handles spinner animation, markdown rendering, arrow-key menu, and Claude/Codex backend detection.

**Install**:
```bash
brew install jianshuo/tap/ccline
# Add to ~/.config/zsh/.zshrc:
source $(brew --prefix)/share/ccline/ccline.zsh
```

Source: https://github.com/jianshuo/ccline

---

## r/MacOS

**Title**: ccline — type plain English at your macOS zsh prompt, get an AI shell answer

**Body**:

Quick thing I built for my macOS workflow: **ccline**.

It hooks into zsh's `command_not_found_handler` so when you type something that's not a command, instead of "command not found" you get an AI answer.

**Examples on macOS**:
```
$ defaults command to speed up dock animation
→ defaults write com.apple.dock autohide-time-modifier -float 0.15; killall Dock

$ how do I find what's eating disk space
→ du -sh /* 2>/dev/null | sort -rh | head -20

$ pbpaste into a file
→ pbpaste > output.txt
```

It uses the `claude` CLI (Claude Code), prints the answer with syntax highlighting, and offers to run any commands it suggests.

**Install**:
```bash
brew install jianshuo/tap/ccline
# Add to ~/.config/zsh/.zshrc: source $(brew --prefix)/share/ccline/ccline.zsh
```

GitHub: https://github.com/jianshuo/ccline

Works with macOS zsh (default since Catalina). Uses your existing Claude Code CLI.

---

## Show HN (Hacker News)

**Title**: Show HN: ccline – type a thought at your zsh prompt, get an AI answer, run the command

**URL**: https://github.com/jianshuo/ccline

**Text** (optional body):
ccline hooks into zsh's command_not_found_handler. When you type something that isn't a recognized command, instead of an error, it asks Claude (or Codex) and prints the answer with syntax highlighting. If the answer contains bash commands, an arrow-key menu lets you run them in your current shell.

~300 lines of bash. No external dependencies beyond the AI CLI. Works with the claude CLI (Claude Code) or OpenAI Codex as fallback.
