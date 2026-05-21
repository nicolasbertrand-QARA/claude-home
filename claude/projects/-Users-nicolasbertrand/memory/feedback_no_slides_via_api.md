---
name: Don't generate Google Slides programmatically via API
description: Slides API can replace text but produces poor visual results — propose HTML/PDF or manual build instead
type: feedback
originSessionId: d6884259-cad2-4ff6-be3d-a04d7d8de358
---
Don't try to generate or rework Google Slides decks programmatically via the Slides API (`gws slides batchUpdate`, replaceAllText, deleteText/insertText). The API only manipulates content within existing placeholder shapes — it can't resize boxes, reflow layouts, or adapt visual rhythm to new content. Result: text overflows, alignment breaks, and the deck looks worse than what could be produced manually in 1-2h from the master template.

**Why:** User reviewed an attempted Sunrise mission deck (15 slides built by copying a Resmed kickoff template and replacing text via API) and rejected it with "you can't do slides." Layouts inherited from the source were sized for the source's specific content and didn't accommodate the new copy.

**How to apply:** When the user wants a slide deliverable, do NOT default to programmatic Slides generation. Instead:
- Produce a polished HTML page (impeccable skill) and offer PDF export — this is the strongest visual deliverable I can produce.
- Provide structured content (storyline, slide-by-slide bullets, copy) for a human to assemble manually in Slides from a master template — explicitly call this out as the path with the best visual result.
- Only use the Slides API for narrow, surgical edits to existing decks (a few text replacements that don't disturb layout), never for building or restructuring a deck.
