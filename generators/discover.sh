#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${1:?usage: discover.sh <repo-url-or-path> <test-cmd> <max>}"
TESTCMD="${2:?test-cmd required}"
MAX="${3:-10}"
GREP="${GREP:-fix|bug|regression|correct|broken}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ -d "$REPO" ]; then
  SRC="$REPO"
else
  git clone --quiet "$REPO" "$TMP/repo"
  SRC="$TMP/repo"
fi

found=0
for sha in $(git -C "$SRC" log --format=%H -"$MAX" -E --grep="$GREP" -i); do
  git -C "$SRC" diff --name-only "$sha^" "$sha" 2>/dev/null | grep -qE '(test|spec|__tests__|_test)' || continue
  git -C "$SRC" diff --name-only "$sha^" "$sha" | grep -vqE '(test|spec|__tests__|_test)' || continue
  name="$(basename "$REPO" .git)-$(printf '%s' "$sha" | cut -c1-8)"
  out="$ROOT/eval/generated/revert-$name"
  if sh "$ROOT/generators/revert.sh" "$SRC" "$sha" "$TESTCMD" "$out" >/dev/null 2>&1; then
    found=$((found + 1))
    echo "revert-$name"
  fi
done
[ "$found" -gt 0 ] || { echo "no eligible commits (fix+test) in last $MAX matching '$GREP'" >&2; exit 1; }
