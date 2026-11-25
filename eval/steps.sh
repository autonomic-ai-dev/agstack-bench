#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVAL="$ROOT/.verify/artifacts/eval"
[ -d "$EVAL" ] || { echo "no eval artifacts"; exit 0; }

cd "$EVAL"
find . -name claude.jsonl | while read -r f; do
  run=$(dirname "$f")
  case "$(basename "$run")" in agstack-*) ;; *) continue;; esac
  task=$(dirname "$run" | sed 's|^\./||')
  spec="$ROOT/tasks/$task/playbook"
  [ -f "$spec" ] || spec="$ROOT/eval/generated/$task/playbook"
  [ -f "$spec" ] || continue
  sh "$ROOT/eval/lib/playbook-check.sh" "$f" "$spec"
done | awk '$3=="before" || $3=="after" {k=$2" "$3; tot[k]++; if($1=="PASS") p[k]++}
  END { for (k in tot) printf "%-32s %2d/%2d (%3.0f%%)\n", k, p[k], tot[k], 100*p[k]/tot[k] }' | sort -t'(' -k2 -n
