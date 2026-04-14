---
name: claude-code-orchestra
description: |
  Multi-agent workflow helper for Claude Code + OpenAI Codex. Use PROACTIVELY when:
  (1) The user completes any implementation task that changed code (not formatting-only) — auto-run parallel-review
  (2) The user is preparing to release, merge, or ship a branch — run full-audit against the base branch
  (3) The user has a complex or ambiguous task where multiple approaches could work — use best-of-n
  (4) The user is about to work on an unfamiliar or complex area — run codex-scout for a pre-implementation briefing
  (5) The user needs tests for recent changes — run codex-test (different model = different edge cases)
  (6) The user is stuck debugging after 3+ attempts — use /codex:rescue for a fresh perspective
  Never run an all-Claude multi-agent pass — the whole point is cross-model diversity.
---

# claude-code-orchestra

Scripts and agents that pair Claude Code with OpenAI Codex for cross-model review and orchestration.

## Available scripts (all in `~/.claude/scripts/`)

### parallel-review — Cost-proportional multi-agent review

Run after every implementation task. Auto-scores change complexity and spawns 1-3 agents accordingly.

```bash
# Review uncommitted changes (auto-scoring)
~/.claude/scripts/parallel-review

# Review against a base branch
~/.claude/scripts/parallel-review --base main

# Force a specific agent count (override scoring)
~/.claude/scripts/parallel-review --agents 3

# Review a specific commit
~/.claude/scripts/parallel-review --commit abc123
```

**Scoring:**
- Score 0 (formatting only, <5 code lines) → skipped entirely
- Score 1 (small, non-sensitive) → 1 Codex agent (security + correctness)
- Score 2 (moderate or touches API/config) → 2 agents (Codex + Claude)
- Score 3+ (large or hits auth/DB/deps) → 3 agents (full pass)

Scoring factors: lines changed, files touched, and whether the diff touches auth/API/database/env/dependency files.

### full-audit — Comprehensive pre-release audit

Run before releases, merges, or major PRs. 5 agents in parallel (3 Codex + 2 Claude).

```bash
# Audit uncommitted changes
~/.claude/scripts/full-audit

# Audit full branch diff against base
~/.claude/scripts/full-audit --base main
```

The 5 agents cover: security & correctness, architecture & code quality, edge cases & test coverage, breaking changes & API compatibility, release readiness checklist.

### best-of-n — Competing implementations with synthesizer

Use for complex or ambiguous tasks where multiple approaches could work.

```bash
~/.claude/scripts/best-of-n "refactor the picker to use a state machine"
~/.claude/scripts/best-of-n --agents 2 "fix the N+1 query in property listing"
```

Spawns N agents (alternating Claude/Codex) implementing the same task independently, then a synthesizer reviews all solutions and produces the best combined version with explanation of what it kept and rejected.

### codex-scout — Pre-implementation briefing

Run before starting work in a complex or unfamiliar area. Codex surfaces patterns, dependencies, gotchas from a fresh perspective.

```bash
~/.claude/scripts/codex-scout "the picker component"
~/.claude/scripts/codex-scout "auth middleware and session handling"
~/.claude/scripts/codex-scout "property listing API route"
```

### codex-test — Test generation from a different model

Different model = different edge case assumptions than Claude's `test-writer` agent.

```bash
# Test uncommitted changes
~/.claude/scripts/codex-test

# Test branch diff
~/.claude/scripts/codex-test --base main

# Test a specific area
~/.claude/scripts/codex-test "picker component"
```

### codex-review — Quick single-agent review

Lighter-weight than parallel-review. Use when you only want a Codex-only second opinion.

```bash
~/.claude/scripts/codex-review
~/.claude/scripts/codex-review --base main
~/.claude/scripts/codex-review --base main "focus on auth logic"
```

### codex-validate — Ad-hoc Codex task

Run Codex with a custom prompt against the codebase in a read-only sandbox.

