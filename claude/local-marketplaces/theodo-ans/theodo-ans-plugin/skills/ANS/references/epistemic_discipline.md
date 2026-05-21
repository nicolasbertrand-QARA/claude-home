# Discipline épistémique du plugin theodo-ans-gap-analysis

Cette référence est **non négociable**. Elle existe parce que les missions ANS engagent la responsabilité de Theodo face à un assesseur (NB ou évaluateur ANS) qui demandera, scénario par scénario : « sur quelle preuve repose ce verdict ? ». Un verdict halluciné = dossier rejeté = client perdu.

**À charger systématiquement** par tout slash command et tout subagent qui émet ou critique un verdict.

---

## Règle 1 — Citation obligatoire (Q9-A)

Tout verdict autre que `À confirmer` ou `Non applicable` DOIT inclure :

1. **Source primaire client** — chemin précis dans la doc fournie :
   - `PRO-460 V20 §5.2 SRS-SSP-014 p.22` (référence à un PDF + section + ligne)
   - `UI testing — probe 6.1 — capture: probe-patient-form.png` (référence à un artefact)
   - `1Password vault → testing-creds — vérifié 2026-04-15` (référence à un accès)

2. **Référence opposable** — clause de référentiel :
   - `Guide INS V3.0 EXI ID 39 + RNIV règle 4`
   - `DMN V1.2.2 §IEPS 9.1`
   - `PGSSI-S Référentiel IE_RECO 18`

Si l'une des deux manque → **statut = `À confirmer`**, jamais autre chose.

### Exemples corrects

```python
"INS 42.1": Assessment(
    statut="Non conforme",
    sources_client=[
        ("Probe 8 — rapport imprimable John Doe", "reports/artifacts/08-rapport-text.txt"),
        ("PRO-460 V20", "§5.1.2 SRS-REP-009 p.20"),
    ],
    sources_opposables=[
        "Guide INS V3.0 EXI DIF 02 + règle 32",
    ],
    ecart="...",
)
```

```python
"RGPD 1.1 / HDS sub-thème": Assessment(
    statut="À confirmer",  # pas "Non conforme" — l'absence dans REP-351 ne prouve pas l'absence d'attestation HDS
    sources_client=[
        ("REP-351 V04", "§5.2.3 — silence sur HDS"),
    ],
    sources_opposables=[
        "RGPD art. 9 + HDS référentiel ANS",
    ],
    ecart="REP-351 décrit cybersécurité, pas attestation HDS. Demande à Sunrise : attestation, contrat GCP HDS, scope.",
)
```

### Exemples incorrects (à rejeter à la review)

```python
# INCORRECT — pas de source primaire
"PSC 1.1": Assessment(statut="Non conforme", ecart="Sunrise n'est pas raccordé à PSC")

# INCORRECT — référence opposable trop vague
"INS 1.1": Assessment(statut="Non conforme", sources_opposables=["Guide INS"])

# INCORRECT — verdict Conforme sans preuve UI
"IEPS 12.1": Assessment(statut="Conforme", sources_client=[("SRS-ACC-004", "PRO-460")])
# → Doit être "Conforme à étayer" : la doc ne suffit pas, il faut capture du logout en UI authentifiée
```

---

## Règle 2 — Défaut conservateur « À confirmer » (Q9-B, V0.4 Lot 13 réécrit)

**Principe directeur (non négociable)** : le but de la gap analysis
est de **trancher**. « À confirmer » est un statut d'**ignorance**
résiduelle (« je ne peux pas vérifier »), pas un statut de **prudence**
(« je préfère ne pas me prononcer »).

### Quand `À confirmer` EST légitime

UNIQUEMENT quand l'agent est **physiquement incapable de constater** :

- La probe ne couvre pas ce scénario ET l'exigence dépend d'un
  comportement UI que l'agent n'a pas pu observer
- Le doc requis (déclaré par le client) n'a pas été uploadé dans `docs/`
- Le scope produit est ambigu (le brief lui-même ne tranche pas)
- La langue du doc bloque la lecture (NL/DE) et l'agent n'a pas de
  version EN/FR

