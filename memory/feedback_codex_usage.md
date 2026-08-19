---
name: when to use Codex during normal work
description: Claude should bring Codex in for cross-model review after implementation and before release; ad-hoc Codex work goes through the plugin commands, not standalone scripts.
type: feedback
originSessionId: 0b3a4686-3fdb-4c1f-9c4a-cac1f0fabc27
---
Codex provides a different model's perspective with completely separate context.

**After implementation — review:**
- Run `~/.claude/scripts/parallel-review` (auto, cost-proportional) — 1-3 agents, always at least one Codex

**Before release:**
- Run `~/.claude/scripts/full-audit --base main` — 5 agents (3 Codex + 2 Claude)

**Ad-hoc Codex during work:**
- `/codex:rescue` when stuck debugging after 3+ attempts — fresh context often finds what you can't
- `/codex:review`, `/codex:adversarial-review` for a standalone Codex pass
- `codex exec --sandbox read-only --ephemeral "<prompt>"` for a one-off question

**Cross-model rule:** When spawning multiple agents for any task (review, implementation, research), always include at least 1 Codex agent. Never run an all-Claude multi-agent pass — the whole point is cross-model diversity.

**Don't use Codex for:** single-agent routine confident changes, formatting, mechanical tasks.

**Why:** Different models catch different things. Codex with separate context spots issues Claude misses because Claude's context is loaded with implementation details. Distributes token usage across providers.

**How to apply:** Done implementing → `parallel-review`. Pre-release → `full-audit`. Stuck → `/codex:rescue`.

The standalone `codex-scout` / `codex-validate` / `codex-test` / `codex-review` / `best-of-n` scripts were removed on 2026-08-19 — zero runs in two months of transcripts. See [[agent_orchestration_setup]]. Don't re-add references to them; if a phase genuinely needs one, restore it from `~/dev/claude-code-orchestra/scripts/archive/` AND give it a CLAUDE.md trigger, or it will go unused again.
