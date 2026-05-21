---
description: Lance explicitement un self-review indépendant sur la gap analysis (utile en mode dégradé ou pour rejouer après modifications).
argument-hint: <client-slug>
applies_rules: [probe-evidence, absence-as-nc, disagreement]
requires_tier_at_least: T3
retry_policy: transient_only
criticality: blocking
failure_blocks: [ans-deliverables]
---

# /ans-self-review {{ args }}

Tu lances un self-review indépendant sur la gap analysis de {{ args }}. **Cette commande est normalement appelée automatiquement par `/ans-build`** ; n'utilise cette invocation explicite que si :
- Le PM a modifié manuellement `analysis/gap-analysis.xlsx` après `/ans-build`
- Le PM veut un 2e passage de critique avant la réunion jalon 2
- Une mise à jour du référentiel ANS justifie un re-passage

## Pré-requis

```
analysis/gap-analysis.xlsx           (existant)
intake/fiche-projet.md
docs/ (sources client, lecture)
skills/ANS/references/* (référentiel ANS)
```

## Étapes

### 1. Spawn ans-self-reviewer subagent

Spawn `ans-self-reviewer` (cf. agents/ans-self-reviewer.md) en mode indépendant :

```
Tu es ans-self-reviewer. Mission : {{ args }}.

Inputs :
- analysis/gap-analysis.xlsx (verdicts émis par un 1er passage)
- docs/ (sources client, lecture seule)
- skills/ANS/references/dmn_exigences_full.md
- skills/ANS/references/referentiel_identites_qualification.md
- skills/ANS/references/epistemic_discipline.md
- skills/ANS/references/verdict_taxonomy.md

Tu NE LIRAS PAS les colonnes "Preuve recueillie / Source" et "Écart identifié" et "Recommandation" du XLSX.
Tu n'as accès qu'à : Profil, n_scenario, énoncé du référentiel, Statut.

Pour chaque scénario, forme ton propre verdict en suivant epistemic_discipline.md règles 1+2.
Output : analysis/disagreements.md.

Format disagreements.md :

# Self-review désaccords — {{ args }} — <date>

## Synthèse
- Total scénarios examinés : 103
- Désaccords : N (X %)
  - Désaccords doux (NC ↔ Partiel, Partiel ↔ Conforme à étayer) : N
  - Désaccords radicaux (NC ↔ Conforme, Conforme ↔ N/A) : N
- Verdicts confirmés : N

## Désaccords radicaux (URGENT — escalade DP avant jalon 2)
[liste]

## Désaccords doux (à reclasser en À confirmer)
[liste]

## Verdicts cités sans citation suffisante (à corriger)
[liste]
```

### 2. Lire les disagreements

Lis `analysis/disagreements.md` produit par le subagent.

Identifie (V0.4 Lot 13 raffiné) :
- **V1 evidence-backed** (NC/Partiel/Conforme à étayer avec
  `sources_client[]` solides — silence coordonné UI+doc OU preuve
  concrète) : SR **respecte** V1. Ne PAS downgrader un NC bien fondé en
  ÀC sous prétexte « je préfère prudent / mobile_pending ». Le rôle
  SR est d'écarter les hallucinations, pas d'ajouter du doute.
- **V1 hallucinatoire** (citation fabriquée, boucle copier-coller,
  Conforme sans capture, NC non-triangulé) : SR challenge avec
  contre-evidence ; sinon flag pour re-trigger étape 5.
- **Désaccord factuel** (SR cite une evidence que V1 a manquée) :
  enregistré pour reclassement à l'étape 3.
- **Désaccords radicaux** (NC ↔ Conforme) → marquer URGENT dans
  `disagreements.md` pour priorisation jalon-2.
- **Verdicts confirmés** (V1 == SR) : pas d'action.

### 3. Mise à jour (V0.4 Lot 13 — précision sur Lot 9)

→ Voir `skills/ANS/references/rules/disagreement.md` (raffiné Lot 13).

Pour chaque désaccord :
1. **DP override existant** : applique le verdict signé.
2. **V1 evidence-backed + SR sans contre-evidence** : garde V1 (cas
   majoritaire — SR sur-prudent ne doit pas écraser un verdict solide).
3. **Désaccord factuel non résolu** : reclasse en `À confirmer` +
   `confirm_reason: dp_override_pending`.

Le but est d'éviter le pattern Sunrise 2026-05-09 : 30 ÀC sortis alors
que ~20 étaient des NC légitimes — SR avait downgradé sur
« mobile_pending » ou « prudence ».

Re-génère :
- `analysis/assessments.v2-self-review.json`
- `analysis/merge-trace.json` (append history par exigence)
- `analysis/gap-analysis.xlsx` (avec colonnes « Désaccord self-review », « Justification self-review »)

### 4. Output au PM

```
Self-review terminé pour {{ args }}.

Désaccords : N / 103 (X %)
- Doux : N (reclassés en À confirmer)
- Radicaux : N (URGENT — préviens le DP avant la réunion jalon 2)

XLSX mis à jour : analysis/gap-analysis.xlsx
Détail : analysis/disagreements.md

Si désaccords radicaux : envoie un message au DP avec les scénarios concernés et demande une mini-revue avant le jalon 2 officiel.
```

## Discipline

- Le subagent NE DOIT PAS lire le rationale du 1er passage (sinon il sera biaisé)
- Si le subagent dévie de cette règle (ex: lit la colonne « Évidence »), reset et relance
- Si self-review produit > 30 % de désaccords → quelque chose ne va pas dans le 1er passage, escalade DP en urgence (signal de bug systémique)
