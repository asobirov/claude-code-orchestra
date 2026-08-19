# Instructions for Claude Code (or another AI agent) installing this repo

You're installing `claude-code-orchestra` into the user's Claude Code environment. Follow these steps exactly.

## Prerequisites check

Before doing anything else, verify:

1. `claude` CLI is in PATH → `command -v claude`
2. `codex` CLI is in PATH → `command -v codex`
3. `jq` is in PATH → `command -v jq`
4. `~/.claude/` directory exists

If Codex is missing, offer to install it: `brew install --cask codex` (macOS) or `npm install -g @openai/codex`. If jq is missing, prompt the user to run `brew install jq` before continuing.

## Installation

Run the installer:

```bash
./install.sh
```

It handles:
- Copying `scripts/` → `~/.claude/scripts/` with +x
- Copying `agents/` → `~/.claude/agents/`
- Copying `skills/` → `~/.claude/skills/`
- Copying `memory/` → `~/.claude/projects/<encoded-home>/memory/`, merging `MEMORY.md`
- Adding required Bash permissions to `~/.claude/settings.json` via `jq`
- Installing the Codex plugin (`openai/codex-plugin-cc`) if not present

The installer is interactive — it asks before overwriting differing files. If running non-interactively, pre-empt conflicts by removing any existing files you intend to replace.

## Post-install verification

After `install.sh` completes, verify:

```bash
# Scripts installed and executable
ls -l ~/.claude/scripts/ | grep -E "parallel-review|full-audit|agents.env"

# Agents installed
ls ~/.claude/agents/

# Skill installed
ls ~/.claude/skills/claude-code-orchestra/

# Memory files installed
ls ~/.claude/projects/*/memory/feedback_*.md

# Codex plugin enabled
claude plugin list | grep codex

# Permissions present in settings
jq '.permissions.allow | map(select(test("scripts/")))' ~/.claude/settings.json
```

## Session restart required

Tell the user: **"Restart any running Claude Code sessions so the plugin, permissions, and memory files take effect."** The memory files in particular are loaded at session start — existing sessions won't see the behavioral rules until they restart.

## Enabling the Codex review gate (per-repo, optional)

Inside any git repo where the user wants the Stop-hook review gate:

```bash
node ~/.claude/plugins/cache/openai-codex/codex/<VERSION>/scripts/codex-companion.mjs setup --json --enable-review-gate
```

Replace `<VERSION>` with the installed Codex plugin version (check with `ls ~/.claude/plugins/cache/openai-codex/codex/`).

The gate is persistent — enabled once per repo path, applies forever.

## Things to explain to the user after install

1. **Most of this runs automatically**. The behavioral memory files tell future Claude sessions to run `parallel-review` after implementation, triage findings, and auto-generate skills. The user doesn't need to manually trigger anything.

2. **Scripts are available as Bash commands**, pre-approved in settings. Any Claude session can call `~/.claude/scripts/parallel-review` or `~/.claude/scripts/full-audit` without permission prompts.

3. **Custom agents auto-spawn**. Claude Code will automatically use `security-reviewer`, `perf-auditor`, `arch-reviewer`, and `test-writer` when it sees code that matches their descriptions.

4. **The Codex review gate is opt-in per repo**. Walk the user through enabling it on repos where they want automatic stop-time review.

## If something breaks

- **Scripts fail with permission denied**: `chmod +x ~/.claude/scripts/*`
- **`parallel-review` fails with "Not in a git repository"**: expected — the scripts require git context
- **Codex commands fail**: check `codex login` status; Codex needs to be authenticated
- **Memory files not loading**: verify they're in `~/.claude/projects/<encoded-home>/memory/` where `<encoded-home>` is the home path with `/` replaced by `-` (e.g., `-Users-alice`)
- **Settings.json corrupted**: the installer uses `jq` atomic writes; restore from `~/.claude/settings.json.bak` if one was created, or manually add the permissions listed in the installer script

## Uninstalling

No uninstaller is provided. Remove manually:

```bash
rm ~/.claude/scripts/{parallel-review,full-audit,agents.env}
rm ~/.claude/agents/{security-reviewer,perf-auditor,arch-reviewer,test-writer}.md
rm ~/.claude/projects/*/memory/feedback_{auto_review,auto_skill_gen,communication_style,review_triage,autonomous_decisions,error_recovery,typo_tolerance,codex_usage,codex_gate_bootstrap,phase_isolation}.md
rm ~/.claude/projects/*/memory/agent_orchestration_setup.md
# Then manually clean up MEMORY.md index and settings.json permissions
```
