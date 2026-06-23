# ccline — zsh integration.
#
# Source this from ~/.config/zsh/.zshrc:
#     source ~/.config/ccline/ccline.zsh
#
# When you type something that isn't a real command, zsh hands the whole line
# to command_not_found_handler. A single unknown word is treated as a normal
# typo (the usual "command not found"). Two or more words are treated as a
# thought and routed to the `ccline` helper, which asks Claude.
#
# The helper renders the answer and shows the command menu, but it does NOT run
# the chosen command itself. It writes the selection to $CCLINE_RUN_FILE and
# this handler evals it — so the command runs in YOUR live shell, where cd,
# export, aliases, functions, and history all work as expected.

# Let unmatched globs (a trailing "?" etc.) pass through as literal text so a
# question like "how do I do X?" reaches the handler instead of erroring.
setopt no_nomatch 2>/dev/null

# Cache backend resolution at shell startup — avoids forking `command -v`
# on every keystroke when atuin or other ZLE widgets probe command_not_found_handler.
_CCLINE_BACKEND=""
for _ccline_try in claude codex pi; do
  if command -v "$_ccline_try" >/dev/null 2>&1; then
    _CCLINE_BACKEND="$_ccline_try"
    break
  fi
done
unset _ccline_try

# NOTE (atuin + ZLE compatibility): zsh-autosuggestions and atuin's suggestion
# strategy call command_not_found_handler synchronously during line editing to
# validate partial input. $ZLE_STATE is non-empty whenever the handler is invoked
# from within the ZLE line editor (i.e. the user is still typing), vs. empty when
# zsh is actually executing a command. The guard at the top of
# command_not_found_handler bails immediately in the ZLE context, preventing
# per-keystroke lag caused by mktemp and ccline invocation.

command_not_found_handler() {
  # Atuin and other ZLE widgets call this handler during line editing to
  # validate partial input. $ZLE_STATE is set whenever we're inside the line
  # editor — bail immediately to avoid any lag during typing.
  [[ -n $ZLE_STATE ]] && return 127

  # Also bail instantly if the first token is a known command — prevents
  # unnecessary ccline invocation for valid commands with unknown arguments.
  (( $+commands[$1] )) && return 127

  # Two or more words AND the helper is actually installed → ask Claude.
  if (( $# >= 2 )) && (( $+commands[ccline] )); then
    local runfile
    runfile="$(mktemp "${TMPDIR:-/tmp}/ccline.XXXXXX")" || {
      CCLINE_BACKEND="$_CCLINE_BACKEND" command ccline "$@"; return $?
    }

    CCLINE_BACKEND="$_CCLINE_BACKEND" CCLINE_RUN_FILE="$runfile" command ccline "$@"
    local rc=$?

    if [[ -s "$runfile" ]]; then
      local line
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        print -r -- "$ $line"
        eval "$line" || { rc=$?; break }
      done < "$runfile"
    fi

    rm -f "$runfile"
    return $rc
  fi

  print -u2 "zsh: command not found: $1"
  return 127
}
