---
name: phase isolation and context management
description: At clear phase boundaries during long tasks, prefer spawning subagents for independent phases over accumulating everything in the main context. Track context usage and suggest /compact when phases are complete and context is filling up.
type: feedback
---
When working on multi-phase tasks (research → plan → implement → test → review, or feature A → feature B → feature C), prefer **isolation over accumulation**:

**Soft suggestion: subagents for independent phases**
- If the next phase doesn't need detailed context from the current one (only the summary), spawn it as a subagent via the Agent tool
- Subagent gets fresh context, does focused work, returns a summary
- Parent context only accumulates per-phase summaries, not the full implementation history
- Examples of independent phases: research → implementation, frontend → backend, separate feature modules, exploration → execution

**Context awareness:**
- After every completed phase, briefly evaluate whether `/compact` would help
- Decision criteria: is the bulk of the conversation history still load-bearing for what comes next, or is most of it now just noise that the model doesn't need to keep around?
- If most of the history is no longer needed for the next phase → suggest `/compact` with a one-line note on what to preserve
- If the history is still actively informing the next phase → keep it
- Don't suggest `/compact` reflexively after every phase — only when the cost-benefit is clear

**When NOT to isolate:**
- Phases that build directly on each other's intermediate decisions
- Tight iteration loops (debugging, refactoring with frequent back-and-forth)
- When the user wants to stay in the loop on every detail

**How to apply:**
- After completing a logical phase, briefly note: "phase X complete — next phase Y looks independent, want me to spawn it as a subagent?"
- For pure execution phases (run tests, lint, build), just do it inline
- For research/exploration phases that produce a summary, default to subagents
- For implementation phases on a different module/area, suggest subagent
- Track: if 3+ major phases have completed in one session, proactively suggest `/compact` at the next boundary

**Why:** Long sessions accumulate context that's no longer needed. Subagents preserve information through isolation; compaction preserves it through summarization. Both beat hitting auto-compact at the limit, which is reactive instead of intentional.
