#!/usr/bin/env bash
set -eu

REPO="${1:?usage: revert.sh <repo-url-or-path> <fix-sha> <test-cmd> <outdir>}"
SHA="${2:?fix-sha required}"
TESTCMD="${3:?test-cmd required}"
OUT="${4:?outdir required}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ -d "$REPO" ]; then
  SRC="$REPO"
else
  git clone --quiet "$REPO" "$TMP/repo"
  SRC="$TMP/repo"
fi

git -C "$SRC" cat-file -e "$SHA^{commit}" 2>/dev/null || { echo "no such commit: $SHA" >&2; exit 2; }
SUBJ="$(git -C "$SRC" log -1 --format=%s "$SHA")"
BODY="$(git -C "$SRC" log -1 --format=%b "$SHA" | head -20)"

TEST_FILES="$(git -C "$SRC" diff --name-only "$SHA^" "$SHA" | grep -E '(test|spec|__tests__|_test)' || true)"
[ -n "$TEST_FILES" ] || { echo "commit $SHA touches no test files; cannot grade FAIL_TO_PASS" >&2; exit 2; }

mkdir -p "$OUT/fixture"
git -C "$SRC" archive "$SHA^" | tar -x -C "$OUT/fixture"
git -C "$SRC" diff "$SHA^" "$SHA" -- $TEST_FILES > "$OUT/test.patch"
git -C "$SRC" diff "$SHA^" "$SHA" > "$OUT/oracle.patch"
[ -s "$OUT/test.patch" ] || { echo "empty test patch" >&2; exit 2; }

NAME="$(basename "$REPO" .git)-$(printf '%s' "$SHA" | cut -c1-8)"

cat > "$OUT/prompt.md" <<EOF
The repository in this directory has a bug. Upstream fixed it as "$SUBJ". $BODY
Fix it. The project's test suite must pass ($TESTCMD).
EOF

{
cat <<EOF
cd "\$(dirname "\$0")"
cat > .test.patch <<'PATCHEOF'
EOF
cat "$OUT/test.patch"
cat <<EOF
PATCHEOF
git apply --check .test.patch >/dev/null 2>&1 && git apply .test.patch || { echo "FAIL: test patch does not apply"; exit 1; }
sh -c '$TESTCMD' >/dev/null 2>&1 || { echo "FAIL: $TESTCMD"; exit 1; }
exit 0
EOF
} > "$OUT/hidden.sh"

printf 'plan before\nbug-fix before\ntoken-efficiency before\nno-comments before\n' > "$OUT/playbook"

cat > "$OUT/meta.toml" <<EOF
tier = 4
difficulty = "medium"
family = "revert"
generated = true
repo = "$REPO"
fix_sha = "$SHA"
test_cmd = "$TESTCMD"
playbooks = ["bug-fix"]
EOF
echo "$NAME"