```bash
~/.claude/scripts/codex-validate "check if the API routes handle auth correctly"
~/.claude/scripts/codex-validate "trace how session tokens flow from login to database"
```

## Available custom agents (auto-spawned when relevant)

Claude Code auto-discovers these from `~/.claude/agents/` and spawns them as subagents when relevant:

| Agent | Tools | Use it for |
|---|---|---|
| `security-reviewer` | Read, Grep, Glob | Auth code, API routes, form handling, sensitive data flows |
| `perf-auditor` | Read, Grep, Glob | React/RN components, database queries, hot paths |
| `arch-reviewer` | Read, Grep, Glob | PRs, refactors, new modules (includes blast radius analysis) |
| `test-writer` | Read, Grep, Glob, Edit, Write, Bash | Writing tests for new or changed code |

You can also invoke them explicitly: "run security-reviewer on the auth module" or let Claude pick them up automatically based on the code you're touching.

## Codex plugin commands (from `codex@openai-codex`)

| Command | Purpose |
|---|---|
| `/codex:review` | Read-only Codex review of uncommitted changes or a branch diff |
| `/codex:adversarial-review` | Steerable challenge review (tradeoffs, risks, race conditions) |
| `/codex:rescue` | Delegate a stuck task to Codex with a fresh perspective |
| `/codex:setup --enable-review-gate` | Enable the stop-time review gate for the current repo |
| `/codex:status` / `/codex:result` / `/codex:cancel` | Manage background Codex jobs |

## The automatic workflow

```
You give Claude a task
  │
  ├─ Complex or unfamiliar area?
  │    → codex-scout for a briefing before starting
  │
  ├─ During implementation
  │    Claude spawns security-reviewer / perf-auditor / arch-reviewer
  │    when the code warrants it (automatic, organic)
  │
  ├─ Writing sensitive code (auth, permissions, data mutations)?
  │    → codex-validate for a mid-task cross-model check
  │
  ├─ Stuck after 3+ debug attempts?
  │    → /codex:rescue
  │
  ├─ After implementation
  │    → parallel-review runs automatically (cost-proportional)
  │    → codex-test generates tests from a different model's assumptions
  │
  ├─ On stop
  │    → Codex review gate fires (if enabled) — blocks if issues remain
  │
  └─ Before release
       → full-audit --base main (5 agents, comprehensive)
```

## Behavioral rules loaded from memory

When this skill is installed alongside the behavioral memory files, future Claude sessions automatically follow these rules:

- **Auto-review**: run `parallel-review` after every implementation (not formatting-only)
- **Auto-audit**: run `full-audit --base main` before releases
- **Review triage**: fix only issues from the current change, report pre-existing ones without acting
- **Cross-model rule**: never run an all-Claude multi-agent pass — always include at least 1 Codex
- **Codex usage**: scout before, validate during, test and review after — not just at the end
- **Phase isolation**: at phase boundaries prefer subagents for independent work
- **Autonomous decisions**: pick and go on routine/reversible choices
- **Error recovery**: diagnose and fix in one shot, don't report and wait
- **Communication**: terse — no preambles, no trailing summaries

## When NOT to use these scripts

- **Formatting-only changes** — parallel-review auto-skips (score 0)
- **Single-line typo fixes** — overkill; just make the fix
- **Read-only exploration sessions** — no changes to review
- **Inside a Codex Stop hook** — infinite loop risk; the Stop hook runs Codex review on exit

## Prerequisites

- Claude Code authenticated and running
- Codex CLI installed (`brew install --cask codex` or `npm install -g @openai/codex`) and logged in (`codex login`)
- Codex plugin installed: `claude plugin marketplace add openai/codex-plugin-cc && claude plugin install codex@openai-codex --scope user`
- Bash permissions pre-approved in `~/.claude/settings.json` for all scripts
- Git — all scripts require being inside a git repository

The installer at the repo root (`./install.sh`) handles everything above.