→ `confirm_reason` doit citer **précisément** la source manquante.

### Quand `À confirmer` est un FAUX-FUYANT (bannir)

Quand l'agent A constaté l'absence dans toutes les sources applicables
au scope → c'est `Non conforme`, pas `À confirmer`. Cf.
`rules/absence-as-nc.md` § Principe.

Anti-pattern à reconnaître :

```python
# ❌ FAUX-FUYANT V0.4 Lot 13
Assessment(statut="À confirmer",
           confirm_reason="no_evidence_in_provided_docs",
           methode="Probe UI authentifiée + Doc",
           ecart="Pas mentionné dans REP-351 ni dans la probe HCP")
# Si tu as cherché dans les 2 sources et constaté l'absence,
# l'absence EST le verdict. NC, pas ÀC.
```

### Hiérarchie des verdicts (V0.4 Lot 13)

```
À confirmer  (impossibilité de vérifier — pas de probe ni de doc disponible)
   ↓
Conforme à étayer  (couverture documentaire OK, manque preuve UI authentifiée)
   ↓
Conforme  (doc + preuve UI OK)

Non applicable  (profil hors périmètre — justification écrite signée RAQ)

Partiel  (couverture incomplète, sous-éléments à compléter)
   ↓
Non conforme  (preuve d'absence : silence coordonné UI + doc applicable)
```

### Cas particulier — verdict positif

Pour un verdict positif (Conforme / Conforme à étayer) la preuve
positive reste obligatoire. Sur silence positif (« doc dit qu'on peut
faire X ») sans observation → `Conforme à étayer` pas `Conforme`.

### Doc en langue non maîtrisée

Si le doc est en NL/DE et le PM ne lit pas couramment → `À confirmer`
**uniquement si pas de version EN/FR demandable**. Sinon, demander la
traduction au client et trancher après.

---

## Règle 3 — Self-review systématique (Q9-D)

Tout `/ans-build` est suivi automatiquement d'un passage `ans-self-reviewer` (subagent indépendant). Le subagent :

1. Reçoit en input : la gap analysis brute + accès en lecture aux sources client + références opposables.
2. **Ne reçoit PAS** : le rationale du 1er passage (`evidence` + `ecart` cachés). Il forme son propre jugement.
3. Output : `disagreements.md` listant les verdicts qu'il aurait classés différemment, avec son rationale.

### Cas de désaccord typiques (vus sur Sunrise V1)

| Type d'erreur | Exemple Sunrise V1 | Action self-review |
|---|---|---|
| Confusion énoncé/scénario | INS 1.4 « lieu de naissance » au lieu de « distinction INS/Sécu » | Reclassifier la raison, garder le verdict |
| Boucle copier-coller | INS 11-35 verdict identique pour 25 règles RNIV différentes | Splitter — chaque règle a son rationale |
| Verdict trop indulgent | 9 « Conforme » sans capture UI | Reclasser en « Conforme à étayer » |
| Verdict trop sévère | HDS « Non conforme » sur silence doc | Reclasser en « À confirmer » |
| Profil mal mappé | INS 39.2 « N/A » alors que profil hors-ES applicable | Reclasser en « Non conforme » |

### Merge des résultats — V0.4 Lot 9 (simplifié)

Le merge applique la **règle Disagreement** (`rules/disagreement.md`) :

Pour chaque scénario :
- **Accord** (V1 == SR) : verdict V1 conservé, marqué `[review:✓]`
- **Désaccord avec override DP existant** : applique le verdict signé du
  DP (`dp_decisions.jalon_2.disagreement_overrides[]`).
- **Désaccord non résolu** (par défaut) : reclasse en `À confirmer` +
  `confirm_reason: dp_override_pending` + entrée dans `disagreements.md`.
  Le DP arbitre en jalon 2.

V0.3 distinguait soft (delta sévérité ≤ 1) vs hard (≥ 2) — supprimé en
V0.4. Aucun verdict imposé par heuristique : DP arbitre ou À confirmer.

---

## Règle 4 — Triple gate citations (V0.4 — Lot 1 / A1)

