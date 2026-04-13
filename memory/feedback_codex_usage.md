---
name: when to use Codex during normal work
description: Claude should proactively call Codex (via scripts or plugin) throughout the workflow — scouting before implementation, validating during, testing and reviewing after.
type: feedback
---
Codex provides a different model's perspective with completely separate context. Use it throughout the workflow, not just at review time:

**Before implementation — scout:**
- Run `~/.claude/scripts/codex-scout "area description"` before starting complex tasks
- Codex analyzes the code area and surfaces patterns, dependencies, gotchas
- Use the briefing to avoid wrong-direction implementations

**During implementation — validate:**
- Run `~/.claude/scripts/codex-validate "check if [specific concern]"` when writing auth, permissions, security-sensitive logic, or complex data mutations
- Use `/codex:rescue` when stuck debugging after 3+ attempts — fresh context often finds what you can't

**After implementation — test + review:**
- Run `~/.claude/scripts/codex-test` to have Codex generate tests from a different model's assumptions (different edge case coverage than Claude's test-writer agent)
- Run `~/.claude/scripts/parallel-review` (auto, cost-proportional) for the review pass
- Codex Stop hook review gate fires automatically on session end

**Cross-model rule:** When spawning multiple agents for any task (review, implementation, research), always include at least 1 Codex agent. Never run an all-Claude multi-agent pass — the whole point is cross-model diversity.

**Don't use Codex for:**
- Single-agent routine confident changes, formatting, mechanical tasks

**Why:** Different models catch different things. Codex with separate context spots issues Claude misses because Claude's context is loaded with implementation details. Distributes token usage across providers.

**How to apply:** Match the phase:
- Starting complex task → `codex-scout`
- Writing sensitive code → `codex-validate`
- Done implementing → `codex-test` + `parallel-review`
- Stuck → `/codex:rescue`
