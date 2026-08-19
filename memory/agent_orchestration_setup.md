---
name: agent orchestration setup
description: User's multi-agent setup — Claude + Codex integration, the two review scripts in ~/.claude/scripts/, custom agent definitions, and the Codex plugin. Includes which models the scripts drive and where defaults live.
type: project
originSessionId: 0b3a4686-3fdb-4c1f-9c4a-cac1f0fabc27
---
Multi-agent orchestration setup, trimmed to what actually gets used (as of 2026-08-19).

**Scripts** in `~/.claude/scripts/`:
- `parallel-review` — **cost-proportional**: auto-scores change complexity (lines, files, sensitive patterns), then spawns 1-3 agents. Score 0 = skip (formatting only), 1 = 1 Codex, 2 = Codex + Claude, 3+ = full 3 agents. Override with `--agents N` (1-3).
- `full-audit` — pre-release audit, 5 agents (3 Codex + 2 Claude): security, architecture, edge cases, breaking changes, release readiness. Use `--base main` for branch audits.
- `agents.env` — the single place model defaults live. Codex `gpt-5.6-sol` effort `high`; Claude `opus` effort `high`. Precedence: CLI flag > `ORCHESTRA_*` env var > `agents.env` > in-script fallback.

Override per run with `--codex-model` / `--codex-effort` / `--claude-model` / `--claude-effort`.

**The env var prefix is load-bearing:** it's `ORCHESTRA_CLAUDE_EFFORT`, not `CLAUDE_EFFORT`. Claude Code exports `CLAUDE_EFFORT` into every child process, so the unprefixed name makes the review agents silently inherit the parent session's effort instead of their own.

**Trimmed 2026-08-19:** `best-of-n`, `codex-scout`, `codex-test`, `codex-review`, `codex-validate` were removed — 0 runs in ~2 months of transcripts (151 for `parallel-review`, 8 for `full-audit` over the same window). Fixed versions are archived at `~/dev/claude-code-orchestra/scripts/archive/`.

**Why only those two survived:** usage tracks the `~/.claude/CLAUDE.md` mandate, not the skill description. `parallel-review` and `full-audit` are the two CLAUDE.md requires. "Use PROACTIVELY when…" in a SKILL.md drives nothing. Adding a tool without a CLAUDE.md trigger means it won't get reached for. See [[feedback_codex_usage]].

**Custom Agents** in `~/.claude/agents/` — `security-reviewer`, `perf-auditor`, `arch-reviewer`, `test-writer`. Kept deliberately despite near-zero invocation (1 in two months).

**Codex Plugin** — `codex@openai-codex` v1.0.3 at user scope: `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`.

**Codex CLI** — `~/.codex/config.toml` sets `gpt-5.6-sol`, effort `high`, pragmatic personality; installed at /opt/homebrew/bin/codex.

**Source repo** — `~/dev/claude-code-orchestra` (install.sh copies scripts/agents/memory into ~/.claude/). `agents.env` is seeded but never clobbered on reinstall.

**User preference:** Skipped `type: "prompt"` PostToolUse hooks — parallel-review at the end is sufficient, no need for per-edit semantic checks.