**Origine** : run Sunrise du 2026-05-08 → 26 « À confirmer » / 0 « Conforme » sur 6 PDFs reçus. Pattern implausible. La cause racine : Règles 1+2 acceptaient un verdict mou sans signal que la lecture-doc avait été tentée.

La Règle 4 ferme cette porte. Elle s'applique **automatiquement** au build via `ans-build` étapes 5.5 et 5.6 (validation schema + coverage threshold), exit 1 sur violation. Trois gates :

### Gate 1 — Citation primaire obligatoire pour les verdicts engageants

Pour tout verdict ∈ {Conforme, Conforme à étayer, Partiel, Non conforme}, l'objet Assessment **DOIT** contenir `sources_client` avec ≥1 paire `(doc_id, section_or_page)`.

`Non applicable` et `À confirmer` sont exemptés (mais voir gate 2 + audit_note).

### Gate 2 — `confirm_reason` codée pour chaque À confirmer

Tout assessment au statut `À confirmer` **DOIT** spécifier `confirm_reason` parmi :

| Code | Sens | Action implicite |
|---|---|---|
| `no_evidence_in_provided_docs` | Les docs reçus ne couvrent pas ce point | P0 PM client : demander complément doc |
| `evidence_ambiguous` | La doc dit « la fonctionnalité X existe » mais ne décrit pas son comportement attendu | P0 PM probe : tester en UI authentifiée OU clarif client |
| `requirement_out_of_scope` | Exigence applicable mais le client a explicitement déclaré ce module hors-scope mission | À acter par DP signature en jalon 2 → reclassement N/A |
| `dp_override_pending` | Verdict initial différent reclassé À confirmer par règle disagreement après self-review | Arbitrage DP requis avant jalon 2 close |

Un `À confirmer` sans `confirm_reason` (ou avec une valeur hors enum) **fait échouer le build**. Cela force l'agent à se positionner explicitement sur la nature de l'absence d'evidence — pas un défaut conservateur paresseux.

### Gate 3 — `evidence_attempted` boolean obligatoire et true en sortie

Champ `evidence_attempted: bool` **obligatoire** sur tout Assessment. Sémantique :

- `true` : l'auteur a effectivement lu / tenté de lire les sources pour ce scénario (PDFs cités dans `source-index.json`, probes existantes, captures UI fournies).
- `false` : l'auteur n'a pas lu (ex. boucle copier-coller sur 25 INS sans rouvrir les PDFs, défaut conservateur sans recherche).

Tout assessment en `evidence_attempted=false` à la fin du build **fait échouer le build**. L'agent doit boucler sur étape 3 (subagent ans-doc-reader sur les sources manquantes) puis ré-attribuer les verdicts.

### Coverage gate au niveau du build

Au-delà du per-assessment, le build calcule le ratio **PDFs cités / PDFs reçus**. Seuil par défaut **0,80** (configurable via `tech.docs_coverage_threshold` du Project Brief).

Si < seuil → fail build avec liste explicite des PDFs jamais cités. Signal direct : « tu as ignoré ces N documents ». L'agent corrige par re-lecture ciblée puis ré-attribution.

### Pourquoi ces 3 gates ensemble

Aucune des 3 prise isolément ne ferme la porte :

- Gate 1 sans gate 3 → l'agent flag tout en À confirmer (citation non requise) → 0 Conforme passe.
- Gate 2 sans gate 1 → l'agent code des raisons sans réelle lecture → reasonshells creuses.
- Gate 3 sans gates 1+2 → l'agent met `evidence_attempted=true` partout par défaut sans citer.

Les 3 ensemble forcent le triplet : **lecture effective** → **citation primaire** → **verdict assumé OU raison-de-déférer codée**.

### Effets observables attendus

- Distribution post-Triple-gate sur Sunrise V0.4 : ~30-50 NC + ~5-15 Conforme à étayer + ~5-15 Partiel + 0-5 N/A justifiés + 0-15 ÀC avec raisons codées. Plus jamais 26 ÀC en bloc.
- Si le build sort en exit 1 sur Triple gate, lis `analysis/.build-blocked-reason.json` pour la liste précise des violations.

