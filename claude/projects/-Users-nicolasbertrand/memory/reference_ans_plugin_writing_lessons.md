---
name: ANS plugin — audit prose vs client prose
description: Lesson from Sunrise 2026-05-11 — the theodo-ans plugin must separate audit-internal text (ecart, citations, triangulation) from client-facing prose (obs_fr, reco_client). Edgar's critique on Sunrise INS column V is the canonical dictionary of what to ban from client fields.
type: reference
originSessionId: 778e6c28-c0af-40ff-8349-6a7c9b76798b
---
# Architectural rule for the theodo-ans-gap-analysis plugin

The plugin produces TWO distinct kinds of prose that must never share the same field:

## Audit trace (internal JSON, never to client)
- `ecart`, `evidence`, `sources_client[]`, `sources_opposables[]`, `confirm_reason`, `audit_note`, `evidence_attempted`
- Audience: NB assessor, internal Theodo audit
- Voice: defensive, citation-heavy
- Allowed terms: triangulation, silence coordonné, evidence-backed, sub_decision_impact, voie_b, Lot N

## Client deliverable (xlsx cols U/W, HTML pre-kit)
- `obs_fr` (col U "Pourquoi") and `reco_client` (col W "Reco Theodo HealthTech")
- Audience: client RAQ + product/dev team
- Voice: 2nd person, declarative, specific
- Banned terms (deterministic regex, fail-build): V1/V2, Lot N, self-review, rationale, triangulation, silence coordon, evidence-backed, sub_decision, dp_override, audit_note, voie_a/voie_b, mass-update, /ans-, agent, plugin theodo, étape N, Triple gate, P0/P1/P2, SRS, SOP, RAQ, DP (sauf entre parenthèses pour expliciter), §, ∉/∈/∀/∃, "L'agent a", "Le scénario teste", "cite à tort", "piochée"

## Reference exemplars for client prose
- Okeiro (sheet 10hez1I1TDviM1mVZ6HFSQbE3nJ4JipCBQa2SN4N67D4) and LibreView (1S827AH_83YNXgct30i7o8pBob8gGTpMm6QvcoQ2Q-vM) — used as the gold style.
- House style observed: direct 2nd-person ("Vous devez ajouter…"), specific list of fields/elements, "Same as above" / "Idem INS X.Y" for sibling scenarios, Whimsical mockup link when applicable, Q&A column for genuinely-open questions to client.

## Edgar's critique on Sunrise INS column V (2026-05-11)
Canonical reference. Spreadsheet 1VIzbjM3dXPLHQVkHqPTp4lcpf2cjgvasPRkgYi_RmNQ, column V. Each comment = one banned pattern. Use as a regression fixture if the plugin is rebuilt.

## Why this matters
Lots 13/17/24/26 fixed verdict accuracy but accumulated defensive vocabulary in the prose. The xlsx writer copies `ecart` → col U 1:1, with no rendering step. That single architectural gap is the root cause of "subpar output" feedback (Sunrise 2026-05-11).

## When the plugin is rebuilt
Two-phase build:
- Phase A — audit assessment (current): produces JSON audit fields
- Phase B — render for client (new): LLM call per assessment with fewshots from writing_pack/, outputs obs_fr + reco_client
- Hard lint between A and B with the banned regex above
- New sub-agent ans-prose-reviewer critiques writing (vague verb, copy-paste, missing field name, Cas 1/2 unaddressed, Theodo-ops bleeding into reco)
- Theodo internal ops (P0 PM probe, demander RAQ doc, peupler base testing) → briefs-revue/, never xlsx

## Status
- 2026-05-11: Plan validated. R1+R2+R3 implemented in plugin (commit 523665c). git baseline 6966755.
- Sunrise rebuild (using V0.5 plugin) pending validation.
