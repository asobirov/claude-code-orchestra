---
name: claude-code-orchestra
description: |
  Multi-agent workflow helper for Claude Code + OpenAI Codex. Use PROACTIVELY when:
  (1) The user completes any implementation task that changed code (not formatting-only) — auto-run parallel-review
  (2) The user is preparing to release, merge, or ship a branch — run full-audit against the base branch
  (3) The user is stuck debugging after 3+ attempts — use /codex:rescue for a fresh perspective
  Never run an all-Claude multi-agent pass — the whole point is cross-model diversity.
---

# claude-code-orchestra

Scripts and agents that pair Claude Code with OpenAI Codex for cross-model review and orchestration.

## Models

Both scripts source `~/.claude/scripts/agents.env` — the one place to bump models.

| Side | Default | Per-run override |
|---|---|---|
| Codex | `gpt-5.6-sol`, reasoning effort `high` | `--codex-model <id>` / `--codex-effort <minimal\|low\|medium\|high\|xhigh>` |
| Claude | `opus` (alias → latest frontier Opus), effort `high` | `--claude-model <id>` / `--claude-effort <low\|medium\|high\|xhigh\|max>` |

Precedence: CLI flag > `ORCHESTRA_*` env var > `agents.env` > in-script fallback.
`ORCHESTRA_CLAUDE_EFFORT`, not `CLAUDE_EFFORT` — the latter is set by Claude Code
itself in every child process. Pass `--claude-model opus[1m]` for 1M context on
very large diffs.

## Available scripts (all in `~/.claude/scripts/`)

Only two — `parallel-review` and `full-audit`. Five others (`best-of-n`, `codex-scout`,
`codex-test`, `codex-review`, `codex-validate`) were retired on 2026-08-19 after zero runs
in two months; they live at `~/dev/claude-code-orchestra/scripts/archive/`. Ad-hoc Codex work
goes through the plugin commands below or `codex exec` directly.

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
  ├─ During implementation
  │    Claude spawns security-reviewer / perf-auditor / arch-reviewer
  │    when the code warrants it (automatic, organic)
  │
  ├─ Stuck after 3+ debug attempts?
  │    → /codex:rescue
  │
  ├─ After implementation
  │    → parallel-review runs automatically (cost-proportional)
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
- **Codex usage**: cross-model review after implementation; `/codex:rescue` when stuck
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
