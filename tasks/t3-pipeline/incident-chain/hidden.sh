cd "$(dirname "$0")"
fail() { echo "FAIL: $1"; exit 1; }

sh srv/run.sh 5 >/dev/null 2>&1 || fail "service still crash-looping"
tail -1 logs/app.log | grep -q 'serving' || fail "service not serving"

ls .verify/artifacts/incident-*/NOTE.md >/dev/null 2>&1 || fail "no incident evidence bundle (.verify/artifacts/incident-*/NOTE.md)"
grep -q 'DATA_FILE' .verify/artifacts/incident-*/NOTE.md || fail "NOTE.md missing the root cause (DATA_FILE)"

git status --porcelain -- test/ | grep -q '^??' || fail "no new regression test file under test/ (fixture tests are off-limits; add a new file)"

grep -rliE 'root cause|action item|timeline' .verify/artifacts/ docs/ 2>/dev/null | grep -v 'incident-.*/NOTE.md' | grep -q . || fail "no postmortem/writeup artifact found"

exit 0
