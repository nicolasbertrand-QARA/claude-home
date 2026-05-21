---
name: Always use gws CLI for Google services
description: NEVER use MCP Google Drive, WebFetch, or any other tool for Google Docs/Drive/Gmail/Sheets/Slides/Calendar. ALWAYS use the gws CLI command.
type: feedback
---

When accessing ANY Google service (Google Drive, Google Docs, Google Sheets, Google Slides, Gmail, Google Calendar, etc.), ALWAYS use the `gws` CLI command. Never try alternatives first.

**Why:** The user has repeatedly corrected this. MCP Google Drive authentication, WebFetch on Google URLs, and other workarounds waste time and frustrate the user. The `gws` CLI is already authenticated and works immediately.

**How to apply:**
- Google Docs: `gws docs documents get --params '{"documentId": "..."}'`
- Google Drive download: `gws drive files get --params '{"fileId": "...", "alt": "media"}' --output <path>`
- Google Drive list: `gws drive files list --params '{"q": "..."}'`
- Google Sheets: `gws sheets spreadsheets get --params '{"spreadsheetId": "..."}'`
- Gmail: `gws gmail users messages list --params '{"userId": "me"}'`
- Do NOT attempt `mcp__claude_ai_Google_Drive__authenticate` or any MCP Google tool
- Do NOT attempt `WebFetch` on Google URLs
- Do NOT attempt `gcloud` (different tool entirely)
- Go straight to `gws` on the FIRST attempt, no detours
