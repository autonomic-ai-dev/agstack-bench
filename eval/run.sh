#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK="${1:?usage: run.sh <task-id> <condition: none|agstack> <rep>  (task-id: tN-tier/name or generated/<family>-<seed>)}"
COND="${2:?condition required}"
REP="${3:?rep required}"

TASKDIR="$ROOT/tasks/$TASK"
[ -d "$TASKDIR" ] || TASKDIR="$ROOT/eval/generated/$TASK"
[ -d "$TASKDIR/fixture" ] || { echo "unknown task: $TASK" >&2; exit 2; }

AGSTACK_DIR="${AGSTACK_DIR:-$ROOT/../pinakes/packages/agstack}"
OUT="$ROOT/.verify/artifacts/eval/$TASK/$COND-$REP"
RESULTS="$ROOT/.verify/artifacts/eval/results.tsv"

rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$TASKDIR/fixture/." "$OUT/"
cd "$OUT"
git init -q
git add -A
git -c user.email=bench@local -c user.name=bench -c commit.gpgsign=false commit -q -m base

mkdir -p .claude
case "$COND" in
  none) ;;
  agstack)
    if [ -d "$AGSTACK_DIR/skills" ]; then
      cp -R "$AGSTACK_DIR/skills" .claude/skills
      [ -f "$AGSTACK_DIR/AGENTS.md" ] && cp "$AGSTACK_DIR/AGENTS.md" CLAUDE.md
    elif [ -d "$HOME/.agents/skills" ]; then
      cp -R "$HOME/.agents/skills" .claude/skills
    else
      echo "no agstack skills found (set AGSTACK_DIR or install via skills add)" >&2; exit 2
    fi
    ;;
  *) echo "unknown condition: $COND" >&2; exit 2 ;;
esac
printf '.claude/\nCLAUDE.md\nAGENTS.md\n' >> .git/info/exclude

PROMPT="$(cat "$TASKDIR/prompt.md")"
case "$COND" in
  agstack) PROMPT="Use agstack for this task: load the agstack-mode skill first, pick the matching playbook from its routing table, and follow it before editing. $PROMPT" ;;
esac

set +e
claude -p "$PROMPT" \
  --setting-sources project \
  --permission-mode acceptEdits \
  --allowedTools "Skill" "Read" "Edit" "Write" "Grep" "Glob" "TodoWrite" "Bash(sh:*)" "Bash(bash:*)" "Bash(git:*)" "Bash(ls:*)" "Bash(cat:*)" "Bash(grep:*)" "Bash(printf:*)" "Bash(echo:*)" "Bash(find:*)" "Bash(mkdir:*)" "Bash(cp:*)" "Bash(awk:*)" "Bash(sed:*)" "Bash(od:*)" "Bash(mktemp:*)" "Bash(cd:*)" "Bash(head:*)" "Bash(tail:*)" "Bash(wc:*)" "Bash(tr:*)" "Bash(sort:*)" "Bash(diff:*)" "Bash(touch:*)" "Bash(test:*)" "Bash(.:*)" \
  --output-format stream-json --verbose \
  --max-budget-usd 2.00 \
  --no-session-persistence > claude.jsonl 2> claude.err
AGENT_EXIT=$?
set -e
jq -s 'map(select(.type == "result")) | last' claude.jsonl > claude.json

COST="$(jq -r '.total_cost_usd // 0' claude.json)"
TURNS="$(jq -r '.num_turns // 0' claude.json)"
ERR="$(jq -r '.is_error' claude.json)"
DENIALS="$(jq -r '.permission_denials | length' claude.json)"

git add -A
ADDED_COMMENTS="$(git diff --cached HEAD -- lib bin srv app 2>/dev/null | grep -c '^+[[:space:]]*#' || true)"
TESTS_CHANGED="$(git diff --cached --name-only --diff-filter=MD HEAD -- test | wc -l | tr -d ' ')"

cp "$TASKDIR/hidden.sh" .grade_hidden.sh
set +e
sh .grade_hidden.sh > grade.out 2>&1
HIDDEN_EXIT=$?
set -e
rm -f .grade_hidden.sh

PLAYBOOK_VERDICT=na
if [ -f "$TASKDIR/playbook" ] && [ "$COND" != none ]; then
  PLAYBOOK_REPORT="$(sh "$ROOT/eval/lib/playbook-check.sh" claude.jsonl "$TASKDIR/playbook")"
  PLAYBOOK_VERDICT="$(printf '%s\n' "$PLAYBOOK_REPORT" | tail -n 1)"
  printf 'playbook-check:\n%s\n' "$PLAYBOOK_REPORT" >> grade.out
fi

mkdir -p "$(dirname "$RESULTS")"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$TASK" "$COND" "$REP" "$HIDDEN_EXIT" "$ADDED_COMMENTS" "$TESTS_CHANGED" "$TURNS" "$COST" "$ERR" "$DENIALS" "$AGENT_EXIT" "$PLAYBOOK_VERDICT" \
  >> "$RESULTS"
echo "$TASK $COND $REP hidden=$HIDDEN_EXIT playbook=$PLAYBOOK_VERDICT comments=$ADDED_COMMENTS tests_changed=$TESTS_CHANGED turns=$TURNS cost=$COST denials=$DENIALS"
