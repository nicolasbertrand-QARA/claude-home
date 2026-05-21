---
name: Run commands directly
description: When user says "run X", execute the command immediately instead of searching for it
type: feedback
---

When the user says "run X", just execute the command directly via Bash. Don't search the filesystem for related files, projects, or aliases first.

**Why:** The user expects direct execution. Searching around wastes time and over-complicates things.

**How to apply:** If the user says "run notion", run `notion`. If it fails, the error will guide next steps.
