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

for g in generators/families/*.sh; do
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
[ -s "tasks/$task/fixture/data/records.txt" ] || err "$task fixture missing data/records.txt (intended restore target)"

task=t1-conformance/checklist-hydration
if sh tasks/$task/fixture/test/util_test.sh >/dev/null 2>&1; then
  err "$task fixture test passes as shipped (bug missing)"
fi

if command -v bun >/dev/null; then
  (cd tasks/t2-lifecycle/ts-query-guard/fixture && bun test src/ >/dev/null 2>&1) || true
  (cd tasks/t2-lifecycle/ts-query-guard/fixture && cat > .edge.test.ts <<'EOF'
import { test, expect } from "bun:test";
import { parsePagination, ParseError } from "./src/query";
test("non-numeric throws", () => { expect(() => parsePagination({ page: "x" })).toThrow(ParseError); });
EOF
  bun test .edge.test.ts >/dev/null 2>&1 && err "ts-query-guard fixture passes edge cases as shipped"; rm -f .edge.test.ts)
fi

(cd tasks/t2-lifecycle/py-retry/fixture && python3 -c 'from retrylib.retry import retry
r = retry(lambda: (_ for _ in ()).throw(RuntimeError("x")), attempts=2)
raise SystemExit(0 if r is None else 1)') || err "py-retry fixture bug missing (retry already raises)"

if [ "$FAIL" -eq 0 ]; then
  echo "==> [agstack-bench] Verification passed cleanly (exit 0)."
else
  echo "==> [agstack-bench] FAILED" >&2
  exit 1
fi
