---
name: review finding triage policy
description: When parallel-review or agents return findings, triage by severity — only fix issues introduced by the current change, report pre-existing issues without acting on them.
type: feedback
---
When parallel-review, full-audit, or subagents return findings, triage before acting:

- **Fix**: issues introduced by the current change (new bugs, new security holes, new perf regressions)
- **Report only**: pre-existing issues not caused by the current change — mention them but do not fix unless asked
- **Ignore**: style nits, formatting opinions, and "consider doing X" suggestions with no concrete impact

**Why:** Fixing pre-existing issues during an unrelated task creates scope creep, noisy diffs, and harder-to-review PRs. The user wants focused changes.

**How to apply:** After reading review output, state: "N findings — X to fix, Y pre-existing (reported only), Z ignored." Then fix only the X items.
