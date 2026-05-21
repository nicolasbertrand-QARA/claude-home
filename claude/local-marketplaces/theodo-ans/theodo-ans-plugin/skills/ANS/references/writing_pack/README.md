# Writing pack — exemplars for Phase B (render-for-client)

Cette ressource alimente l'étape de rendu client de `/ans-build`. Elle existe pour casser le mode d'échec Sunrise 2026-05-11 : la prose d'audit (citations, triangulation, vocabulaire plugin) fuyait dans les colonnes lues par le client.

## Contenu

| Fichier | Rôle |
|---|---|
| `anchors.json` | 10 exemplaires hand-authored qui pré-splittent l'observation (`obs_fr`) et la recommandation (`reco_client`). C'est la **source d'autorité du format**. Utilisés en fewshot dans tous les rendus client. |
| `exemplars.json` | 137 exemplaires bruts extraits d'Okeiro + LibreView (verdicts validés en mission, prose validée client). La colonne `gold_reco_unified` contient la prose finale telle qu'elle a été rendue au client. Pool de référence par section. |
| `anchors.json` → `anti_anchors[]` | Exemples explicites de ce qu'**il ne faut pas produire**, sourcés du retour Edgar sur Sunrise. Utilisés en negative fewshot. |
| `_raw/` | Dumps JSON bruts des deux Google Sheets sources + script `extract.py` pour régénérer `exemplars.json`. |

## Voix attendue (à appliquer sans exception)

- **Audience** : RAQ et équipe produit du client. Pas l'évaluateur ANS, pas l'auditeur interne Theodo.
- **2e personne** : « Vous devez ajouter… », « Sur chaque vue… », « Nous aurions besoin de voir… »
- **`obs_fr`** (col 21 « Pourquoi conforme/non conforme ») : 1–2 phrases. Constat factuel et **spécifique au produit** (champ X, écran Y, parcours Z). Pas de défense de verdict, pas de citation de source.
- **`reco_client`** (col 22 « Reco Theodo HealthTech ») : impératif, dev-spec. Liste de bullets quand plusieurs éléments sont à ajouter. Cite explicitement la preuve à produire pour Convergence quand pertinent (« Capture vidéo à produire pour INS X.Y.1 »).

## Sources des exemplaires

- **Okeiro** — `https://docs.google.com/spreadsheets/d/10hez1I1TDviM1mVZ6HFSQbE3nJ4JipCBQa2SN4N67D4` — gap analysis client, prose mature (Done ✅).
- **LibreView** — `https://docs.google.com/spreadsheets/d/1S827AH_83YNXgct30i7o8pBob8gGTpMm6QvcoQ2Q-vM` — gap analysis client, FR + EN parallèles (on n'extrait que les rangs FR).

Toute autre source de fewshot (futurs clients) sera ajoutée ici uniquement après revue de la prose par un consultant senior.

## Régénération

```bash
cd skills/ANS/references/writing_pack/_raw/
gws sheets spreadsheets values get --params '{...}' --format json > okeiro_full.json
gws sheets spreadsheets values get --params '{...}' --format json > libreview_full.json
python3 extract.py
```

## Note sur la séparation `obs_fr` / `reco_client`

Okeiro et LibreView ne disposent que d'une seule colonne « Recommandation Theodo » qui mélange constat et action. Le référentiel ANS Convergence v1.2.2 expose en revanche deux colonnes officielles distinctes :

- Col 21 « Pourquoi conforme/non conforme ? » → notre `obs_fr`
- Col 22 « Reco Theodo HealthTech » → notre `reco_client`

Les `anchors.json` montrent comment partitionner la prose unifiée Okeiro/LibreView en deux champs distincts.
