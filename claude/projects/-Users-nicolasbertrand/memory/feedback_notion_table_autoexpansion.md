---
name: Notion auto-expands tables; surgical edits need a fetch first
description: Notion stores `<table>`/`<tr>`/`<td>` blocks with each cell on its own line, even if the create call sent them inline. Surgical update_content with the original inline form silently no-ops. Always fetch first to get the stored format, or use replace_content for big changes.
type: feedback
originSessionId: f89056ae-539b-4c13-98f4-0c0fff6d60e0
---
When sending Notion-flavored markdown via `notion-create-pages` or `notion-update-page` with one-line table rows like `<tr><td>a</td><td>b</td></tr>`, Notion stores them expanded:

```
<tr>
<td>a</td>
<td>b</td>
</tr>
```

**Why:** A surgical `update_content` whose `old_str` matches the inline form will return success but match zero occurrences (silent no-op). I burned a turn deleting a Role C table this way — the edit "succeeded" but the section was unchanged.

**How to apply:**
- Before any surgical `update_content` that touches a `<table>` block, fetch the page first via `notion-fetch` and copy the actual stored format into `old_str`.
- For deleting or replacing whole sections that contain tables, prefer `replace_content` with the full new page body.
- Same caveat likely applies to other block types Notion may auto-expand (toggles, callouts with multiple children, columns).
- Verify table-touching updates by re-fetching, since the API doesn't report match count.
