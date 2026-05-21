---
name: Artefacts intake ANS — gdoc plain par défaut
description: Pour les artefacts intake (/ans-init), upload via HTML simple — gdoc rendu Google Docs par défaut, pas de charte forcée
type: feedback
originSessionId: 65bfc3f7-a29c-4f75-8829-0e693435a274
---
Pour les **artefacts intake** d'une mission ANS (kickoff-info, fiche-projet, decisions, pathway-decision, docs-tracking, document-request-letter, visio-prep, access README, README mission), upload en **HTML simple** via `gws drive files update --upload <html> --upload-content-type=text/html` → conversion gdoc native.

**Ne PAS** :
- ✗ Construire un wrapper HTML charte avec `<style>` block (Drive strippe tout, rendu identique au plain mais débit gaspillé)
- ✗ Passer par DOCX avec reference docx charte (préserve les couleurs/polices mais Google Docs affiche les artefacts d'import Word — tables avec largeurs fixes, spacing weird, paragraph borders qui font "Word-y")

**Why** : testé sur Sunrise (2026-05-07) — le user a explicitement préféré le rendu Google Docs par défaut (`color:#000000`, fonts Arial fallback, tables propres) au rendu DOCX charte (Manrope/navy/yellow appliqué mais artefacts d'import). Le rendu plain est plus lisible côté collaboration équipe.

**How to apply** :
- `/ans-init` : pandoc `-f gfm -t html5` simple, upload tel quel.
- Pas de wrapper, pas de reference docx, pas de Docs API batchUpdate post-upload.
- La charte Theodo HealthTech reste pour les **livrables clients** (executive-summary, roadmap, etc.) où le visuel branding compte — produits via `/ans-deliverables` puis `/ans-publish`.

**Reference** : si une mission future veut quand même tester DOCX route :
- `~/.claude/plugins/cache/theodo-ans-local/theodo-ans-gap-analysis/0.2.0/templates/charte/theodo-charte-reference.docx` existe (script `build_ref_docx.py` à côté). Mais demander confirmation avant.