---

## Règle 5 — Discipline rédactionnelle (V0.4 Lot 17)

Tout texte produit par l'agent dans un Assessment, un brief de revue,
ou tout livrable client (`ecart`, `evidence`, `recommandation`,
`audit_note`, `briefs-revue/*.md`) **DOIT être rédigé en français
professionnel QARA**. Pas de pseudo-code, pas de jargon plugin,
pas de syntaxe machine.

### Bannir (anti-patterns observés Sunrise 2026-05-09)

```
❌ "Voie B signée jalon-1 + audit_outcome=mark_na_with_audit_notes —
    exigence reconnue applicable mais non-testable sur Sunrise"

❌ "dp_decisions.jalon_1.voie_ins: voie_b signée 2026-05-09T04:35:38Z"

❌ "sub_decision_impact mass-update appliqué"

❌ "Voie A" / "Voie B"
```

### Écrire à la place

```
✓ "Le rôle « Esclave d'identité » a été retenu en jalon 1 : le système
   reçoit le flux d'identité INS qualifié depuis un système prescripteur
   et n'a pas la responsabilité de la qualification. Cette exigence
   relève de la responsabilité du référentiel d'identité amont — non
   applicable au DMN Sunrise."

✓ "Décision DP en jalon 1 du 9 mai 2026 : positionnement « Esclave
   d'identité » avec audit du rôle alternatif (Référentiel d'identité)
   en N/A justifié."

✓ "Conformément à la décision de positionnement INS prise en jalon 1,
   l'exigence est marquée non applicable."
```

### Règles concrètes

1. **Terminologie INS** : « Référentiel d'identité » et « Esclave
   d'identité » exclusivement. JAMAIS « Voie A » / « Voie B » dans le
   texte. Les codes internes `voie_a` / `voie_b` peuvent apparaître dans
   les chemins JSON cités, mais les phrases descriptives utilisent les
   libellés métier.

2. **Pas de chemins JSON dans les phrases** : on n'écrit pas
   « `dp_decisions.jalon_1.voie_ins.payload.decision = voie_b` » dans un
   ecart. On écrit « La décision de positionnement INS du jalon 1 a
   retenu le rôle Esclave d'identité ». Le chemin JSON peut figurer
   en source primaire (citation traçable) mais pas dans la prose.

3. **Pas de pseudo-code** : `audit_outcome=mark_na_with_audit_notes`
   est interne au plugin. L'utilisateur final voit « avec note d'audit
   du rôle alternatif » ou « N/A audité avec justification écrite ».

4. **Pas de timestamps techniques en prose** : « signée 2026-05-09T04:35:38Z »
   → « signée le 9 mai 2026 ». Le timestamp ISO peut figurer dans une
   citation source, pas dans une phrase qui se lit naturellement.

5. **Phrases complètes**, sujet + verbe, ponctuation. Pas de fragments
   bullet-style dans les champs `ecart` / `recommandation` (le format
   bullet est réservé aux briefs).

6. **Acronymes ANS** : à expliciter à la première occurrence dans un
   livrable client (RNIV, INSi, PSC, MSSanté, INS, DMN, EXI, IEPS,
   IEU, etc.). Dans les champs internes (assessments JSON / xlsx),
   les acronymes seuls sont OK car le contexte est connu.

7. **Pas d'auto-référence au plugin** dans les livrables : « Le plugin
   theodo-ans-gap-analysis V0.4 », « `/ans-build` étape 4.5 »,
   « Lot 13 », « le subagent ans-self-reviewer » — tout cela est interne
   à Theodo, jamais visible côté client. Si tu dois citer la
   méthodologie, écris « gap analysis Theodo selon la méthodologie ANS ».

### Tests rapides avant d'émettre

Avant de finaliser un assessment ou un brief, relis le `ecart` /
`recommandation` à voix haute (mentalement). Si la phrase contient :
- un underscore (`_`),
- un point (`.`) entre deux mots non-séparés par espace,
- des CAPITALES techniques (`MARK_NA`, `JSON`, `EOF`),
- des chemins (`dp_decisions.X.Y.Z`),

