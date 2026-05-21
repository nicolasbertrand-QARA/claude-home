# Taxonomie des verdicts — theodo-ans-gap-analysis

6 statuts possibles pour chaque scénario de conformité. Critères stricts pour éviter le glissement entre statuts.

---

## 1. `Conforme` (vert)

**Définition** : exigence couverte ET preuve UI/comportement disponible ET référence opposable claire.

**Critères stricts** :
- Source primaire client documentaire (SRS, REP, SOP) référencée
- Source primaire client UI (capture Playwright authentifiée OU capture manuelle datée) référencée
- Référence opposable (DMN, Guide INS, PGSSI-S) référencée
- Le scénario du référentiel ANS s'exécute correctement — vérifié

**Quand l'utiliser** : rare en V0.x. Réservé aux exigences où la preuve UI **a été produite** dans cette mission (pas reportée à plus tard).

**Exemple Sunrise** : aucun verdict `Conforme` strict dans la mission V0 — tous les "Conforme" V1 ont été reclassés en `Conforme à étayer` après review.

---

## 2. `Conforme à étayer` (bleu clair)

**Définition** : exigence couverte au plan documentaire, comportement attendu plausible, mais preuve UI authentifiée non encore produite.

**Critères stricts** :
- Source primaire client documentaire OK
- Référence opposable OK
- Source primaire client UI manquante (test à faire OU à demander au client de produire)

**Quand l'utiliser** : la grande majorité des "verdicts positifs" en cours de mission Theodo, parce qu'on n'a pas le temps de tester chaque scénario UI.

**Action requise** : entrée dans `roadmap-P0-P1-P2.md` du pré-kit comme **action P1 client** — produire la capture pour Convergence avant submission.

**Exemple Sunrise V1** :
- IEPS 12.1 (logout HCP) : doc OK (`SRS-ACC-004`), pas testé en mode authentifié
- IEU 11.1 (logout patient) : idem côté app
- IEPS 5.1 (reset mdp) : capture probe publique OK mais flux complet non testé

---

## 3. `Partiel` (jaune)

**Définition** : couverture incomplète OU sous-éléments du scénario manquants.

**Critères stricts** :
- Une partie du scénario est couverte, une partie ne l'est pas
- Source(s) référencée(s) mais incomplètes
- Pas binaire : vraie nuance sur le scope de l'exigence

**Quand l'utiliser** : exigence avec sous-éléments (cas 1 / cas 2, ou liste de critères dans un même scénario).

**Action requise** : préciser dans l'`ecart` quelle partie est NC vs Conforme.

**Exemple Sunrise V1** :
- INS 41.1 : partage HCP→HCP existe (logs OK) mais pas de log INS-spécifique → `Partiel`
- IEPS 13.1 : option "rester connecté" OK mais idle timeout indépendant manquant → `Partiel`
- ADM 1.1 : RBAC documenté mais matrice rôles × droits non publiée → `Partiel`

---

## 4. `Non conforme` (rouge)

**Définition** : preuve **d'absence** ou de **non-respect** du scénario.

**Critères stricts** :
- Soit fonctionnalité absente (UI testée, pas de bouton/champ requis)
- Soit fonctionnalité présente mais comportement contradictoire
- Référence opposable + preuve d'absence (test négatif ou doc mentionnant l'absence)

**Quand l'utiliser** : seulement quand l'absence/non-respect est **prouvée**. Pas sur silence documentaire.

**Anti-patterns** :
- ❌ « REP-351 ne mentionne pas HDS donc HDS NC » → en réalité `À confirmer` (cf. exemple HDS Sunrise V1)
- ❌ « Pas trouvé dans la doc lue donc NC » → en réalité `À confirmer` jusqu'à demande au client

**Exemple Sunrise V1** :
- INS 1.1 (champs RNIV) : probe authentifiée prouve l'absence → NC
- IEU 9.1 (2FA Usager imposée) : SRS-SSP-014 V02 documenté comme optionnelle → NC
- INS 42.1 (PDF night report avec INS) : probe 8 prouve l'absence → NC

---

## 5. `Non applicable` (gris)

**Définition** : scénario hors-périmètre du produit.

**Critères stricts** :
- Profil applicabilité explicitement déclaré "non applicable" dans la fiche projet
- Justification écrite signée par RAQ (à fournir dans Convergence)

**Quand l'utiliser** : profils dont le client n'a pas le cas d'usage.

**Anti-patterns** :
- ❌ N/A par défaut sans justification (cf. erreur Sunrise V1 où INS 39.2 était N/A alors que profil applicable)
- ❌ N/A pour échapper à un scénario non testé (utiliser `À confirmer` à la place)

**Exemple Sunrise** :
- INS 39.1 (en ES) : profil "Référentiel d'identités en ES" non déclaré → N/A correct
- INS 46.1 (stockage pièces) : profil "Stockage copies" non déclaré → N/A correct
- ApCV 1.1 : profil ApCV non déclaré → N/A correct

---

## 6. `À confirmer` (bleu)

**Définition** : information manquante pour trancher, demande à formuler au client OU vérification à faire.

**Critères stricts** :
- Au moins une des sources requises (client doc, client UI, référence opposable) manquante
- Pas de fabrication de verdict — le statut **est** la conclusion
- **V0.4 — Lot 1 / A1** : `confirm_reason` codée obligatoire (cf. ci-dessous). Un `À confirmer` sans raison codée fait échouer le build.

**Quand l'utiliser** : largement, surtout en début de mission. C'est le statut **par défaut** quand le doute existe — **mais toujours avec une raison codée pour que le PM/DP sache quoi faire**.

