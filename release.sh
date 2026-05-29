#!/usr/bin/env bash
#
# Cut a new ccline release.
#
#   ./release.sh vX.Y.Z ["release notes..."]
#
# Steps, in order:
#   1. validate the version and preconditions (clean tree, tag is new, tests pass)
#   2. bump the pinned version in install.sh and README.md
#   3. commit and push main
#   4. create and push the git tag
#   5. create the GitHub release (with the pinned install one-liner)

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

NEW="${1:-}"
if [ -z "$NEW" ]; then
  echo "usage: ./release.sh vX.Y.Z [\"release notes...\"]" >&2
  exit 2
fi
case "$NEW" in v*) ;; *) NEW="v$NEW" ;; esac
if ! echo "$NEW" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "release: version must look like vX.Y.Z (got '$NEW')" >&2
  exit 2
fi

command -v gh >/dev/null || { echo "release: gh CLI not found" >&2; exit 1; }

# Current pinned version = first vX.Y.Z in install.sh (the REF default).
CUR="$(grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' install.sh | head -1)"
[ -n "$CUR" ] || { echo "release: could not find current version in install.sh" >&2; exit 1; }
[ "$CUR" != "$NEW" ] || { echo "release: $NEW is already the current version" >&2; exit 1; }

echo "Releasing ${CUR} -> ${NEW}"

# Preconditions.
[ -z "$(git status --porcelain)" ] || { echo "release: working tree not clean" >&2; exit 1; }
if git rev-parse "$NEW" >/dev/null 2>&1; then
  echo "release: tag $NEW already exists" >&2; exit 1
fi
echo "Running tests…"
bash tests/test_ccline.sh >/dev/null || { echo "release: tests failed" >&2; exit 1; }

# Bump the pinned version (portable in-place edit via perl).
perl -i -pe "s/\Q${CUR}\E/${NEW}/g" install.sh README.md

# Commit + push main.
git add -A
git commit -q -m "Release ${NEW}"
git push -q origin main

# Tag + push.
git tag -a "$NEW" -m "ccline ${NEW}"
git push -q origin "$NEW"

# GitHub release.
shift || true
NOTES="${*:-Release ${NEW}.}"
gh release create "$NEW" --title "ccline ${NEW}" --notes "${NOTES}

## Install
\`\`\`sh
curl -fsSL https://raw.githubusercontent.com/jianshuo/ccline/${NEW}/install.sh | bash
\`\`\`"

echo "Released ${NEW}: https://github.com/jianshuo/ccline/releases/tag/${NEW}"
