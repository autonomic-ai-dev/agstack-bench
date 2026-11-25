#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAMILY="${1:?usage: gen_task.sh <family> <seed>}"
SEED="${2:?seed required}"
GEN="$ROOT/generators/$FAMILY.sh"
OUT="$ROOT/eval/generated/$FAMILY-$SEED"

[ -f "$GEN" ] || { echo "unknown family: $FAMILY (have: $(ls "$ROOT/generators/" | sed 's/\.sh$//' | tr '\n' ' '))" >&2; exit 2; }
rm -rf "$OUT"
mkdir -p "$OUT"
sh "$GEN" "$SEED" "$OUT"
echo "generated/$FAMILY-$SEED"
