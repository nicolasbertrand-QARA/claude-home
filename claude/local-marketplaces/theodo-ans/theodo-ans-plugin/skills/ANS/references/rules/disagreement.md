# Rule — Disagreement Resolution (V0.4 / Lot 9 — simplifiée)

**Applies to**: `/ans-build` merge step, `/ans-self-review`, `/ans-merge`.

## Règle (V0.4 Lot 24 — l'evidence-backed gagne)

Quand V1 (build) et self-review divergent sur le verdict d'une exigence,
appliquer dans l'ordre :

1. **DP override existant** (`dp_decisions.jalon_2.disagreement_overrides[]`)
   → applique le verdict signé + rationale du DP.

2. **Un seul des deux est evidence-backed strict** — l'un des verdicts
   (V1 OU SR, peu importe) est `Non conforme`, `Conforme à étayer`,
   `Partiel` ou `Conforme` AVEC :
   - `sources_client[]` ou citations de triangulation (silence coordonné
     UI + doc, capture probe, doc citée précise),
   - ET l'autre verdict est `À confirmer` (par définition non-engagé) ou
     repose sur « je suis pas sûr / 3rd source pending / préfère prudent »
     SANS contre-evidence,
   → **Garde le verdict evidence-backed**, peu importe qui le porte.
   Annoter le caveat de l'autre dans `ecart`.

   Cas typiques :
   - V1 = NC evidence-backed + SR = ÀC prudent → garde **NC** (V1 wins)
   - V1 = ÀC prudent + SR = NC evidence-backed → garde **NC** (SR wins)
   - V1 = ÀC ("mobile_pending") + SR = NC (« HCP UI insMarkers all false +
     PRO-460 silent ») → garde **NC** (SR a triangulé, V1 punté).

3. **Les deux sont evidence-backed et factuels divergent** — V1 cite
   sources_client A, SR cite sources_client B, les deux ont raison
   localement mais arrivent à des verdicts différents :
   → reclasse en `À confirmer` avec
   `confirm_reason = "dp_override_pending"`. Le DP arbitre en jalon 2.

4. **Aucun n'est evidence-backed** — V1 et SR sont tous deux ÀC ou
   sortent un verdict sans citation primaire :
   → conformément à `rules/absence-as-nc.md`, l'agent N'AURAIT PAS DÛ
   verdicter. Re-trigger étape 5 de `/ans-build` pour ce scénario avec
   lecture re-renforcée. À défaut, garder ÀC + `confirm_reason` adapté.

## Objectif

Éviter deux failure modes symétriques :

- **Failure mode A (Lot 13)** : SR sur-prudent qui downgrade un V1=NC
  evidence-backed en ÀC sous prétexte « je préfère prudent ». Couvert
  par règle 2 (V1 wins).
- **Failure mode B (Lot 24)** : V1 sur-prudent qui flag ÀC sur silence
  coordonné, SR vient triangulier et émet NC, le merge reclasse tout
  en ÀC dp_override_pending. Couvert par règle 2 (SR wins).

La règle 2 est symétrique : **le verdict engagé + evidence-backed gagne
sur le verdict prudent**. Le DP n'arbitre que les vrais désaccords
factuels (règle 3), qui restent rares.

Observé sur Sunrise 2026-05-11 (run #69/70) : 13 dp_override_pending
relèvent du failure mode B et auraient dû être NC. Lot 24 les corrige.

## Pourquoi cette simplification (V0.3 → V0.4)

V0.3 distinguait :
- **Soft** (delta sévérité ≤ 1, deux evidence-backed) → garde le strict
- **Hard** (delta ≥ 2) → reclasse `À confirmer`

Cette nuance demandait de calibrer une `severity_numeric` discutable
(cf. `verdict_taxonomy.md`). Le run Sunrise a montré que le PM/DP
préfère arbitrer chaque désaccord (~20 cas typiques) plutôt que
reposer sur une heuristique. Le coût : ~20 décisions DP en jalon-2.
Le gain : zéro verdict imposé par heuristique sans signature DP — modèle
audit-defensible sans ambiguïté.

## Comportement post-merge attendu

Après `/ans-build` (auto) ou `/ans-merge` (manuel), tout scénario où
V1 ≠ self-review est :

1. Soit `À confirmer` + `confirm_reason: dp_override_pending` (cas par défaut),
2. Soit le verdict signé par le DP (si override présent dans le brief).

Le brief de revue jalon 2 (`briefs-revue/jalon-2-gap-brute.md`) liste
tous les `dp_override_pending` triés par sévérité du V1 — c'est l'agenda
de la réunion DP.

## Note : accord conservé tel quel

Si V1 == SR (accord), le verdict reste tel quel (`[review:✓]`). Pas de
reclassement automatique en À confirmer dans ce cas — c'est seulement
le cas de divergence non résolue qui devient À confirmer.

## Reference

- Triple gate citations : cf. `epistemic_discipline.md` § Règle 4
- confirm_reason enum : cf. `verdict_taxonomy.md` § À confirmer
