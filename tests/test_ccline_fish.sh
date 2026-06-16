#!/usr/bin/env bash
# Tests for ccline fish integration. Run: bash tests/test_ccline_fish.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

# shellcheck source=/dev/null
source "${ROOT}/ccline"

pass=0 fail=0
check() { # desc, expected, actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL: %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"
  fi
}

got="$(CCLINE_SHELL=fish ccline_shell_name)"
check "shell name override: fish" "fish" "$got"

prompt="$(CCLINE_SHELL=fish ccline_system_prompt)"
case "$prompt" in
  *'macOS fish prompt'*'```fish code block'*) check "fish prompt mentions fish fence" "yes" "yes" ;;
  *) check "fish prompt mentions fish fence" "yes" "no" ;;
esac

ans="\`\`\`fish
set -gx EDITOR nvim
\`\`\`"
got="$(printf '%s\n' "$ans" | CCLINE_SHELL=fish ccline_extract_commands | ccline_runnable_lines)"
check "fish blocks extracted for fish shell" "set -gx EDITOR nvim" "$got"

got="$(printf '%s\n' "$ans" | CCLINE_SHELL=zsh ccline_extract_commands | ccline_runnable_lines)"
check "fish blocks ignored for zsh shell" "" "$got"

INSTALL_HOME="$(mktemp -d)"
HOME="$INSTALL_HOME" SHELL=/usr/bin/fish "${ROOT}/install-fish.sh" >/dev/null
check "install script writes fish conf.d" "yes" "$([ -f "${INSTALL_HOME}/.config/fish/conf.d/ccline.fish" ] && echo yes || echo no)"
check "install script leaves config.fish alone" "no" "$([ -f "${INSTALL_HOME}/.config/fish/config.fish" ] && echo yes || echo no)"
check "install script skips zsh integration for fish" "no" "$([ -e "${INSTALL_HOME}/.config/zsh/.zshrc" ] && echo yes || echo no)"
rm -rf "$INSTALL_HOME"

if command -v fish >/dev/null 2>&1; then
  fish -n "${ROOT}/ccline.fish"
  check "fish integration syntax" "0" "$?"

  RUNTIME_CONFIG_HOME="$(mktemp -d)"
  FISH_STUB="$(mktemp -d)"
  cat > "${FISH_STUB}/ccline" <<'FISHSTUB'
#!/usr/bin/env bash
[ -n "${CCLINE_FISH_LOG:-}" ] && printf '%s\n' "$*" >> "$CCLINE_FISH_LOG"
if [ "${CCLINE_SHELL:-}" != fish ]; then
  echo "bad shell: ${CCLINE_SHELL:-}" >&2
  exit 42
fi
if [ -z "${CCLINE_RUN_FILE:-}" ]; then
  echo "missing run file" >&2
  exit 43
fi
printf 'set -g CCLINE_FISH_TEST_VAR from_handler\n' > "$CCLINE_RUN_FILE"
FISHSTUB
  chmod +x "${FISH_STUB}/ccline"
  fish_log="${FISH_STUB}/calls"

  out="$(XDG_CONFIG_HOME="$RUNTIME_CONFIG_HOME" PATH="${FISH_STUB}:${PATH}" CCLINE_FISH_LOG="$fish_log" fish -c "source '${ROOT}/ccline.fish'; please set fish var >/dev/null 2>&1; echo \$CCLINE_FISH_TEST_VAR" 2>/dev/null)"
  check "fish handler evals run file in live shell" "from_handler" "$(printf '%s\n' "$out" | tail -n 1)"
  check "fish handler passes shell context" "please set fish var" "$(cat "$fish_log")"

  : > "$fish_log"
  XDG_CONFIG_HOME="$RUNTIME_CONFIG_HOME" PATH="${FISH_STUB}:${PATH}" CCLINE_FISH_LOG="$fish_log" fish -c "source '${ROOT}/ccline.fish'; gti >/dev/null 2>&1; true" 2>/dev/null
  check "fish handler leaves single word to default" "" "$(cat "$fish_log")"

  out="$(XDG_CONFIG_HOME="$RUNTIME_CONFIG_HOME" fish -c "function fish_command_not_found; echo previous:\$argv[1]; end; source '${ROOT}/ccline.fish'; __ccline_command_not_found gti" 2>/dev/null)"
  check "fish handler preserves previous fallback" "previous:gti" "$(printf '%s\n' "$out" | head -n 1)"

  CONF_HOME="$(mktemp -d)"
  mkdir -p "${CONF_HOME}/fish/conf.d" "${CONF_HOME}/bin"
  install -m 0644 "${ROOT}/ccline.fish" "${CONF_HOME}/fish/conf.d/ccline.fish"
  cat > "${CONF_HOME}/bin/ccline" <<'FISHSTUB'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$CCLINE_FISH_LOG"
printf 'set -g CCLINE_FISH_CONF_TEST ok\n' > "$CCLINE_RUN_FILE"
FISHSTUB
  chmod +x "${CONF_HOME}/bin/ccline"
  fish_log="${CONF_HOME}/calls"
  out="$(XDG_CONFIG_HOME="$CONF_HOME" PATH="${CONF_HOME}/bin:${PATH}" CCLINE_FISH_LOG="$fish_log" fish -c "please load confd >/dev/null 2>&1; echo \$CCLINE_FISH_CONF_TEST" 2>/dev/null)"
  check "fish conf.d auto-loads integration" "ok" "$(printf '%s\n' "$out" | tail -n 1)"
  check "fish conf.d handler receives argv" "please load confd" "$(cat "$fish_log")"

  rm -rf "$RUNTIME_CONFIG_HOME" "$FISH_STUB" "$CONF_HOME"
else
  echo "skip: fish not found; runtime fish tests skipped"
fi

echo
echo "passed: ${pass}, failed: ${fail}"
[ "$fail" -eq 0 ]
