# Rule — Absence as Non Conforme (V0.4 Lot 13 — réécriture)

**Applies to**: `/ans-build`, `/ans-self-review`.

## Principe (non négociable)

**Le principe MÊME de la gap analysis est : si tu ne trouves pas
l'élément après une revue suffisante, c'est `Non conforme`.**

Pas `À confirmer`. La charge de la preuve est sur le manufacturer (cf.
art. R.5212-1 CSP + DMN V1.2.2 § Convergence). Une absence coordonnée
constatée IS une preuve de NC.

## Définition opérationnelle de « revue suffisante »

Une exigence est en « revue suffisante » dès que TOUTES les sources
**applicables au scope déclaré dans `intake.probe_scope[]` + profils
DMN du brief** ont été consultées, ET que l'élément exigé y est absent.

Sources applicables (selon le scope) :
- **UI Web HCP** — si la probe Playwright a couvert l'exigence
- **UI mobile** — si un capture protocol a été reçu, OU si le scope
  déclare cette exigence « mobile_only » et un protocol existe
- **Documentation** — `docs/` indexé par `ans-doc-reader`

→ Si un élément est absent de **toutes les sources applicables au scope**,
le verdict EST `Non conforme`. Cite chaque silence en
`sources_client[]` (ex. `"PRO-460 V20 §5.1.2 silence sur INS qualifié"`,
`"Probe 4 — DOM signup HCP, pas de champ RPPS"`).

## Quand `À confirmer` reste légitime

UNIQUEMENT quand l'agent est physiquement incapable de constater :

- **Probe non couvrante** : pas de spec Playwright pour ce scénario
  ET le scénario a été **explicitement déclaré comme `mobile_pending`**
  dans `intake.probe_scope[]` ou `dp_decisions.jalon_2.a_confirmer_actions[]`.
- **Doc requise non fournie** : le client a déclaré une doc (ex. SOP
  identitovigilance) dans `intake.docs_expected[]` ou `tech.docs_received[]`
  mais elle n'a pas été uploadée — le silence n'est pas constaté, il est
  **non investigué**.
- **Scope produit ambigu** : le brief lui-même ne tranche pas si l'exigence
  s'applique à ce profil DMN — escalader DP avant de verdicter.

Dans tous ces cas, `confirm_reason` est obligatoire (cf. `epistemic_discipline.md`
Règle 4) et **doit citer la source manquante**, pas un silence générique.

## Anti-pattern à bannir : « pas trouvé donc À confirmer »

```python
# INTERDIT V0.4 Lot 13 :
Assessment(
    statut="À confirmer",
    confirm_reason="no_evidence_in_provided_docs",
    methode="Probe UI authentifiée + Doc",
    ecart="Pas mentionné dans REP-351 ni dans la probe HCP",
)
# → Si tu as VRAIMENT cherché dans le doc + probé l'UI et que c'est absent,
#   le verdict EST Non conforme. La preuve d'absence est l'absence elle-même.
```

```python
# CORRECT V0.4 Lot 13 :
Assessment(
    statut="Non conforme",
    sources_client=[
        ("PRO-460 V20", "§5.1.2 — silence total sur référentiel INS qualifié"),
        ("Probe HCP /signup", "DOM dump — aucun champ matricule INS"),
    ],
    sources_opposables=["Guide INS V3.0 EXI ID 14"],
    ecart="Aucune mention du champ matricule INS dans SRS-SSP-014, et la probe HCP confirme l'absence du champ dans l'UI authentifiée. Triangulation = preuve d'absence.",
    severity_numeric=5,
)
```

## Cas spécifiques voie INS

Si `dp_decisions.jalon_1.voie_ins.decision == "voie_b"` (Esclave
d'identité), les exigences de **création/modification** d'identité
côté HCP sont :

- **N/A par défaut** (cf. `sub_decision_impact.json`) — le HCP NE crée
  PAS, il consomme un flux. Le verdict est `Non applicable` avec
  `audit_note ≥ 10 chars` justifiant.
- **NC SI** la mission a `audit_other_voie = true` ET
  `audit_outcome_for_other = "mark_nc_strict"` — auquel cas l'absence
  côté HCP est NC (pour la voie A potentielle).
- **N/A avec audit_note** SI `audit_other_voie = true` ET
  `audit_outcome_for_other = "mark_na_with_audit_notes"` — l'audit_note
  doit citer ce qui manquerait pour passer en voie A.

Dans aucun de ces cas le verdict n'est `À confirmer`. La voie est
tranchée → le statut découle.

## Triangulation : check minimum avant tout NC

Avant d'émettre `Non conforme` sur silence, l'agent doit avoir cité :

- ≥ 1 source primaire client (cf. Règle 1) attestant le silence
  (ex. doc PRO-460 lue page X-Y, mention zéro)
- ≥ 1 référence opposable précisant ce qui était attendu
  (Guide INS, RNIV, EXI ID, PGSSI-S…)

Sans ces deux citations, c'est un `À confirmer` paresseux — relire
les sources avant de verdicter.

## Pratique : comment le PM/DP révise un NC contesté

Si un NC paraît injustifié au DP, l'override DP via
`dp_decisions.jalon_2.disagreement_overrides[]` reclasse explicitement.
La trace `ecart` du NC d'origine reste dans `merge-trace.json` pour
audit.

---

*V0.3 → V0.4 Lot 13 : règle réécrite après run Sunrise 2026-05-09 où
30 ÀC trompeurs sortaient sur silence coordonné — le bon verdict était
NC. Cf. epistemic_discipline.md Règle 2 mise à jour.*
