---
description: Kickoff d'une nouvelle mission ANS — crée le folder Drive standard, prépare l'intake visio, génère la lettre de demande de docs.
argument-hint: <client-slug>
applies_rules: []
requires_tier_at_least: T1
retry_policy: transient_only
criticality: skippable
failure_blocks: []
---

# /ans-init {{ args }}

Tu démarres une nouvelle mission ANS gap-analysis pour le client **{{ args }}**. Cette commande prépare le terrain pour la visio d'intake (jalon 1) qui aura lieu sous 5j.

## Charges immédiates

```
skills/ANS/SKILL.md
skills/ANS/references/mission_workflow.md
skills/ANS/references/intake_questionnaire.md
skills/ANS/references/document_request_catalog.md
skills/ANS/references/epistemic_discipline.md
skills/ANS/references/verdict_taxonomy.md
skills/ANS/references/run_state_machine.md
schemas/project-brief.v1.json
```

## Étape 0 — Mission existante ?

**Avant tout** : vérifier si la mission `{{ args }}` existe déjà.

```bash
test -f ~/missions/{{ args }}/intake/project-brief.json && BRIEF_EXISTS=1 || BRIEF_EXISTS=0
test -d ~/missions/{{ args }} && LOCAL_EXISTS=1 || LOCAL_EXISTS=0
gws drive files list --params '{"q":"name=\"Mission ANS — {{ args }}\" or name=\"{{ args }}\"","fields":"files(id,name)","supportsAllDrives":true,"includeItemsFromAllDrives":true}' && DRIVE_EXISTS_via_listing
```

Si `BRIEF_EXISTS=1` OU local OU Drive trouvé → afficher au PM un diff 3-colonnes (SQLite UI / local FS / Drive) et demander :
- **Reprise** : continuer avec l'état existant (skip création).
- **Recreate** : confirmer l'effacement explicit (DANGEREUX — alerter audit trail conservé en archive).

## Étape 1 — Project Brief Tier 1 (8 champs essentials)

Si la mission est nouvelle, le PM a (ou aurait dû) renseigner via la console UI les 8 champs T1. Ils sont fournis dans le contexte de cette commande sous forme de liste numérotée. Persiste-les directement dans `intake/project-brief.json` au format schema v1 — pas de question supplémentaire (mode non-interactif).

Si un champ est manquant → marque `(non renseigné — À confirmer en visio)` dans le brief, mais NE BLOQUE PAS l'init.

Schéma cible (extrait T1) :

```json
{
  "schema_version": "v1",
  "tier": "T1",
  "mission": {
    "client": { "raison_sociale": "...", "nom_court": "{{ args }}", "domaine": "..." },
    "pm": { "nom": "...", "email": "..." },
    "dp": { "nom": "...", "email": "..." },
    "raq_client": { "email": "..." },
    "dpo_client": { "email": "...", "same_as_raq": false },
    "dates": { "kickoff": "...", "visio_intake": "...", "cible_convergence": "..." },
    "dmn_version": "1.2.2"
  },
  "product": { "ml_ai": { "present": false } },
  "watchouts": [],
  "contractuel": { "nda_signed": false, "dpa_art28_signed": false }
}
```

Aussi écrire `intake/kickoff-info.md` (rendu humain pour PM/DP) à partir des mêmes données.

## Étape 2 — Créer la structure Drive Theodo

Via gws CLI, crée le folder `Hokla > Projets > {{ args }} > Mission ANS — {{ args }}/` avec sous-folders standard :

```
{{ args }}/
├── intake/
│   ├── project-brief.json          ← canonical (V0.3)
│   ├── project-brief.html          ← rendu charte Theodo (regénéré sur édition)
│   ├── kickoff-info.md             ← human-readable copy
│   ├── fiche-projet.html           ← à remplir pendant la visio
│   ├── decisions.md                ← signatures DP aux 3 jalons (legacy human-readable, dérivé de project-brief.json)
│   ├── pathway-decision.md         ← human readable copy (dérivé)
│   ├── docs-tracking.md            ← tracking docs reçus (V0.3 : aussi dans UI tabular view)
│   └── document-request-letter.md  ← généré ici (étape 3)
├── docs/
├── access/
├── probes/
│   └── reports/artifacts/
├── analysis/                        ← assessments versionnés (v1-build, v2-self-review, vN-merge, final) + merge-trace.json
├── deliverables/
├── briefs-revue/
├── archive/                         ← intermediates pour audit (V0.3)
└── README.md
```

Si gws CLI échoue, créer en local sous `~/missions/{{ args }}/` et notifier le PM.

## Étape 3 — Générer la lettre de demande de docs

Lis `skills/ANS/references/document_request_catalog.md` et produis `intake/document-request-letter.md` avec :
- Vague 1 : tous les éléments P0 (HDS + INS + démarches ANS + RGPD/DPIA)
- Vague 2 : SRS/REP/SOPs documentation produit
- Vague 3 : clarifications + stratégie + captures UI

## Étape 4 — Préparer la visio d'intake

Génère `intake/visio-prep.md` avec :
- Le déroulé (cf. `intake_questionnaire.md`)
- Questions par section
- Checklist PM avant visio

## Étape 5 — Initialiser le 1Password vault

Note dans `access/README.md` :

```markdown
# Accès testing — {{ args }}

Vault 1Password : `Theodo-ANS/{{ args }}-testing`
À créer manuellement par le DP au kickoff.
PM aura accès en lecture une fois créé.

À demander RAQ client :
- Email + mdp HCP testing
- URL environnement testing
- Email + mdp patient testing (si applicable)

JAMAIS dans Drive ou emails. TOUJOURS dans 1Password.
```

## Étape 6 — État machine

Enregistre la transition `idle → idle` (mission init) dans `mission_state_transitions` (via SQLite UI ou jsonl CLI fallback).

## Étape 7 — Output au PM

Liste à faire pour le PM dans les 24h :
- [ ] Vérifier visio d'intake calendaire avec PM + DP + RAQ + DPO client
- [ ] Lire `intake/visio-prep.md` la veille
- [ ] Demander au DP de créer le vault 1Password partagé
- [ ] Personnaliser et envoyer `intake/document-request-letter.md` au client (post-visio)
- [ ] Inviter le client RAQ comme **reader** sur le folder Drive (post-visio)

## Discipline

Cette commande ne produit que de la préparation. Aucun verdict émis. Aucun jugement sur le client (qualification = jalon 1, pas avant). Si le PM demande à brûler les étapes, refuser.