→ réécris jusqu'à ce que ça sonne comme une phrase d'un consultant
QARA expérimenté qui dicterait son rapport au DP.

---

## Anti-patterns à reconnaître

### 1. Citation plausible mais fabriquée

Risque : Claude « invente » une référence opposable qui sonne crédible mais n'existe pas.

Mitigation : `ans-self-reviewer` re-vérifie chaque citation contre `dmn_exigences_full.md` et `referentiel_identites_qualification.md`. Si une réf citée n'existe pas dans les sources locales, → flag « citation invérifiable ».

### 2. Inheritance loop (Sunrise V1 INS 11-35)

Risque : pour des exigences avec template d'énoncé similaire, le 1er passage utilise une boucle Python qui produit 25 verdicts identiques.

Mitigation : règle de validation = 2 verdicts ne peuvent JAMAIS avoir le même `ecart` ET la même `recommandation` ET le même `evidence`. Si oui → erreur de boucle, à réécrire.

### 3. Verdicts en cascade non explicitée

Risque : INS 22 dépend de INS 4, INS 4 dépend de INSi (INS 37). Si INS 37 NC → tout est NC, mais le plugin ne dit pas pourquoi.

Mitigation : champ `depends_on` obligatoire pour les verdicts qui sont NC par effet domino. Le plugin produit alors un graphe de dépendances dans le brief de revue.

---

## Tests de la discipline (à inclure dans CI)

Avant tag `v0.x`, lancer les vérifications :

```bash
# 1. Aucune Assessment sans source si statut ≠ "À confirmer" / "Non applicable"
python -m theodo_ans.qa check-citations <client>

# 2. Aucune duplication ecart+recommandation+evidence dans un même run
python -m theodo_ans.qa check-no-duplication <client>

# 3. Self-review obligatoire passé après /ans-build
test -f <client>/analysis/disagreements.md || exit 1

# 4. Sunrise re-run produit ≤ 5 % delta vs ground truth
python -m theodo_ans.qa diff tests/fixtures/sunrise/expected/gap-analysis.xlsx <client>/analysis/gap-analysis.xlsx
```

---

## Pourquoi ces règles ?

Ces règles existent parce qu'elles cassent les modes d'échec qu'on a observés concrètement sur Sunrise V1 :

| Erreur Sunrise V1 | Règle qui l'aurait évitée |
|---|---|
| INS 1.4 / 2.1 / 8.1 / 10.1 commentés sur la mauvaise règle RNIV (E1-E4) | Règle 1 : citer le scénario, pas l'énoncé global |
| HDS marqué NC sur silence REP-351 (E6) | Règle 2 : silence ≠ absence |
| 9 verdicts « Conforme » sans capture UI (E10) | Règle 1 : exiger preuve UI pour Conforme |
| Boucle 25 entrées INS 11-35 identiques (E11) | Anti-pattern 2 + règle 3 (self-review) |
| INS 39.2 « N/A » alors qu'applicable (E5) | Règle 3 (self-review) cross-check profil ↔ scénario |

Ces règles ne sont pas des préférences. Elles sont la **différence entre un dossier vendable et un dossier rejeté**.

---

## Règles modulaires liées (V0.3)

Au-delà des 3 règles non-négociables ci-dessus, 5 règles complémentaires ont migré dans `rules/` à partir du runner UI (CLI parity) :

| Slug | Couverture |
|---|---|
| `probe-evidence` | Mapping verdict probe → verdict assessment (autoritaire UI-observable) |
| `docs-fetch` | Step déterministe : fetch docs Drive avant tout verdict |
| `absence-as-nc` | Triangulation décisive : silence coordonné UI+doc+manuel = NC |
| `disagreement` | V0.2 raffinement : soft (delta ≤ 1) garde le strict ; hard (delta ≥ 2) → `À confirmer` |
| `publish-target` | Mapping subfolder Drive (idempotent + checksum) |

Charger via la frontmatter `applies_rules: [...]` de chaque command. Voir `rules/README.md`.

---

*Dernière mise à jour : 2026-05-09 (V0.4 — Lot 1 / A1 : Triple gate citations).*
