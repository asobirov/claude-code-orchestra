---
name: agent orchestration setup
description: Multi-agent setup — Claude + Codex integration, parallel review scripts, custom agent definitions, and Codex plugin. Describes the scripts in ~/.claude/scripts/ and agents in ~/.claude/agents/.
type: project
---
Multi-agent orchestration setup installed from claude-code-orchestra:

**Scripts** in `~/.claude/scripts/`:
- `codex-review` — single-agent Codex review of current changes
- `codex-validate` — run Codex with a custom prompt against the codebase (read-only sandbox)
- `parallel-review` — **cost-proportional**: auto-scores change complexity (lines, files, sensitive patterns), then spawns 1-3 agents accordingly. Score 0 = skip (formatting only), score 1 = 1 Codex, score 2 = Codex + Claude, score 3+ = full 3 agents. Override with `--agents N`.
- `full-audit` — comprehensive pre-release audit, runs 5 agents (3 Codex + 2 Claude): security, architecture, edge cases, breaking changes, and release readiness checklist. Use with `--base main` for branch audits.
- `best-of-n` — spawn N agents (alternating Claude/Codex) implementing the same task independently, then a synthesizer agent combines the best from all solutions. Use for complex or ambiguous tasks where multiple approaches could work.
- `codex-scout` — pre-implementation briefing: Codex analyzes a code area and surfaces patterns, dependencies, gotchas before you start working. Use for complex/unfamiliar areas.
- `codex-test` — Codex generates tests for recent changes or a specific area. Different model = different edge case assumptions than Claude's test-writer agent.

**Why:** User wants Claude as the manager that can call in Codex for validation with completely separate context. Codex sees only the diff, Claude sees the full codebase. Different models catch different things.

**How to apply:** `parallel-review` runs automatically after implementation tasks (see feedback_auto_review.md). `full-audit --base main` for pre-release. Permissions are pre-approved in global settings.json.

**Codex review gate** — enable per-repo via the Codex plugin Stop hook. Fires automatically when Claude tries to stop, blocks if Codex finds issues. See feedback_codex_gate_bootstrap.md.

**Custom Agents** in `~/.claude/agents/`:
- `security-reviewer` — read-only, OWASP-focused vulnerability scanning
- `perf-auditor` — read-only, React/RN performance issues
- `arch-reviewer` — read-only, architectural fit, pattern consistency, and blast radius analysis (traces callers/imports of changed code)
- `test-writer` — read/write, generates tests following project conventions

**Codex Plugin** — `codex@openai-codex` installed at user scope. Provides `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`.

**Codex CLI** — `brew install --cask codex` or `npm install -g @openai/codex`. Default model configurable in `~/.codex/config.toml`.
