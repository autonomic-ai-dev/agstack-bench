#!/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FAIL=0

err() { echo "ERROR: $1" >&2; FAIL=1; }

for t in tasks/*/*/; do
  [ -f "$t/prompt.md" ] || err "$t missing prompt.md"
  [ -f "$t/hidden.sh" ] || err "$t missing hidden.sh"
  [ -f "$t/playbook" ] || err "$t missing playbook spec"
  [ -f "$t/meta.toml" ] || err "$t missing meta.toml"
  [ -d "$t/fixture" ] || err "$t missing fixture/"
  grep -vE '^[a-z-]+ (before|after)$' "$t/playbook" | grep -q . && err "$t/playbook has malformed spec lines"
done

for g in generators/*.sh; do
  fam="$(basename "$g" .sh)"
  tmp="$(mktemp -d)"
  sh "$g" 1 "$tmp/task" || err "generator $fam failed on seed 1"
  for f in prompt.md hidden.sh playbook meta.toml; do
    [ -f "$tmp/task/$f" ] || err "generator $fam seed 1 missing $f"
  done
  [ -d "$tmp/task/fixture" ] || err "generator $fam seed 1 missing fixture/"
  rm -rf "$tmp"
done

task=t3-pipeline/incident-chain
if sh tasks/$task/fixture/srv/run.sh 5 >/dev/null 2>&1; then
  err "$task fixture is not crash-looping (broken fixture)"
fi

task=t1-conformance/checklist-hydration
if sh tasks/$task/fixture/test/util_test.sh >/dev/null 2>&1; then
  err "$task fixture test passes as shipped (bug missing)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "==> [agstack-bench] Verification passed cleanly (exit 0)."
else
  echo "==> [agstack-bench] FAILED" >&2
  exit 1
fi
