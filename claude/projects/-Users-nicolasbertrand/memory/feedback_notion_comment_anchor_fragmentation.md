---
name: feedback_notion_comment_anchor_fragmentation
description: Notion update_content silently skips entries whose target text is fragmented by comment-anchor spans; it only errors when ZERO entries match.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e5250bfe-7132-4eb0-ba2e-51f329a4ed59
---

When editing a Notion page that has inline comments, the commented text is split into separate rich-text segments (shown in fetch as `<span discussion-urls="...">`). `notion-update-page` `update_content` matches WITHIN a single segment (substring ok), never ACROSS segment boundaries.

Consequences proven on the AI System Lifecycle standard (Jun 2026):
- A batch `update_content` call succeeds and returns `{page_id}` as long as at least ONE entry matches; entries that don't match are SILENTLY skipped. It only throws "No matches found" when ZERO entries match. So always re-fetch and verify after a batch.
- To edit commented text, match the un-fragmented sub-segment (e.g. the plain tail after the span), not the full logical line.
- Ambiguous matches throw "Multiple matches found" and refuse even with `replace_all_matches:false` (it does NOT take the first). Disambiguate by making the string unique or by removing the other occurrences first.
- There is NO comment-resolve action in the MCP/API. Replies are possible (`notion-create-comment` with `discussion_id`); resolving must be done by a human in the UI.

**Why:** Saves a long trial-and-error loop on every commented page edit.
**How to apply:** Fetch with discussions visible, edit sub-segments, re-fetch to confirm, and tell the user resolve is manual. Related: [[feedback_notion_table_autoexpansion]].
