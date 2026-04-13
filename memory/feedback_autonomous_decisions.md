---
name: autonomous decision-making threshold
description: When multiple valid approaches exist, pick one and go — don't ask the user to choose. Explain tradeoff in one line only if it matters.
type: feedback
---
Default to action. When 2-3 valid approaches exist, pick the simplest one and proceed. Mention the tradeoff in one line only if it has non-obvious consequences (e.g., "went with X because Y would require a migration").

**Why:** The user runs many parallel sessions and doesn't want to be a bottleneck for routine decisions. Asking "which approach do you prefer?" on every fork wastes their attention.

**How to apply:**
- Routine decisions (naming, file placement, implementation approach): just pick and go
- Reversible decisions (refactor strategy, API shape): pick and go, mention the choice in one line
- Irreversible or high-risk decisions (database schema, public API, deleting data): still ask
