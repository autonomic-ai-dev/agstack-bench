# agstack-bench

A benchmark for the agstack playbook catalog: does following the process produce better work than not, across the whole software lifecycle — not just bug fixes.

Each task is a self-contained broken repo. An agent runs it under a condition (`none` = bare, `agstack` = policy + skills injected). Grading is split: **hidden outcome** (did the thing get fixed) and **protocol** (was the playbook read before the first edit, was the plan hydrated, were demerits avoided) — because the question is whether the process helps, not whether agents can fix things.

## Tiers

| Tier | What it measures | Example |
|---|---|---|
| T1 conformance | Does the agent enter the protocol at all — playbook read, plan hydrated, core refs | `checklist-hydration` |
| T2 lifecycle | One playbook, one realistic defect, graded outcome + protocol | `host-env` |
| T3 pipeline | A chain of playbooks; graded on handoff artifacts, not just the fix | `incident-chain` (incident → bug-fix → postmortem) |
| T4 frontier | Generated, seeded tasks the agent has never seen — new seed, new task | `generators/config-port.sh` |

## Run a task

```sh
sh eval/run.sh t2-lifecycle/host-env agstack 1
sh eval/run.sh t2-lifecycle/host-env none 1
```

Results append to `.verify/artifacts/eval/results.tsv` (12 columns: task, condition, rep, hidden, comments, tests_changed, turns, cost, err, denials, agent_exit, playbook).

## Generate an unseen task

```sh
TASK=$(sh eval/gen_task.sh config-port 42)      # -> generated/config-port-42
sh eval/run.sh "$TASK" agstack 1
```

Every seed materializes a different fixture (names, values, bug variant) with a deterministic grader. New seeds are new tasks — the frontier set can grow without bound and nothing in it can be memorized.

## Compare conditions

```sh
sh eval/gate.sh none agstack t2-lifecycle/host-env   # needs MIN_REPS (default 5) per condition
```

## Add a task

```text
tasks/<tier>/<name>/
  prompt.md      # what the agent sees
  fixture/       # the broken repo, committed as the base state
  hidden.sh      # outcome grader, run inside the run dir (exit 0 = pass)
  playbook       # protocol spec: one "<name> before|after" per line
  meta.toml      # tier, difficulty, playbooks, generated
```

Rules: `hidden.sh` must fail on the fixture as shipped. Fixture `test/` files are the spec — editing them is a demerit; new test files are legitimate. `before` = before the first edit; `after` = after it.

## Relationship to pinakes

pinakes's `packages/agstack/eval/` gates *skill promotion* — is a skill good enough to ship. This repo benches the *playbook content* — does the process hold up across difficulty, across chains, and on tasks nobody wrote down in advance.
