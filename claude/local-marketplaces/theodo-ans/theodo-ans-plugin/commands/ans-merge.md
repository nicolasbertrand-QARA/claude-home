---
description: Re-merge déterministe d'overrides DP sur la gap analysis sans rejouer le LLM (Mode C "Re-merge"). LLM-assisted fallback si delta verdict > 1 cran.
argument-hint: <client-slug>
applies_rules: [disagreement]
requires_tier_at_least: T3
retry_policy: transient_only
criticality: blocking
failure_blocks: []
---

# /ans-merge {{ args }}

Tu appliques les overrides DP capturés dans `intake/project-brief.json` (`verdict_overrides[]` + `dp_decisions.jalon_2.disagreement_overrides[]` + `dp_decisions.jalon_2.a_confirmer_actions[]`) à la gap analysis existante, **sans rejouer la construction LLM complète**.

Cette commande remplace `apply_merge_v5.py` (script ad-hoc Sunrise) par une étape officielle reproductible.

## Charges immédiates

```
skills/ANS/references/rules/disagreement.md
skills/ANS/references/verdict_taxonomy.md          (severity scale)
skills/ANS/references/sub_decision_impact.json
intake/project-brief.json                          (overrides à appliquer)
analysis/assessments.final.json                    (gap actuelle, point d'entrée)
analysis/merge-trace.json                          (history per-exigence)
```

## Étape 0 — Lock + state check

```bash
LOCK=~/missions/{{ args }}/.lock
test -f "$LOCK" && { echo "[LOCKED]"; exit 2; }
echo "$$ $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$LOCK"
trap "rm -f $LOCK" EXIT
```

État machine attendu : `jalon-2-pending` ou `jalon-2-stale` ou `jalon-2-signed`. Refuser si `running` (un autre run est actif).

## Étape 1 — Lecture des overrides

```bash
BRIEF=~/missions/{{ args }}/intake/project-brief.json
VERDICT_OVERRIDES=$(jq '.verdict_overrides // []' "$BRIEF")
DISAGREEMENT_OVERRIDES=$(jq '.dp_decisions.jalon_2.disagreement_overrides // []' "$BRIEF")
A_CONFIRMER_ACTIONS=$(jq '.dp_decisions.jalon_2.a_confirmer_actions // []' "$BRIEF")
```

## Étape 2 — Classification deterministic vs LLM-assisted

Pour chaque override, calcule le delta de severity (cf. `verdict_taxonomy.md` numeric scale) :

- `simple` : `abs(severity_current - severity_override) ≤ 1` → traitement Python pur (étape 3)
- `narrative_regen_needed` : `abs(severity_current - severity_override) ≥ 2` → marque pour LLM (étape 4)

## Étape 3 — Apply simple overrides (déterministe Python)

Pour chaque override `simple` :
- Update `assessments.final.json` : statut = override.override_to ; ecart prepended `[DP override Jalon 2 §X]` ; rationale_override appended
- Update `merge-trace.json` : append entry to `history[]`

Pour `a_confirmer_actions` :
- `demander_client` : tag `axis` + `recipient` selon `axis` provisioned ; ne change pas le statut (reste À confirmer) ; append à `intake/docs-tracking.md` (tableau : item + action + date demande + statut)
- `lancer_probe` : génère placeholder `probes/specs-pending/<exigence-id>.spec.ts` à coder
- `override` : update statut comme verdict_override
- `laisser_ouvert` : tag `accepted_unresolved` + rationale_unresolved obligatoire

## Étape 4 — Apply narrative-regen overrides (LLM-assisted)

Pour chaque override `narrative_regen_needed` :
- Lance un mini-LLM call (single-turn) : "DP a override l'exigence X de [V1 verdict] vers [override_to]. Génère un nouveau triplet (evidence, ecart, recommandation) cohérent, en citant les sources primaires existantes + la nouvelle clause opposable si applicable."
- Update assessments.final.json + merge-trace.json
- Coût attendu : ~$0.10-0.50 par override narrative (faible)

Si aucun override narrative_regen → step skipped (run reste 100% déterministe).

## Étape 5 — Re-génère gap-analysis.xlsx

À partir de `assessments.final.json` mis à jour, regénère le XLSX avec colonnes nominales + colonne « Override DP Jalon 2 » (oui/non) + colonne « Cluster ID » (si applicable).

## Étape 6 — Update merge-trace.json

Schéma (par exigence) :

```json
{
  "exigence_id": "INS 17.1",
  "history": [
    {"version": "v1-build", "verdict": "Conforme à étayer", "source": "build", "rationale": "..."},
    {"version": "v2-self-review", "verdict": "Non applicable", "source": "self-review", "rationale": "..."},
    {"version": "v3-merge-jalon-2", "verdict": "Non applicable", "source": "dp-override", "rationale": "DP confirme V6", "signed_by": "Nicolas Bertrand", "signed_at": "..."}
  ],
  "current": "Non applicable"
}
```

## Étape 7 — Stale-tracking

Si la signature jalon-2 existe (`dp_decisions.jalon_2.validation` non vide), et qu'un nouveau verdict_override a été appliqué après la dernière signature → marquer la signature comme stale (state machine transition `jalon-2-signed → jalon-2-stale`).

## Étape 8 — Output PM

```
Re-merge {{ args }} appliqué.

Overrides traités : {N_simple} simple (Python) + {N_narrative} narrative-regen (LLM).
Coût LLM : ${cost}.
Snapshot : analysis/assessments.v3-merge-jalon-2.json (write) + analysis/assessments.final.json (current).

Stale check : {jalon-2-stale | OK}.

Re-génère le brief jalon 2 si signature à régulariser.
```

## Discipline

- **Jamais d'override sans rationale** : schema Project Brief le rejette (`rationale: minLength 10`).
- **Append-only** : `merge-trace.json` ne réécrit jamais l'historique, accumule.
- **Lockfile** : sortir avec exit 2 si autre process actif.
- **Coût LLM** : si > $5 sur un seul re-merge, alerter PM (probablement bug — trop de overrides narrative ou prompt inflé).
