# claude-code-orchestra

A multi-agent workflow setup for [Claude Code](https://claude.com/claude-code), pairing it with [OpenAI Codex](https://github.com/openai/codex) for cross-model review and orchestration. Installs scripts, specialized agent definitions, and behavioral memory files that turn Claude Code into a manager for parallel reviewers, synthesizers, and auditors.

## What you get

### Scripts (`~/.claude/scripts/`)

| Script | Purpose |
|---|---|
| `parallel-review` | Cost-proportional review. Auto-scores change complexity (lines, files, sensitive patterns) and spawns 1-3 agents accordingly. Score 0 skips entirely, score 3+ runs full 2-Codex + 1-Claude pass. |
| `full-audit` | Pre-release audit with 5 agents (3 Codex + 2 Claude): security, architecture, edge cases, breaking changes, release-readiness checklist. |
| `best-of-n` | Spawn N agents implementing the same task independently, then a synthesizer picks the best ideas from each. |
| `codex-scout` | Pre-implementation briefing: Codex analyzes a code area and surfaces patterns, dependencies, gotchas before you start. |
| `codex-test` | Codex generates tests for recent changes or a specific area. Different model = different edge case assumptions. |
| `codex-review` | Quick single-agent Codex review. |
| `codex-validate` | Ad-hoc Codex task with a custom prompt, read-only sandbox by default. |

### Agents (`~/.claude/agents/`)

| Agent | Tools | Focus |
|---|---|---|
| `security-reviewer` | Read, Grep, Glob | OWASP-style vulnerability scanning. |
| `perf-auditor` | Read, Grep, Glob | React/RN re-renders, N+1 queries, memory leaks, bundle size. |
| `arch-reviewer` | Read, Grep, Glob | Pattern consistency + blast radius analysis (traces callers/imports of changed code). |
| `test-writer` | Read, Grep, Glob, Edit, Write, Bash | Generates tests following existing project conventions. |

Claude Code auto-discovers these and spawns them as subagents when relevant. You can also invoke them explicitly.

### Skill (`~/.claude/skills/claude-code-orchestra/`)

A single auto-discoverable skill (`claude-code-orchestra`) that documents every script, agent, and workflow in one place. Claude Code reads the skill description at session start and loads the full content when relevant. This is the canonical reference for how to use the setup — the behavioral memory tells Claude *when* to act, the skill tells it *how*.

### Behavioral memory (`~/.claude/projects/<home>/memory/`)

Rules every future Claude Code session picks up automatically:

- **Auto-review policy** — run `parallel-review` after every implementation, `full-audit` before releases
- **Auto-skill generation** — after complex multi-step tasks, write reusable skill files for future sessions
- **Communication style** — terse; no preambles or trailing summaries
- **Review triage** — fix only issues from the current change, report pre-existing ones without acting
- **Autonomous decisions** — pick and go on routine/reversible choices, only ask on irreversible ones
- **Error recovery** — diagnose and fix in one shot
- **Typo tolerance** — interpret intent, never correct spelling
- **Codex usage** — proactively use Codex mid-task (scout, validate, rescue) not just for final review
- **Codex gate auto-enable** — offer to enable the Codex Stop-hook review gate on new repos
- **Phase isolation** — at phase boundaries, prefer subagents for independent work; suggest `/compact` when context fills up

## Install

```bash
git clone https://github.com/asobirov/claude-code-orchestra.git
cd claude-code-orchestra
./install.sh
```

The installer:

1. Copies scripts to `~/.claude/scripts/` and makes them executable
2. Copies agent definitions to `~/.claude/agents/`
3. Copies the skill to `~/.claude/skills/claude-code-orchestra/`
4. Copies behavioral memory files and merges `MEMORY.md` with any existing index
5. Adds required Bash permissions to `~/.claude/settings.json` via `jq`
6. Installs the official Codex plugin (`openai/codex-plugin-cc`) if not already present

Existing files that differ are never silently overwritten — you're prompted.

### Prerequisites

- [Claude Code](https://claude.com/claude-code) installed and authenticated
- [Codex CLI](https://github.com/openai/codex) installed (`brew install --cask codex` or `npm install -g @openai/codex`) and authenticated
- `jq` (`brew install jq`)

### For another Claude session to install this

If you're a Claude Code instance setting this up for a user, run:

```bash
git clone https://github.com/asobirov/claude-code-orchestra.git /tmp/claude-code-orchestra && \
  /tmp/claude-code-orchestra/install.sh
```

Then tell the user to restart any running Claude Code sessions so the new plugin, permissions, and memory files take effect.

## Workflow

```
Implementation
  ├─ Claude spawns specialized agents organically when code warrants it
  │  (security-reviewer for auth code, perf-auditor for hot paths, etc.)
  └─ Complex tasks → Claude writes a skill file to ~/.claude/skills/ for reuse

Post-implementation
  ├─ parallel-review runs automatically (cost-proportional, 0-3 agents)
  └─ Codex review gate fires on stop if enabled — blocks if Codex finds issues

Pre-release
  └─ full-audit --base main — 5-agent comprehensive audit

Complex / ambiguous tasks
  └─ best-of-n "task description" — N competing implementations + synthesizer
```

## Why multi-agent + cross-model

Different models have different blind spots. Running Claude and Codex in parallel with separate contexts catches issues neither would find alone:

- Claude has full repo context; Codex sees only the diff — they find different classes of bugs
- Same-model self-review is easy to game; cross-model adversarial review is not
- Costs distribute across two providers
- Empirically, structured reviewer roles improve SWE-bench scores by ~7 points on average

## What this is not

- Not a fine-tuning or RL setup. All improvement is via skill accumulation and behavioral memory.
- Not an IDE or GUI. It's a set of scripts and config files that integrate with the existing Claude Code CLI.
- Not coupled to any one model. Codex model is configurable (`--codex-model`), Claude uses whatever your session is running.

## Customizing

- **Change Codex model**: edit `~/.codex/config.toml` or pass `--codex-model <name>` to any script
- **Disable auto-review**: remove `feedback_auto_review.md` from the memory directory
- **Tune scoring thresholds**: edit `score_changes()` in `parallel-review`
- **Add new agents**: drop a markdown file into `~/.claude/agents/` with the same YAML frontmatter format

## Credits

Inspired by patterns from:

- [Nous Research's Hermes Agent](https://hermes-agent.nousresearch.com) — auto-skill generation, progressive disclosure
- [adversarial-review](https://github.com/ng/adversarial-review) — Optimizer/Skeptic pattern, cost-proportional review
- [Composio Agent Orchestrator](https://github.com/ComposioHQ/agent-orchestrator) — multi-agent orchestration patterns
- [Emdash](https://github.com/generalaction/emdash) — Best-of-N implementation selection

## License

MIT
