#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COND="${1:?usage: matrix.sh <condition> <reps> [task-glob]}"
REPS="${2:?reps required}"
GLOB="${3:-*}"

for t in "$ROOT"/tasks/*/"$GLOB" "$ROOT"/eval/generated/"$GLOB"; do
  [ -d "$t/fixture" ] || continue
  id="$(basename "$(dirname "$t")")/$(basename "$t")"
  case "$t" in *generated*) id="generated/$(basename "$t")";; esac
  for rep in $(seq 1 "$REPS"); do
    sh "$ROOT/eval/run.sh" "$id" "$COND" "$rep" || true
  done
done
