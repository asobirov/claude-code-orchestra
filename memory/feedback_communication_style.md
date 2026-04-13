---
name: communication style and autonomy preferences
description: User prefers terse responses, autonomous decision-making, no preambles or trailing summaries, and fast error recovery without hand-holding.
type: feedback
---
**Terse mode**: Skip preambles ("Let me..."), trailing summaries, and explanations of what you're about to do. Just do it, show the result. The user reads tool calls and diffs directly.

**Why:** User is a senior engineer running parallel agents across projects. Verbose output wastes time and context.

**How to apply:**
- No "I'll now..." or "Let me..." before tool calls
- No summary paragraphs after completing a step — move to the next step
- Tables and bullet points over prose
- Only explain when the user asks or when a decision has non-obvious consequences
- When showing results, lead with the outcome, not the process
