---
name: feedback-source-documents-not-derived
description: "Never use previously generated artifacts (grids, decks, reports) as source of truth for new deliverables; re-verify facts against primary source documents"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8b026b39-ee17-4943-a5ad-61a84b0cfcc5
---

When building a new deliverable, do NOT treat a previously generated artifact (audit grid xlsx, slide deck, gap analysis, summary) as the factual source, even if it was verified at creation time. User correction (2026-06-10, MDSAP training session): "N'utilise pas ta grille comme source de vérité, c'est déjà de la donnée transformée, va à la source."

**Why:** Derived artifacts accumulate silent transformation errors. Proven the same day: the June 3 MDSAP grid cited "AU P0004" for NC grading; the actual source documents are AU P0037 (procedure), AU G0019.4 (guidelines), AU F0019.2 (NGE form). Reusing the grid would have propagated the wrong reference into client-facing training.

**How to apply:** Use prior artifacts only as structure/navigation hints. Re-download or re-open the primary sources (official PDFs, standards in ~/Documents/Normes, regulator websites) and verify every fact: document numbers, revisions, clause references, task counts, timelines. If the primary source is unreachable (site down), use Wayback Machine or official mirrors (fda.gov), and say which copy was used. Related: [[feedback-ask-when-blocked]].
