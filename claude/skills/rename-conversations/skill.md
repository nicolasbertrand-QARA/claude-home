---
name: rename-conversations
description: Rename Claude Code conversations to descriptive 2-5 word titles. Use when the user asks to rename, retitle, or clean up conversation names.
---

Rename Claude Code conversations so their titles reflect the actual topic discussed.

## How conversation naming works

Claude Code stores conversations as JSONL files at:
```
~/.claude/projects/<project-slug>/<session-id>.jsonl
```

The default project for the home directory is:
```
~/.claude/projects/-Users-<username>/
```

Each JSONL file contains one JSON object per line. Entries have a `"type"` field. The relevant types are:
- `"user"` — user messages (contain `message.content` with the actual text)
- `"custom-title"` — sets the display name shown in `/resume` picker and terminal title

## How to rename a conversation

Append a line to the JSONL file with this exact format:
```json
{"type":"custom-title","customTitle":"My New Title","sessionId":"<session-uuid>"}
```

That's it. The last `custom-title` entry in the file wins — Claude Code reads it on next load.

## Step-by-step procedure

1. **List all conversation JSONL files** sorted by date. Extract from each file:
   - The session ID (filename without `.jsonl`)
   - The timestamp (from the first entry with a `"timestamp"` field)
   - The existing custom title if any (last `"custom-title"` entry)
   - The first few user text messages (entries with `"type":"user"`, look at `message.content` for `"type":"text"` sub-entries, skip system tags like `<local-command-caveat>` and `<command-name>`)

2. **Determine the topic** of each conversation from the user messages. Draft a 2-5 word title that captures what the conversation was actually about (e.g., "Vivoptim PIA Update", "Apilife Summative Plan", "Live Flight Map").

3. **Append the custom-title entry** to each JSONL file using a shell script with a helper function:
   ```bash
   add_title() {
     local id="$1" title="$2"
     local file="$BASE/$id.jsonl"
     [ -f "$file" ] && echo "{\"type\":\"custom-title\",\"customTitle\":\"$title\",\"sessionId\":\"$id\"}" >> "$file"
   }
   ```

4. **Skip** conversations that are empty (no user messages), already have a good title, or that the user asked to exclude.

## Tips

- Use `python3` one-liners or inline scripts to parse JSONL efficiently when extracting user messages.
- The `slug` field on user/assistant entries is the auto-generated random name (e.g., "jazzy-baking-graham") — it is NOT the display title.
- Other project directories (e.g., `-Users-<username>-Documents-Normes/`) may also contain conversations.
- To resume a specific conversation from the CLI: `claude -r <session-id>`
