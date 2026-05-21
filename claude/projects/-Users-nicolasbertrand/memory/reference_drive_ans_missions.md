---
name: Drive parent pour missions ANS Theodo
description: Les missions ANS gap-analysis sont stockées dans le Shared Drive "Hokla" > "Projets" > "<client>", pas dans My Drive
type: reference
originSessionId: 65bfc3f7-a29c-4f75-8829-0e693435a274
---
Les missions ANS gap-analysis menées par Theodo sont stockées dans :

- **Shared Drive** : `Hokla` (driveId `0AJPn_avg1HuNUk9PVA`)
- **Path** : `Projets/<client>/Mission ANS — Gap analysis/`
- **Folder ID `Projets`** : `1quIo8NzH5COmnEUrAiTCt4mt8nVfshxQ`

Exemple Sunrise (2026-05-07) :
- Folder client `Sunrise` : `1XPkhcLbzuXT3TvLU899ZFHxVBApfQB52`
- Folder mission : `1EdwLFhvif6hoi7fX2Q6Im-RIe4-PYN50` — https://drive.google.com/drive/folders/1EdwLFhvif6hoi7fX2Q6Im-RIe4-PYN50

## Conséquences pour les commandes

- Toujours créer/lire avec `supportsAllDrives:true` et `includeItemsFromAllDrives:true`.
- Le Drive API **ne permet PAS de déplacer un folder** depuis My Drive vers un Shared Drive (`teamDrivesFolderMoveInNotSupported`). Si le init s'est trompé de parent, il faut **recréer la structure dans le Shared Drive** puis **déplacer les fichiers** (pas les folders) un à un, puis trasher l'ancien folder racine.
- Le slash command `/ans-init` (plugin v0.2) référence dans son texte un parent `Theodo - QARA Missions/` qui n'existe pas dans le tenant Theodo. Le vrai parent est `Hokla > Projets > <client>`. Demander confirmation au PM avant de créer ailleurs.

## Spec plugin v0.2 — artefacts en Google Docs natifs

Le plugin v0.2 produit des **Google Docs natifs** sur Drive.

### ⚠ Bug `ans-publish.md` — la conversion HTML→gdoc DÉTRUIT la charte

Contrairement à ce que prétend `ans-publish.md` step 4 (« Pertes attendues à la conversion (non-bloquantes V0.1) »), la conversion HTML→gdoc côté Drive API **stripe la totalité du `<style>` block et les `style="..."` inlines**. Test confirmé sur Sunrise (2026-05-07) : background blanc, texte noir, aucune classe `.head` `.tbl` `.callout` survit. Tout part à la poubelle.

### Solution — passer par DOCX (pandoc + reference docx charte)

1. Générer le contenu en markdown local (`~/missions/<client>/...`).
2. Convertir en `.docx` via pandoc avec un reference docx charte-stylé : `pandoc -f gfm -t docx --reference-doc=<charte-ref.docx> <md> -o <docx>`.
3. Upload du DOCX en `mimeType=application/vnd.google-apps.document` → Google Docs préserve les styles DOCX (couleurs, polices Manrope/Public Sans/JetBrains Mono, table borders, paragraph borders, shading).
4. Pour mettre à jour : `gws drive files update --params '{"fileId":"...","supportsAllDrives":true}' --json '{}' --upload <docx> --upload-content-type=application/vnd.openxmlformats-officedocument.wordprocessingml.document`.

### Reference docx Theodo HealthTech

Sauvegardée dans le plugin cache :
- `templates/charte/theodo-charte-reference.docx` — pandoc reference avec styles charte (Title/Heading1-4 navy + Manrope, Normal Public Sans, VerbatimChar JetBrains Mono navy, BlockText callout yellow-deep border)
- `templates/charte/build_ref_docx.py` — script Python pour régénérer le reference depuis le default pandoc

Ce qui survit après upload comme gdoc :
- ✓ Couleurs hex (navy `#1B2A4E`, navy-soft `#3D4870`, yellow-deep `#B68C25`, ink-body `#3A4055`)
- ✓ Polices Manrope (display), Public Sans (body), JetBrains Mono (code) — Google Fonts natives
- ✓ Tables avec borders + headers
- ✓ Bold/italic, paragraph borders, cell shading

### TODO plugin v0.3 — Option B Docs API batchUpdate

Le DOCX route est plus fidèle que HTML mais reste une fidélité « Word default + couleurs ». Pour atteindre le rendu pixel-perfect du HTML charte (header navy bandeau, callouts décorés, sec-title avec numéro yellow), implémenter une couche `documents.batchUpdate` qui applique post-upload des styles natifs Google Docs (updateTextStyle, updateParagraphStyle, updateTableCellStyle, namedStyles). À prioriser pour livrables clients (executive-summary, roadmap), pas indispensable pour artefacts intake.
