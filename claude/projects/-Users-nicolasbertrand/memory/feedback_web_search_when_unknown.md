---
name: feedback-web-search-when-unknown
description: "When the user asks about something not in training data (product names, recent releases, model IDs, news, etc.), MUST run WebSearch/WebFetch rather than answering from memory or claiming it doesn't exist"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9a32b583-4ffc-41e0-8c31-d89f874fa29b
---

When information isn't in training data, search the web — do NOT answer from memory or assert the thing "isn't real / doesn't exist".

**Why:** User stated this explicitly as a final correction after I dismissed "Fable 5 model" as non-existent, when in fact Anthropic released Claude Fable 5 on 2026-06-09 (one day before the conversation). Asserting "X isn't an Anthropic model" without checking is a hard failure mode. Sibling memory: [[feedback_use_realtime_tools]].

**How to apply:**
- Triggers: unknown product/model names, version numbers, release dates, recent news, current pricing, anything time-sensitive, anything the user implies should exist.
- Action: WebSearch first, then answer. If WebSearch is unavailable, say so explicitly — don't fall back to training-data assertions of non-existence.
- Never say "X isn't a thing" / "that doesn't exist" / "I'm not aware of X" without having searched. Absence in training data ≠ absence in reality.
- Model knowledge cutoff (Jan 2026) is roughly 5 months stale as of 2026-06-10 — anything released in 2026 is likely missing.