**Action requise** : entrée dans `roadmap-P0-P1-P2.md` du pré-kit comme **action P0 PM** — demander explicitement.

### V0.4 — Enum `confirm_reason` (obligatoire) — Lot 13 réécrit

Tout `À confirmer` doit déclarer son code de raison. **`À confirmer`
n'est légitime QUE quand l'agent est physiquement incapable de
constater** (cf. `epistemic_discipline.md` Règle 2 + `rules/absence-as-nc.md`).
Les 4 codes ci-dessous décrivent les 4 motifs d'incapacité. Aucun d'eux
ne doit servir à punter un silence coordonné — un silence constaté
EST la preuve d'absence, donc `Non conforme`.

| Code | Sens (V0.4 Lot 13) | Action |
|---|---|---|
| `no_evidence_in_provided_docs` | Le client a déclaré une doc applicable (ex. SOP identitovigilance) qui n'a **pas été uploadée** dans `docs/`. **PAS** « j'ai cherché et c'est silencieux » — ça c'est NC. | Lettre demande client P0 (cite la doc manquante) |
| `evidence_ambiguous` | La doc affirme l'existence de la fonctionnalité (« le système gère X ») mais ne décrit pas son comportement, ET la probe n'a pas pu l'observer (pas de spec, mobile_pending). | Probe complémentaire OU clarif client (P0) |
| `requirement_out_of_scope` | Exigence applicable au profil mais le client a déclaré ce module hors-scope mission via `mission.product.modules_hors_scope`. | DP jalon 2 → reclasser N/A signé RAQ |
| `dp_override_pending` | Réservé au cas spécifique d'un override DP en attente. **Ne PAS abuser** : si V1 et SR ont tous deux des verdicts evidence-backed, la règle disagreement V0.4 Lot 13 garde le plus strict (cf. `rules/disagreement.md`). | Arbitrage DP requis avant jalon 2 close |

**Exemples Sunrise V1 → V0.4 reclassés avec `confirm_reason` :**
- HDS sub-thème de RGPD 1.1 : silence dans REP-351 → `À confirmer` + `confirm_reason: no_evidence_in_provided_docs`
- SRS-ACC-017 V02 (HCP creates patient) : doc dit que ça existe, UI non observée → `À confirmer` + `confirm_reason: evidence_ambiguous`
- Idle timeout : doc ne mentionne pas, peut-être ailleurs → `À confirmer` + `confirm_reason: no_evidence_in_provided_docs`

Cf. `epistemic_discipline.md` § Règle 4 — Triple gate citations pour la mécanique complète.

---

## Distribution attendue par mission

| Statut | Mission early (sem 2) | Mission late (sem 5) | Pré-kit final |
|---|---|---|---|
| Conforme | 0 | 0-2 | 0-5 |
| Conforme à étayer | 0 | 5-15 | 5-15 |
| Partiel | 5-15 | 5-15 | 5-15 |
| Non conforme | 30-50 | 60-80 | 60-80 |
| Non applicable | 0-5 | 1-5 | 1-5 |
| À confirmer | 30-50 | 5-15 | 0-5 |
| Total | 103 | 103 | 103 |

**Lecture** : en début de mission, beaucoup de `À confirmer` (information non encore reçue). Au fur et à mesure que docs arrivent et probes tournent, les `À confirmer` migrent vers `NC` ou `Partiel`. Le pré-kit final ne devrait quasi pas avoir de `À confirmer` — sinon le client n'a pas fourni assez de doc.

Si pré-kit a > 5 `À confirmer` → DP doit acter en réunion jalon 3 + lister explicitement dans le pré-kit + le client en assume la responsabilité ANS.

---

## Mapping aux preuves Convergence

L'ANS attend par scénario :
- **Conforme / Conforme à étayer** : capture d'écran ou vidéo + texte de conformité
- **Partiel** : explication de la partie couverte + roadmap pour la partie manquante
- **Non conforme** : explication + plan de mise en conformité
- **Non applicable** : justification écrite signée RAQ
- **À confirmer** : à éviter en submission Convergence — soit reclasser, soit ne pas soumettre cette exigence

---

## Numeric severity scale (V0.3 — for `disagreement.md` rule)

Used by `/ans-build` merge step and `/ans-merge` to decide soft vs hard disagreement (cf. `rules/disagreement.md` § « Soft disagreement »).

| Statut | Numeric severity |
|---|---|
| À confirmer | 0 |
| Non applicable | 1 |
| Conforme | 2 |
| Conforme à étayer | 3 |
| Partiel | 4 |
| Non conforme | 5 |

**Soft disagreement** = `abs(severity_v1 - severity_sr) ≤ 1`.
**Hard disagreement** = `abs(severity_v1 - severity_sr) ≥ 2`.

**Rationale** : The scale puts the *most consequential* verdicts at the top (NC = 5 because it triggers client remediation work) and *information-absent* at the bottom (À confirmer = 0 because it's not a verdict, it's a deferral). N/A is at 1 because misclassifying a real exigence as N/A is small in narrative impact (vs misclassifying as NC). Not totally ordered semantically, but ordered by *consequence-on-client-roadmap* — which is what matters for "soft vs hard" merge decisions.

**Exception** : Conforme ↔ Non conforme (delta=3) is always hard, even if the rationale narrative seems close. There is no scenario where these are 1 cran apart.

---

*Dernière mise à jour : 2026-05-08 (V0.3 ajout severity scale).*
