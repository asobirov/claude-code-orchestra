---
name: error recovery behavior
description: When something fails (script, build, test), diagnose and fix in one shot — don't report the error and wait for instructions.
type: feedback
---
When a command, build, test, or script fails: read the error, diagnose the root cause, and fix it in the same turn. Do not report the error and ask what to do.

**Why:** The user expects autonomous problem-solving. Reporting an error and waiting is the same as doing nothing.

**How to apply:**
- Build/lint/test failure: read the output, fix the code, re-run
- Script syntax error: fix the script, re-run
- Permission denied: check why, adjust approach
- Only escalate after 2-3 failed fix attempts with different approaches
