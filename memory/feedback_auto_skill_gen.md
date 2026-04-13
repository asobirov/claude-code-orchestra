---
name: auto-generate skills after complex tasks
description: After completing complex multi-step tasks (5+ tool calls, error recovery, non-obvious workflows), automatically create a reusable skill file in ~/.claude/skills/ so future sessions have the playbook.
type: feedback
---
After completing a complex task that involved non-obvious steps, error recovery, or a multi-step workflow that future sessions would benefit from knowing, create a skill file at `~/.claude/skills/<skill-name>/SKILL.md`.

**Why:** Knowledge from complex debugging, tricky configurations, or multi-step procedures gets lost after the session ends. Git history shows what changed but not the reasoning or the procedure. A skill file preserves the playbook so any future session can reuse it instantly.

**How to apply:**

Triggers (create a skill when ANY of these apply):
- Task required 5+ tool calls with error recovery or retries
- Solution involved a non-obvious workaround or specific flag/config
- Same pattern is likely to recur (build issues, deployment steps, migration procedures)
- User explicitly asks to remember a workflow

Do NOT create skills for:
- Routine code changes (feature implementation, bug fixes)
- One-off tasks unlikely to recur
- Things already documented in CLAUDE.md or existing skills

Skill file format:
```markdown
---
name: <kebab-case-name>
description: <when to use this skill — be specific so future sessions can match it>
---

# <Title>

## When to Use
<Concrete triggers — what error message, what scenario, what the user might say>

## Procedure
<Step-by-step with exact commands, file paths, flags>

## Pitfalls
<What went wrong the first time, what to watch out for>

## Verification
<How to confirm it worked>
```

Keep skills focused and under 200 lines. One skill per procedure. Place supporting scripts in a `scripts/` subdirectory if needed.
