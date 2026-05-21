---
name: Use local claude CLI, not Anthropic API
description: For user's personal automations that need Claude, prefer the local `claude` CLI over the Anthropic SDK/API
type: feedback
originSessionId: 780e16a3-7d69-463f-b464-3c55074f44e4
---
When building automations that call Claude, default to invoking the local `claude` CLI (`claude -p --model sonnet --system-prompt "..." "user prompt"`) rather than the `anthropic` Python SDK with `ANTHROPIC_API_KEY`.

**Why:** The user already pays for Claude Code (subscription). Calling the API on top would be paying twice. Local CLI uses the existing OAuth/keychain auth — no extra key to manage and no extra spend.

**How to apply:**
- For scripts/cron/menubar tools: `subprocess.run(["claude", "-p", "--model", "sonnet", "--system-prompt", system, prompt], capture_output=True, text=True)`
- Don't use `--bare` (forces API key auth, defeats the purpose).
- `--system-prompt` *replaces* the default; `--append-system-prompt` appends to it. Use replace when you want a clean focused prompt without the user's CLAUDE.md leaking in.
- Only fall back to the SDK if you genuinely need API-only features (batch, files API, prompt caching analytics, very high QPS).
- Skip installing the `anthropic` pip package unless needed.
