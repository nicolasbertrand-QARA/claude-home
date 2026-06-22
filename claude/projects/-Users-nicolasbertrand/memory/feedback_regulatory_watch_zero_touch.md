---
name: feedback-regulatory-watch-zero-touch
description: Regulatory watch newsletter is automated. NEVER ask confirmation before sending. NEVER discuss recipients/subject. Auto-recover from auth failures and send silently. Zero interactions tolerated.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bca43b77-da04-4128-b694-842354a91b29
---

The weekly regulatory watch (Friday 08:00 CEST) is a fully automated newsletter. Recipients, subject, and content are stable. The user wants ZERO interactions to receive it.

**Why:** It used to work perfectly. The user got frustrated when send was blocked on GWS reauth, then I made it worse by asking "want me to send it?" before firing send.py. Recipients are already on every prior Friday's send. Asking is friction, not safety.

**How to apply:**
- If send.py is built and ready, fire it immediately. Never ask.
- If GWS auth expired: try to remediate (re-run auth check, surface a single OS notification with one-click action), then send as soon as auth restored. Do NOT ask the user to confirm sending; just send.
- Never propose dry-runs, never quote recipients, never offer to "open the HTML for a final read-through". The user reviews in his own inbox.
- Apply the same zero-touch principle to any other recurring automated artefact the user owns (stockpulse newsletter, qms-relancer, etc.) unless explicitly told otherwise.
