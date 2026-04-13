---
name: automatic post-implementation and pre-release reviews
description: User wants parallel multi-agent reviews to run automatically after implementation and before releases — never require manual triggering.
type: feedback
---
After completing any implementation task that changes code (not formatting-only), automatically run `~/.claude/scripts/parallel-review` before wrapping up. Do not ask — just run it. Read the findings and address anything legitimate before finishing.

**Why:** User wants multi-model coverage (Claude + Codex) on every implementation, not just single-model self-review. Different models catch different issues. The Codex Stop hook review gate is a safety net, but the parallel-review gives broader coverage with specialized focus areas.

**How to apply:**
- After implementing features or fixing bugs, run `~/.claude/scripts/parallel-review` (3 agents: 2 Codex + 1 Claude)
- Skip for trivial changes (formatting, comments, typo fixes)
- For pre-release or pre-merge audits, run `~/.claude/scripts/full-audit --base main` (5 agents: 3 Codex + 2 Claude, more comprehensive)
- The Codex review gate Stop hook also fires automatically on session end as a final safety net
- Claude subagents (security-reviewer, perf-auditor, arch-reviewer, test-writer) should still be spawned organically during implementation when relevant
