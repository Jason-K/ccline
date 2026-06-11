#!/usr/bin/env bash
#
# Install ccline for fish. Works two ways:
#   • from a local clone:   ./install-fish.sh
#   • remotely:             curl -fsSL <raw-url>/install-fish.sh | bash
#
# Idempotent — safe to re-run.

set -euo pipefail

# Pinned to a release tag so the install command is stable across future
# changes. Override with CCLINE_REF=main (or another tag) to install elsewhere.
REPO="jianshuo/ccline"
REF="${CCLINE_REF:-v0.2.2}"
RAW="https://raw.githubusercontent.com/${REPO}/${REF}"

BIN_DIR="${HOME}/.local/bin"
FISH_CONF_DIR="${HOME}/.config/fish/conf.d"
FISH_CONF_FILE="${FISH_CONF_DIR}/ccline.fish"

# Find source files: prefer a local clone; otherwise download from GitHub.
SRC_DIR=""
if [ -n "${BASH_SOURCE:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  maybe="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "${maybe}/ccline" ] && [ -f "${maybe}/ccline.fish" ]; then
    SRC_DIR="$maybe"
  fi
fi

cleanup=""
if [ -z "$SRC_DIR" ]; then
  echo "Downloading ccline from ${REPO}…"
  SRC_DIR="$(mktemp -d)"
  cleanup="$SRC_DIR"
  for f in ccline ccline.fish; do
    if ! curl -fsSL "${RAW}/${f}" -o "${SRC_DIR}/${f}"; then
      echo "ccline: failed to download ${f} from ${RAW}/${f}" >&2
      rm -rf "$cleanup"
      exit 1
    fi
  done
fi

mkdir -p "$BIN_DIR" "$FISH_CONF_DIR"
install -m 0755 "${SRC_DIR}/ccline" "${BIN_DIR}/ccline"
install -m 0644 "${SRC_DIR}/ccline.fish" "$FISH_CONF_FILE"
[ -n "$cleanup" ] && rm -rf "$cleanup"

echo "Installed:"
echo "  ${BIN_DIR}/ccline"
echo "  ${FISH_CONF_FILE}"

case ":${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) echo "NOTE: ${BIN_DIR} is not on your PATH. Add it to fish's PATH." ;;
esac

if ! command -v claude >/dev/null 2>&1 && ! command -v codex >/dev/null 2>&1; then
  echo "NOTE: neither 'claude' nor 'codex' was found. ccline needs one:"
  echo "      Claude Code: https://claude.com/claude-code"
  echo "      Codex:       https://github.com/openai/codex"
fi

echo
echo "Done. Open a new fish terminal (or run: source ~/.config/fish/conf.d/ccline.fish) and just type a thought:"
echo "    how do I find files bigger than 100MB here"
