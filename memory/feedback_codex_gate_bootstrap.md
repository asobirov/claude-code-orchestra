---
name: Codex review gate auto-enable
description: When starting work in a git repo where the Codex review gate is not yet enabled, offer to enable it. Once enabled, it persists forever for that path.
type: feedback
---
When a session starts in a git repo where the Codex review gate is not yet enabled, and the session involves real implementation work (not just reading), offer to enable the gate once:

"Codex review gate is not enabled for this repo. Enable it? (it'll fire automatically before the session ends to catch issues Claude might miss)"

If yes: run `node ~/.claude/plugins/cache/openai-codex/codex/1.0.3/scripts/codex-companion.mjs setup --json --enable-review-gate`

**Why:** The gate is persistent once enabled, but it has to be enabled per-repo. Rather than manually remembering to enable it on every new repo, Claude should offer it when it first encounters an unprotected repo during real work.

**How to apply:**
- Check the gate status with: `node ~/.claude/plugins/cache/openai-codex/codex/1.0.3/scripts/codex-companion.mjs setup --json | python3 -c "import sys,json; print(json.load(sys.stdin).get('reviewGateEnabled'))"`
- Only ask once per repo per session (don't pester)
- Don't ask for read-only/exploration sessions
- Don't ask if user explicitly opts out (save that decision to project memory: "no gate for this repo")
- If the user says yes, enable it and continue silently

**Note:** The `1.0.3` in the path is the Codex plugin version. Update to match the currently installed version — find it with `ls ~/.claude/plugins/cache/openai-codex/codex/`.
