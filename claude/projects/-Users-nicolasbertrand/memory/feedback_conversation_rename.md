---
name: Cannot rename conversations programmatically
description: The /rename command is interactive-only; cannot be executed via Bash or tools from within a conversation
type: feedback
---

The CLAUDE.md requires renaming conversations after each prompt. However, `/rename` is a built-in interactive CLI command that cannot be invoked programmatically from within the conversation. When the user asks to rename, tell them immediately to type the command themselves rather than attempting workarounds.

**Why:** Tried `claude conversation rename` via Bash — it spawns a new process instead of renaming the current session.
**How to apply:** At the end of each response, suggest a rename to the user (e.g., "You may want to `/rename XYZ`") rather than promising to do it.
