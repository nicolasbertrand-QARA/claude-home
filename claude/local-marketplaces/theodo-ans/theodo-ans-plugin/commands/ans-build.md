---
description: Lance la gap analysis sur les docs Drive du client + self-review automatique.
argument-hint: <client-slug>
applies_rules: [docs-fetch, probe-evidence, absence-as-nc, disagreement]
requires_tier_at_least: T3
retry_policy: transient_only
criticality: blocking
failure_blocks: [ans-deliverables, ans-publish]
---

# /ans-build {{ args }}

Tu lances la gap analysis pour la mission **{{ args }}**. Pré-requis : intake fait, project-brief.json à tier T3 (profils décidés), docs P0 reçus dans le folder Drive.

## Charges immédiates (ne saute aucune)

```
skills/ANS/SKILL.md
skills/ANS/references/exigences_official_v1.json           [SOURCE DE VÉRITÉ — 103 scénarios ANS officiel onglet Exigences]
skills/ANS/references/dmn_exigences_full.md                [LEGACY — transcription approximative, NE PLUS UTILISER pour les libellés/scénarios]
skills/ANS/references/referentiel_identites_qualification.md
skills/ANS/references/epistemic_discipline.md             [CRITIQUE]
skills/ANS/references/verdict_taxonomy.md
skills/ANS/references/convergence_workflow.md
skills/ANS/references/sub_decision_impact.json             [dependency map V0.3]
skills/ANS/references/quality_thresholds.md
skills/ANS/references/baseline_distributions.json
skills/ANS/references/rules/docs-fetch.md                  [auto-loaded via applies_rules]
skills/ANS/references/rules/probe-evidence.md
skills/ANS/references/rules/absence-as-nc.md
skills/ANS/references/rules/disagreement.md
skills/ANS/references/writing_pack/anchors.json           [V0.5 — exemplars hand-authored, format obs_fr + reco_client]
skills/ANS/references/writing_pack/exemplars.json         [V0.5 — pool Okeiro+LibreView, 137 prose-client validées]
agents/ans-prose-renderer.md                              [V0.5 — sub-agent Phase B render-for-client]
intake/project-brief.json                                  [CANONICAL — verdict reads here]
```

## Source de vérité officielle (V0.4 Lot 18 + Lot 20)

`exigences_official_v1.json` est l'export brut de l'**onglet "Exigences"
du Google Sheet ANS Convergence officiel** (téléchargé 2026-05-10).
C'est la SEULE source autoritaire pour :

- Liste des 103 scénarios à évaluer (col 11 `N° scénario`)
- Libellé des exigences (col 9 `Enoncé de l'exigence (DOIT) ou de la
  préconisation (DEVRAIT)`)
- Texte des scénarios de conformité (col 12 `Scénario de conformité`)
- Descriptions des preuves attendues (cols 14, 16, 18 `Preuve 1/2/3`)
- Section / Bloc / Fonction / Nature de l'exigence / Profil applicable

**Colonnes 19-25 (Applicable / Conforme / Pourquoi / Reco / Impact UX
/ Q&A / EPIC) sont vidées dans `exigences_official_v1.json`** —
elles étaient polluées par les résidus d'une mission antérieure
(V0.4 Lot 20 cleanup). Ces colonnes sont l'OUTPUT à produire par le
plugin, JAMAIS de l'input à lire ou recopier.

**`dmn_exigences_full.md` est une transcription approximative legacy** :
ne plus utiliser comme référence pour le contenu des scénarios.

Si une de ces sources manque : `ÉCHEC PRÉ-REQUIS — {liste}`.

## Exit codes (V0.4 / Lot 3 / A6)

Convention partagée par toutes les commandes du plugin. La UI lit aussi
`analysis/.last-run-status.json` pour afficher un bandeau actionnable.

| Code | reason_code | Sens |
|---|---|---|
| 0 | (success ou success_with_warnings) | OK |
| 1 | fatal | Erreur non catégorisée — voir le log |
| 2 | lock_busy | `.lock` détenu par un autre process actif |
| 3 | brief_missing | `intake/project-brief.json` introuvable |
| 4 | tier_too_low | brief tier insuffisant pour cette commande |
| 5 | degenerate | distribution de verdicts suspecte (cf. quality_thresholds) |
| 6 | docs_empty | `docs/` vide alors que requis |
| 7 | state_guard | mission dans un état incompatible avec un re-run |
| 8 | triple_gate_violation | violations Triple gate (cf. epistemic_discipline §Règle 4) |
| 9 | doc_coverage_below_threshold | < 80 % PDFs cités |
| 10 | probe_evidence_ignored | > 2 verdicts assessment contredisent un probe verdict clair (cf. Lot 25 étape 4.5) |
| 11 | rule_misalignment | > 2 verdicts citent une règle RNIV ≠ règle testée par le scénario (cf. Lot 26 étape 5.7) |
| 12 | voie_b_universal_bypass | N/A voie_b appliqué sur scénario universel (énoncé sans préfixe conditionnel — cf. Lot 26 étape 4-bis) |
| 13 | client_prose_lint_violation | Motif interne plugin / Theodo détecté dans `obs_fr` ou `reco_client` (étape 7.6). La Phase B doit relancer. |
| 14 | cas_dispatch_violation | Scénario à Cas 1/Cas 2 split mal scopé : verdict ne respecte pas `status_hint=Non applicable` OU ecart fuite des éléments du Cas non applicable (étape 4-ter / V0.5 R10). |
| 15 | merge_override_not_applied | Un override DP signé (verdict_overrides[], jalon_2.a_confirmer_actions[], ou jalon_3.dynamic_points_responses[]) n'a pas été appliqué au final.json. Cf. overrides-collected.json (étape 7.3 / V0.5 R8). |

Toute exit ≠ 0 doit être accompagnée d'un fichier `analysis/.last-run-status.json`
(cf. helper `_write_status` ci-dessous).

## Étape 0 — Lock + Project Brief + Tier check + Resume detection (B5)

```bash
MISSION_ROOT=~/missions/{{ args }}
ANALYSIS=$MISSION_ROOT/analysis
mkdir -p "$ANALYSIS"

# Helper : écrit le status file de fin de run
_write_status() {
  local rc=$1; local reason=$2; local stage=$3; local msg=$4
  python3 - <<PYEOF
import json, datetime
from pathlib import Path
out = Path("$ANALYSIS/.last-run-status.json")
out.write_text(json.dumps({
  "exit_code": $rc,
  "reason_code": "$reason",
  "stage": "$stage",
  "command": "ans-build",
  "message_human": """$msg""",
  "finished_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
}, ensure_ascii=False, indent=2), encoding="utf-8")
PYEOF
}

# 1. Lockfile (dual-PID format V0.4 — cf. Lot 3 / A6 lockfile.py)
LOCK=$MISSION_ROOT/.lock
if test -f "$LOCK"; then
  HOLDER_PID=$(awk '{print $1}' "$LOCK")
  # V0.4 Lot 14 — re-entrance detection : si HOLDER_PID est mon
  # claude parent ($PPID), c'est mon propre run qui tient le lock
  # (la UI a appelé update_run_pid avec mon PID claude juste avant
  # de me spawn). Continue normalement, ne pas re-écrire le lock.
  if [ "$HOLDER_PID" = "$PPID" ]; then
    echo "[lock] re-entrant — HOLDER ($HOLDER_PID) = mon claude parent, continue"
    LOCK_OWNED_BY_ME="false"  # je ne dois PAS le supprimer en EXIT trap
  elif kill -0 "$HOLDER_PID" 2>/dev/null; then
    _write_status 2 lock_busy etape_0 "Mission verrouillée par PID $HOLDER_PID — cf. .lock"
    echo "[LOCKED] mission {{ args }} en cours d'usage par PID $HOLDER_PID"
    exit 2
  else
    rm -f "$LOCK"  # stale, je peux écraser
    echo "$$ $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$LOCK"
    LOCK_OWNED_BY_ME="true"
  fi
else
  echo "$$ $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$LOCK"
  LOCK_OWNED_BY_ME="true"
fi
# Cleanup en EXIT trap : ne supprime QUE si je suis le créateur
# (sinon je casse le lock du run qui m'englobe — UI side l'enlèvera).
trap '[ "$LOCK_OWNED_BY_ME" = "true" ] && rm -f "$LOCK"' EXIT

# 2. Read brief
BRIEF=$MISSION_ROOT/intake/project-brief.json
if ! test -f "$BRIEF"; then
  _write_status 3 brief_missing etape_0 "pas de project-brief.json — lance /ans-init d'abord"
  echo "ÉCHEC : pas de project-brief.json — lance /ans-init d'abord"; exit 3
fi

# 3. Tier check (T3 minimum pour /ans-build)
TIER=$(jq -r '.tier' "$BRIEF")
case "$TIER" in
  T3) ;;
  *)
    _write_status 4 tier_too_low etape_0 "tier=$TIER, /ans-build requiert T3 (profils DMN décidés post-jalon-1)"
    echo "ÉCHEC : tier=$TIER, mais /ans-build requiert T3 (profils DMN décidés post-jalon-1)"; exit 4 ;;
esac

# 4. Resume detection (B5 — V0.4 / Lot 3) — si une partial.json existe d'un run
# précédent interrompu, charge la liste des exigences déjà traitées et skip-les
# en étape 5. Garde-fou : si la partial.json a > 2h, ignorer (probablement obsolète).
PARTIAL=$ANALYSIS/assessments.v1-build.partial.json
if test -f "$PARTIAL"; then
  AGE_S=$(($(date -u +%s) - $(date -u -r "$PARTIAL" +%s 2>/dev/null || stat -f %m "$PARTIAL")))
  if [ "$AGE_S" -lt 7200 ]; then
    DONE_COUNT=$(jq -r '.done | length' "$PARTIAL" 2>/dev/null || echo 0)
    echo "[resume] $DONE_COUNT exigence(s) déjà traitée(s) dans la partial.json (age ${AGE_S}s) — skip en étape 5"
  else
    echo "[resume] partial.json > 2h — ignorée"
    rm -f "$PARTIAL"
  fi
fi
```

## Étape 1 — Apply docs-fetch rule

→ Voir `skills/ANS/references/rules/docs-fetch.md` (auto-loaded). Lire `tech.docs_drive_url` du brief, fetch via gws, populer `~/missions/{{ args }}/docs/`.

## Étape 2 — Vérification cohérence brief vs docs

- [ ] Au moins 1 doc PDF SRS référencé dans le brief est présent dans docs/
- [ ] Pathway lisible dans `dp_decisions.jalon_1.pathway` (dernière version)
- [ ] Voie INS lisible dans `dp_decisions.jalon_1.voie_ins`
- [ ] Profils applicables lisibles dans `dp_decisions.jalon_1.profils_dmn`

Si manque : `ÉCHEC PRÉ-REQUIS — relance après jalon 1 signé`.

## Étape 3 — Lecture des sources (subagent ans-doc-reader)

Spawn `ans-doc-reader` :

```
Tu es ans-doc-reader. Lis tous les PDFs/docx du folder docs/ de la mission {{ args }}.
Pour chaque document, extrais : id (PRO-460, REP-351...), version, date, sections, mots-clés ANS (INS, INSi, RNIV, PSC, PGSSI-S, HDS, MSSanté, RPPS, ADELI, FHIR...) avec pages.
Output : analysis/source-index.json.
Discipline epistemic_discipline.md règles 1+2.
```

## Étape 4 — Application sub_decision_impact (V0.4 Lot 17 + Lot 26 universel_filter)

Lis `sub_decision_impact.json` + `dp_decisions.jalon_1.*` du brief.

Pour chaque exigence dont l'applicabilité par défaut est modifiée :
- Le statut par défaut est appliqué (`Applicable`, `Non applicable`,
  `À confirmer` selon la règle).
- Le champ `audit_note` (pour les N/A) ET le champ `ecart` (pour mémoire)
  sont rédigés en utilisant le **`rationale_fr_assessment`** de la règle
  comme texte de base. Ce texte est en français professionnel QARA et
  utilise les libellés métier (« Référentiel d'identité », « Esclave
  d'identité » — JAMAIS « Voie A » / « Voie B »).
- L'agent peut adapter à la marge (ajouter le contexte client précis,
  ex. « Sunrise reçoit son flux d'identité depuis l'application
  prescripteur Maison Blanche ») mais NE recopie PAS de pseudo-code,
  PAS de chemin JSON, PAS de timestamps techniques.

Discipline rédactionnelle : cf. `epistemic_discipline.md` § Règle 5.

### Étape 4-bis — Garde universal_filter voie_b (V0.4 Lot 26 — non négociable)

**Cause racine adressée** : bug Sunrise 2026-05-11 — INS 1.4 marqué N/A par mass-update voie_b alors que son énoncé ne porte pas le préfixe conditionnel « Si le Système est référentiel d'identité ». Le scénario INS 1.4 (champ SECU distinct du champ INS) est une obligation universelle de stockage qui s'applique aussi en voie_b.

**Règle déterministe à appliquer AVANT toute assignation N/A par règle voie_b** :

```python
import re, json
from pathlib import Path

PATTERN_CONDITIONAL = re.compile(
    r"si\s+le\s+syst[èe]me\s+est\s+(un\s+)?r[ée]f[ée]rentiel\s+d['’]identit",
    re.IGNORECASE
)

official = json.loads(Path("skills/ANS/references/exigences_official_v1.json").read_text())
H = official["headers"]
i_scen = H.index("N° scénario")
i_enonce = H.index("Enoncé de l'exigence (DOIT) ou de la préconisation (DEVRAIT) ")

# universal_by_id[nid] = True si scénario universel (préfixe absent → applicable même en voie_b)
universal_by_id = {}
for r in official["rows"]:
    nid = r[i_scen]
    if not nid: continue
    universal_by_id[nid] = not bool(PATTERN_CONDITIONAL.search(r[i_enonce] or ""))
```

**Comportement attendu** :

- INS 11.1, 12.1, 15.1, 16.1-3 → énoncé contient « Si le Système est référentiel d'identité » → `universal=False` → N/A voie_b légitime ✅
- INS 1.4 → énoncé ne contient pas le préfixe → `universal=True` → **PAS de N/A** → reste applicable, traité par étape 5 standard ✅

**Audit étape 4-bis (fail-build si bypass)** : à la fin de la phase 4, écrire `analysis/voie-b-filter-audit.json` :

```json
{
  "filtered_universal_kept_applicable": ["INS 1.4", ...],
  "applied_na_voie_b": ["INS 11.1", "INS 12.1", "INS 15.1", "INS 16.1", "INS 16.2", "INS 16.3", ...]
}
```

Si l'agent applique N/A voie_b sur un scénario sans préfixe conditionnel → exit_code 12, reason_code `voie_b_universal_bypass`.

**Exemple correct (rôle Esclave d'identité retenu en jalon 1)** :

```python
Assessment(
    n_scenario="INS 4.1",
    statut="Non applicable",
    audit_note="Le rôle « Esclave d'identité » a été retenu en jalon 1 : Sunrise reçoit le flux d'identité INS qualifié depuis l'application prescripteur et n'assume pas la qualification. Cette exigence relève du référentiel d'identité amont. Si Sunrise bascule un jour sur le rôle Référentiel d'identité, l'exigence redevient applicable et nécessitera la mise en place de la qualification INSi.",
    ecart="Exigence relevant du référentiel d'identité amont, non applicable au DMN dans la configuration actuelle.",
    ...
)
```

**Exemple incorrect (bot-speak banni V0.4 Lot 17)** :

```python
# ❌ NE PAS PRODUIRE
audit_note="Voie B signée jalon-1 + audit_outcome=mark_na_with_audit_notes — exigence reconnue applicable mais non-testable sur Sunrise"
ecart="dp_decisions.jalon_1.voie_ins: voie_b signée 2026-05-09T04:35:38Z"
```

### Étape 4-ter — Dispatch Cas de figure n°1 / Cas de figure n°2 (V0.5 R10)

**Cause racine adressée** (Sunrise 2026-05-11) :
- INS 1.2 mobile capture protocol ciblait Cas 1 (création identité) alors que voie B impose le scope Cas 2 (visualisation flux reçu).
- INS 1.3 Cas 2 indique littéralement « Pas de scenario de test associé » → en voie B le scénario est SANS OBJET, devrait être N/A. Verdict final était À confirmer avec capture mobile DDN 32/13/1990 = Cas 1 hors scope.
- L'évaluation par défaut mélangeait les deux cas → ecart + reco hors scope structurel.

**Règle déterministe à appliquer après l'étape 4-bis et avant l'étape 4.5** :

```python
import re, json
from pathlib import Path

# Patterns de parsing du scénario officiel.
# Note : les libellés varient — "Cas de figure n°1", "Cas de figure 1", "Cas de figure n°2", etc.
# On utilise split plutôt que group capture pour éviter les pièges de [^:]* qui consomment trop.
SPLIT_CAS_1 = re.compile(r"cas\s+de\s+figure\s+(?:n[°o]?\s*)?1\b[^\n]*\n?", re.IGNORECASE)
SPLIT_CAS_2 = re.compile(r"cas\s+de\s+figure\s+(?:n[°o]?\s*)?2\b[^\n]*\n?", re.IGNORECASE)
PATTERN_NO_SCENARIO = re.compile(r"pas\s+de\s+sc[ée]nario\s+de\s+test\s+associ[ée]", re.IGNORECASE)

base = Path.home() / "missions" / "<client>" / "analysis"
brief = json.loads((Path.home() / "missions" / "<client>" / "intake" / "project-brief.json").read_text())
voie_ins = (brief.get("dp_decisions", {})
                .get("jalon_1", {})
                .get("voie_ins", [{}])[-1]
                .get("payload", {})
                .get("decision"))  # "voie_a" / "voie_b" / None

official = json.loads(Path("skills/ANS/references/exigences_official_v1.json").read_text())
H = official["headers"]
i_scen = H.index("N° scénario")
i_scen_conf = H.index("Scénario de conformité")

# Map: scenario_id → {has_cas_split, cas_1_text, cas_2_text, voie_applied, cas_applied, status_hint}
dispatch = {}
for r in official["rows"]:
    nid = r[i_scen]
    if not nid: continue
    txt = r[i_scen_conf] or ""
    # Détection présence du split
    m1 = SPLIT_CAS_1.search(txt)
    m2 = SPLIT_CAS_2.search(txt)
    if not (m1 and m2):
        continue  # pas de split Cas 1/Cas 2 — étape 5 standard
    # Extraction des textes : on coupe en 3 morceaux (avant cas 1, entre cas 1 et 2, après cas 2)
    after_cas1 = txt[m1.end():]
    m2_in_rest = SPLIT_CAS_2.search(after_cas1)
    if not m2_in_rest:
        continue  # robustesse : cas 2 doit être APRÈS cas 1
    cas_1 = after_cas1[:m2_in_rest.start()].strip()
    cas_2 = after_cas1[m2_in_rest.end():].strip()
    # Quel Cas s'applique selon la voie retenue ?
    if voie_ins == "voie_a":
        cas_applied = "cas_1"
        cas_text_applied = cas_1
    elif voie_ins == "voie_b":
        cas_applied = "cas_2"
        cas_text_applied = cas_2
    else:
        continue  # voie non décidée → l'agent traitera en étape 5 standard

    no_scenario = bool(PATTERN_NO_SCENARIO.search(cas_text_applied))

    dispatch[nid] = {
        "has_cas_split": True,
        "voie_applied": voie_ins,
        "cas_applied": cas_applied,
        "cas_text_applied": cas_text_applied,
        "cas_text_other": cas_1 if cas_applied == "cas_2" else cas_2,
        "no_scenario_in_applied_case": no_scenario,
        "status_hint": "Non applicable" if no_scenario else None,
        "audit_note_hint": (
            "Le Cas de figure applicable au rôle retenu en jalon 1 indique « Pas de scenario de test associé » — "
            "le scénario est sans objet dans la configuration produit actuelle."
        ) if no_scenario else None,
    }

(base / "cas-dispatch.json").write_text(json.dumps({
    "voie_ins": voie_ins,
    "scenarios_with_cas_split": len(dispatch),
    "dispatch": dispatch,
}, ensure_ascii=False, indent=2))
print(f"[cas-dispatch] {len(dispatch)} scénarios à Cas 1/Cas 2, voie retenue={voie_ins}")
```

**Conséquence sur étape 5** :

Pour chaque scénario où `dispatch[nid]` existe :

1. Si `status_hint == "Non applicable"` (le Cas applicable indique « Pas de scenario de test associé ») → l'Assessment doit avoir `statut = "Non applicable"` + `audit_note = dispatch[nid].audit_note_hint`. C'est non négociable.

2. Sinon, l'agent évalue le scénario **en se référant exclusivement à `cas_text_applied`**. Il NE doit PAS faire référence aux exigences du Cas non applicable (par exemple : un scénario INS 1.2 en voie B ne doit JAMAIS demander une capture mobile de création — la création n'est pas dans le périmètre de Sunrise).

**Audit étape 4-ter (fail-build si violation)** : si après étape 5, un assessment d'un scénario à Cas split mentionne dans son `ecart`/`recommandation` des éléments propres au Cas non applicable (regex sur les premières phrases distinctives du `cas_text_other`), `exit_code 14`, `reason_code: cas_dispatch_violation`.

```python
# Audit à la fin de l'étape 5 ou avant étape 6
violations = []
for a in items:
    nid = a.get("n_scenario") or ""
    d = dispatch.get(nid)
    if not d: continue
    if d.get("status_hint") == "Non applicable" and a.get("statut") != "Non applicable":
        violations.append({"scenario": nid, "type": "no_scenario_case_not_na",
                          "expected": "Non applicable", "got": a.get("statut")})
    # Détection de fuite Cas non applicable
    other = (d.get("cas_text_other") or "").lower()[:200]
    ecart_low = (a.get("ecart") or "").lower()
    # Heuristique : on extrait les 3-5 mots distinctifs du cas_text_other et on vérifie qu'ils n'apparaissent pas
    # dans l'ecart. Calibration prudente — fail seulement sur matches multiples.
    distinct_words = [w for w in other.split() if len(w) > 6 and w.isalpha()][:8]
    matches = [w for w in distinct_words if w in ecart_low]
    if len(matches) >= 3:
        violations.append({"scenario": nid, "type": "cross_case_leak",
                          "leaked_words": matches[:5]})

if violations:
    # ... write status, exit 14
    pass
```

**Tolérance** : si voie INS n'est pas décidée au moment du build (rare, jalon 1 incomplet), l'étape 4-ter ne produit pas de dispatch, et l'étape 5 standard évalue les deux Cas comme c'était le cas avant V0.5.

## Étape 4.5 — Pré-merge déterministe probe-evidence (V0.5)

**Avant** la construction des assessments : si `probes/exigences-coverage.json` existe, lire la liste des items et **pré-fixer le statut** pour chaque exigence avec un probe_verdict clair.

```bash
python3 - <<'PYEOF'
import json
from pathlib import Path

cov_path = Path.home() / "missions" / "{{ args }}" / "probes" / "exigences-coverage.json"
if not cov_path.is_file():
    print("[probe-evidence-prefill] coverage.json absent — skip")
else:
    cov = json.loads(cov_path.read_text(encoding="utf-8"))
    prefill = {}
    for item in cov.get("items", []):
        eid = item.get("exigence_id")
        ss = item.get("suggested_statut")
        if eid and ss:
            prefill[eid] = {
                "statut_probe": ss,
                "probe_verdict": item.get("probe_verdict"),
                "evidence_files": item.get("evidence_files", []),
                "verdict_hint": item.get("verdict_hint", ""),
                "cat_A": bool(item.get("cat_A", False)),
            }
    out = Path.home() / "missions" / "{{ args }}" / "analysis" / "probe-prefill.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"prefill": prefill}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[probe-evidence-prefill] {len(prefill)} exigences pré-fixées depuis coverage.json")
PYEOF
```

**Règle d'autorité (V0.5 — non négociable)** : si `probe-prefill.json` contient un statut pour exigence X, le statut de l'Assessment X **DOIT** être `prefill[X].statut_probe` — sauf si l'agent a une preuve documentaire qui contredit la preuve UI (alors `Conforme` strict OU note dans `ecart` justifiant le downgrade). Le LLM ne décide PAS d'ignorer un probe-positif/négatif sans citation explicite contraire.

Cf. `skills/ANS/references/rules/probe-evidence.md` § « Discipline ».



### Étape 5 prélude — utilisation des Preuves officielles (V0.4 Lot 19)

Avant de verdicter chaque scénario, **lis les descriptions des
Preuves 1/2/3** dans la source officielle (cols 13/15/17 + 14/16/18
de exigences_official_v1.json). Ces descriptions précisent
**exactement** ce que l'ANS attendrait pour démontrer la conformité.

Exemple INS 1.1 :
- Preuve 1 (INS 1.1.1) : « Démonstration (capture d'écran, vidéo...)
  montrant la création de l'identité dans le cas de figure 1. »
- → Pour l'analyse : chercher dans la doc une référence à la création
  d'identité dans ce cas. Pour le probe : générer une spec qui capture
  la création d'identité (formulaire signup, validation champs, etc.).

Le verdict (Conforme / NC / etc.) repose sur la concordance entre :
1. Ce que l'ANS attend (Preuve 1/2/3 du référentiel)
2. Ce qui est OBSERVÉ (probe + doc)

Si les preuves attendues ne sont pas observées → NC (silence coordonné =
preuve d'absence, cf. absence-as-nc.md). Pas "À confirmer" sauf
incapacité physique de vérifier.

### Pont étape 4-ter → étape 5 — consigne d'utilisation de `cas-dispatch.json`

L'agent qui construit les Assessments (étape 5) DOIT charger `analysis/cas-dispatch.json`. Pour chaque scénario `nid` présent dans `dispatch[]` :

- Si `dispatch[nid].status_hint == "Non applicable"` → produire directement l'Assessment N/A correspondant (`audit_note = dispatch[nid].audit_note_hint`). Aucune autre évaluation à faire.
- Sinon, restreindre l'évaluation au texte `dispatch[nid].cas_text_applied`. Ne pas se référer aux exigences propres à `dispatch[nid].cas_text_other` (le Cas non applicable au rôle retenu).

L'audit étape 4-ter (cf. ci-dessus) vérifie le respect de ces consignes en post-build.

## Étape 5 — Construction de la gap brute (batchée — B5 V0.4 / Lot 3)

**INTERDICTION ABSOLUE V0.4 Lot 15** — Si `analysis/assessments.v1-build.json`
ou `analysis/assessments.final.json` existent déjà, tu DOIS les **supprimer
en début d'étape 5** et régénérer 103 nouveaux Assessments avec les règles
courantes. Tu NE réutilises PAS un artefact `assessments.*-build.json` complet
sous prétexte que :
- « les inputs sont les mêmes » (les RÈGLES ont changé entre versions plugin)
- « ça économiserait des tokens » (le coût d'un verdict obsolète est infini face à un dossier rejeté NB)
- « j'ai juste à re-valider contre les gates » (Triple gate ne sait pas si la doctrine NC/ÀC du moment a été appliquée)

Le seul cas où tu réutilises du travail antérieur :
`analysis/assessments.v1-build.partial.json` (mid-batch resume — cf.
B5 ci-dessous). Jamais le `.json` final. Jamais le `.final.json`.

```bash
# Étape 5 prélude — wipe forcé (Lot 15, étendu V0.5)
rm -f ~/missions/{{ args }}/analysis/assessments.v1-build.json
rm -f ~/missions/{{ args }}/analysis/assessments.final.json
rm -f ~/missions/{{ args }}/analysis/assessments.v2-self-review.json
rm -f ~/missions/{{ args }}/analysis/assessments.v3-merge-jalon-2.json
rm -f ~/missions/{{ args }}/analysis/assessments.pre-render.json   # V0.5 — backup avant Phase B
rm -f ~/missions/{{ args }}/analysis/disagreements.md
rm -f ~/missions/{{ args }}/analysis/merge-trace.json
rm -f ~/missions/{{ args }}/analysis/gap-analysis.xlsx
rm -f ~/missions/{{ args }}/analysis/client-prose-lint.json        # V0.5 — rapport lint
echo "[lot15] wipe forcé des outputs antérieurs — régénération obligatoire"
```

**Stratégie batches (B5)** — Pour éviter de tomber sur le token-limit
(observé sur Sunrise 2026-05-08), tu produis les Assessments **par lots
de 25-30 exigences**. À la fin de chaque lot :

1. Tu écris l'agrégat courant dans `analysis/assessments.v1-build.partial.json`
   au format `{"done": [<n_scenario>...], "assessments": [...], "started_at": "..."}`.
2. Tu logges `[batch N/M] X exigences traitées (Y total)`.

Si `assessments.v1-build.partial.json` existe en début d'étape 5 (cf.
étape 0 resume detection), reprends en partant de `done[]` — ne re-traite
PAS les exigences déjà dans cette liste. Préserve les Assessments existants.

À la fin de l'étape (toutes exigences traitées) :
- Écris la version finale dans `analysis/assessments.v1-build.json`.
- Supprime `assessments.v1-build.partial.json`.

Pour chacun des 103 scénarios (cf. `dmn_exigences_full.md`), produis un Assessment selon `epistemic_discipline.md` règles 1+2+4 + `rules/probe-evidence.md` + `rules/absence-as-nc.md` :

```python
Assessment(
    n_scenario="...",
    profil="...",
    statut="...",  # cf. verdict_taxonomy.md
    severity_numeric=int,  # depuis verdict_taxonomy.md severity scale
    evidence_attempted=True,  # V0.4 OBLIGATOIRE — TRUE si tu as lu les sources pour ce scénario.
                              # FALSE seulement si physiquement impossible (sources absentes ET pas de probe ET pas de UI accessible) — provoque un fail build (cf. Étape 5.5).
    sources_client=[(doc_id, section_or_page), ...],  # V0.4 ≥1 obligatoire si statut ∉ {Non applicable, À confirmer}
    sources_opposables=[clause, ...],
    methode="UI authentifiée + Doc" / "Documentation" / "UI publique" / etc.,
    evidence="texte court qui pointe la preuve concrète",
    ecart="texte court qui décrit ce qui manque",
    recommandation=structured_recommendation(action, sor, system, type, ref, eta),
    confirm_reason=None,  # V0.4 OBLIGATOIRE si statut='À confirmer'. Enum :
                          #   - no_evidence_in_provided_docs  (les docs reçus ne couvrent pas — demander complément client)
                          #   - evidence_ambiguous            (la doc dit que ça existe mais le comportement n'est pas décrit — clarif/probe requise)
                          #   - requirement_out_of_scope      (exigence applicable mais module déclaré hors-scope par client — à acter DP)
                          #   - dp_override_pending           (reclassé À confirmer par règle disagreement post self-review — arbitrage DP requis)
                          # NULL pour tout autre statut.
    audit_note="",  # V0.4 OBLIGATOIRE et ≥10 chars si statut='Non applicable' (justification écrite signée RAQ — Convergence).
)
```

Anti-patterns à éviter (cf. `epistemic_discipline.md`) :
- ❌ Boucle copier-coller sur INS 11-35
- ❌ Confusion énoncé/scénario
- ❌ Citation fabriquée
- ❌ N/A par défaut sans `audit_note` justifiée (sauf override `sub_decision_impact`)
- ❌ V0.4 — `À confirmer` sans `confirm_reason` codée (signal de défaut conservateur sans réflexion — fail build)
- ❌ V0.4 — `evidence_attempted=False` (signal d'absence de lecture — fail build)
- ❌ **V0.4 Lot 13 — `À confirmer` sur silence coordonné (probe + doc tous deux absents)**
  C'est le bug Sunrise 2026-05-09 : l'agent a marqué 30 ÀC alors que la majorité
  étaient des **NC légitimes par triangulation**. Cf. `rules/absence-as-nc.md` :
  si tu as cherché dans le doc + probé l'UI et que c'est absent, le verdict
  EST `Non conforme`. La preuve d'absence est l'absence elle-même.
  - `À confirmer` = « j'ai pas pu vérifier » (pas de probe + pas de doc applicable)
  - `Non conforme` = « j'ai vérifié et c'est absent »
  - Cite chaque silence en `sources_client[]` (`"PRO-460 V20 §X.Y silence sur Z"`,
    `"Probe HCP /signup DOM dump aucun champ Z"`).

- ❌ **V0.4 Lot 26 — Citer une règle RNIV dans le `ecart` qui n'est PAS la règle testée par le scénario**
  C'est le bug Sunrise 2026-05-11 (INS 1.2, 1.3, 2.1) : l'agent invoque « règle 4 (journalisation) » pour justifier le NC d'INS 1.3, alors que le scénario INS 1.3 teste la **règle 1** (validation format DDN). L'énoncé DOIT liste souvent plusieurs règles (ex. « 1, 3, 4 et 17 ») dans son préambule. Le **scénario de conformité** précise toujours la règle effectivement testée via « Vérifie la règle du guide d'implémentation suivante : X ». Tu DOIS aligner ton `ecart` sur la règle X effectivement testée, jamais piocher dans la liste générale de l'énoncé.

  **Règle d'extraction déterministe** à appliquer avant rédaction de chaque `ecart` :

  ```python
  import re
  RULE_FROM_SCENARIO = re.compile(
      r"v[ée]rifie\s+la\s+r[èe]gle.*?:?\s*n?[°o]?\s*(\d+)",
      re.IGNORECASE
  )
  m = RULE_FROM_SCENARIO.search(scenario_text_official)
  if m:
      target_rule = m.group(1)
      # Ton ecart DOIT citer "règle <target_rule>" et décrire son contenu.
      # Si tu cites "règle <autre_numéro>", c'est un bug Lot 26 — audit fail-build.
  ```

Output : `analysis/assessments.v1-build.json` (versionné — finding #16).

## Étape 5.5 — Triple gate validation V0.4 (Lot 1 / A1)

**Avant** d'enchaîner sur le self-review, valide les Assessments contre `schemas/assessment.v1.json`. Trois gates non négociables :

1. **Citation gate** — chaque verdict ∉ {Non applicable, À confirmer} doit avoir `len(sources_client) ≥ 1`.
2. **Reason gate** — chaque verdict 'À confirmer' doit avoir `confirm_reason ∈ enum` (4 valeurs).
3. **Effort gate** — aucun assessment ne doit avoir `evidence_attempted=False`. Si tu n'as pas lu les sources pour un scénario, c'est que tu as raté l'étape 3 (source-index) ou que tu boucles à blanc.

```bash
python3 - <<'PYEOF'
import json
from pathlib import Path

VALID_STATUTS = {"Conforme", "Conforme à étayer", "Partiel", "Non conforme",
                 "Non applicable", "À confirmer"}
CONFIRM_REASONS = {"no_evidence_in_provided_docs", "evidence_ambiguous",
                   "requirement_out_of_scope", "dp_override_pending"}

base = Path.home() / "missions" / "{{ args }}" / "analysis"
ass_path = base / "assessments.v1-build.json"
data = json.loads(ass_path.read_text(encoding="utf-8"))
items = data if isinstance(data, list) else data.get("assessments", [])

errors = []
for i, a in enumerate(items):
    eid = a.get("n_scenario") or f"#{i}"
    statut = a.get("statut")
    if statut not in VALID_STATUTS:
        errors.append(f"{eid}: statut invalide {statut!r}")
        continue
    if "evidence_attempted" not in a:
        errors.append(f"{eid}: champ evidence_attempted manquant (V0.4 requis)")
    elif a["evidence_attempted"] is False:
        errors.append(f"{eid}: evidence_attempted=False (lecture sources non tentée)")
    if statut not in {"Non applicable", "À confirmer"}:
        sc = a.get("sources_client") or []
        if not sc:
            errors.append(f"{eid}: statut={statut!r} sans sources_client (Triple gate #1)")
    if statut == "À confirmer":
        cr = a.get("confirm_reason")
        if cr not in CONFIRM_REASONS:
            errors.append(f"{eid}: À confirmer sans confirm_reason valide (got {cr!r})")
    if statut == "Non applicable":
        an = a.get("audit_note") or ""
        if len(an.strip()) < 10:
            errors.append(f"{eid}: Non applicable sans audit_note ≥10 chars (RAQ Convergence)")

if errors:
    # V0.4 Lot 3 / A6 — unifié sur .last-run-status.json
    out = base / ".last-run-status.json"
    out.write_text(json.dumps({
        "exit_code": 8,
        "reason_code": "triple_gate_violation",
        "stage": "etape_5.5",
        "command": "ans-build",
        "violations_count": len(errors),
        "violations": errors[:50],
        "message_human": f"{len(errors)} violations Triple Gate (V0.4 / A1) — l'agent doit re-attribuer correctement les verdicts avec citations + raisons codées + evidence_attempted=true",
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n✗ TRIPLE GATE — {len(errors)} violations :")
    for e in errors[:20]:
        print(f"  - {e}")
    if len(errors) > 20:
        print(f"  ... +{len(errors)-20}")
    raise SystemExit(1)
print(f"✓ Triple gate — {len(items)} assessments validés (citation + reason + effort)")
PYEOF
```

Si le script exit 1 → corrige les Assessments concernés (ajoute citations, code les raisons, lis vraiment les sources) puis relance la production. **Ne JAMAIS** contourner ce gate en abaissant le `evidence_attempted` à `false` pour faire passer le build.

## Étape 5.6 — Coverage threshold V0.4 (Lot 1 / A1)

Mesure le % de PDFs `docs/` cités au moins une fois dans les Assessments. Seuil ≥ 80 % par défaut (configurable via `intake/project-brief.json` → `tech.docs_coverage_threshold` ; défaut 0.8 si absent).

```bash
python3 - <<'PYEOF'
import json, re
from pathlib import Path

base = Path.home() / "missions" / "{{ args }}"
brief = json.loads((base / "intake" / "project-brief.json").read_text(encoding="utf-8"))
threshold = float(brief.get("tech", {}).get("docs_coverage_threshold", 0.8))

src_path = base / "analysis" / "source-index.json"
ass_path = base / "analysis" / "assessments.v1-build.json"
src = json.loads(src_path.read_text(encoding="utf-8"))
data = json.loads(ass_path.read_text(encoding="utf-8"))
items = data if isinstance(data, list) else data.get("assessments", [])

doc_ids = []
for d in src.get("docs", []):
    did = d.get("doc_id") or d.get("filename")
    if did:
        doc_ids.append(did)

# Extract cited doc_ids from sources_client (first element of each pair)
cited = set()
for a in items:
    for s in a.get("sources_client") or []:
        if isinstance(s, list) and s:
            cited.add(s[0])
        elif isinstance(s, str):
            cited.add(s)

# Match: a doc is "cited" if any sources_client[0] matches its doc_id, filename, or contains its base name
matched = set()
for did in doc_ids:
    base_name = re.sub(r"\s+V\d.*$", "", did).strip()
    for c in cited:
        if did in c or c in did or (base_name and base_name in c):
            matched.add(did)
            break

total = len(doc_ids)
pct = (len(matched) / total) if total else 1.0
uncited = [d for d in doc_ids if d not in matched]
ok = pct >= threshold

report = {
    "threshold": threshold,
    "coverage_pct": round(pct, 3),
    "total_docs": total,
    "cited_docs": len(matched),
    "uncited_docs": uncited,
    "passed": ok,
}
out = base / "analysis" / "coverage-docs.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"[doc-coverage] {len(matched)}/{total} docs cités ({pct:.0%}, seuil {threshold:.0%}) — {'PASS' if ok else 'FAIL'}")
if not ok:
    # V0.4 Lot 3 / A6 — unifié sur .last-run-status.json + exit code 9
    blocked = base / "analysis" / ".last-run-status.json"
    blocked.write_text(json.dumps({
        "exit_code": 9,
        "reason_code": "doc_coverage_below_threshold",
        "stage": "etape_5.6",
        "command": "ans-build",
        "coverage_pct": round(pct, 3),
        "threshold": threshold,
        "uncited_docs": uncited,
        "message_human": f"Seulement {pct:.0%} des PDFs docs/ ont été cités (seuil {threshold:.0%}) — l'agent n'a probablement pas lu : {', '.join(uncited[:5])}{'…' if len(uncited)>5 else ''}",
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    raise SystemExit(9)
PYEOF
```

Si exit 1 → relance étape 3 (subagent ans-doc-reader) sur les docs non cités, puis re-fais étape 5 en t'assurant de citer les docs lus.

**Audit post-build** (V0.5) : à la fin du build, comparer prefill vs assessments :

```bash
python3 - <<'PYEOF'
import json
from pathlib import Path
base = Path.home() / "missions" / "{{ args }}" / "analysis"
prefill = json.loads((base / "probe-prefill.json").read_text(encoding="utf-8"))["prefill"] if (base / "probe-prefill.json").is_file() else {}
ass = json.loads((base / "assessments.v1-build.json").read_text(encoding="utf-8"))
items = ass if isinstance(ass, list) else ass.get("assessments", [])
mismatches = []
for a in items:
    eid = a.get("n_scenario") or a.get("exigence_id")
    pf = prefill.get(eid)
    if pf and a.get("statut") != pf["statut_probe"]:
        mismatches.append({"exigence_id": eid, "expected": pf["statut_probe"], "actual": a.get("statut"), "probe_verdict": pf["probe_verdict"]})
if mismatches:
    out = base / "probe-evidence-audit.json"
    out.write_text(json.dumps({"mismatches": mismatches, "count": len(mismatches)}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"⚠ [probe-evidence-audit] {len(mismatches)} verdicts ignorent le probe-evidence — voir {out}")
else:
    print("✓ [probe-evidence-audit] tous les verdicts probe-evidence ont été honorés")
PYEOF
```

Si mismatches > 0, l'agent DOIT corriger les Assessments concernés.
**V0.4 Lot 25** : si `len(mismatches) > 2` après tolérance voie_b mass-update,
l'audit FAIL le build avec `exit_code: 10`, `reason_code: probe_evidence_ignored`.
La discipline `rules/probe-evidence.md` est non négociable :

- probe `pass` → Conforme à étayer (ou Conforme)
- probe `fail` → Non conforme
- probe `partial` → Partiel
- probe `mobile_pending` → À confirmer (`evidence_ambiguous`)
- probe `non_observable` → À confirmer (`evidence_ambiguous`)

**Anti-pattern Lot 25** : NE PAS confondre `mobile_pending` /
`non_observable` (= déclaration probe « non observable par mon canal »
→ ÀC) avec un silence coordonné (UI + doc tous absents → NC par
Règle 4). La probe a explicitement déclaré son incapacité — pas une
preuve d'absence.

## Étape 5.7 — Audit règle RNIV scénario ↔ règle ecart/sources_opposables (V0.4 Lot 26 + V0.5 R7)

**Cause racine adressée** :
- Bug Sunrise 2026-05-11 (V0.4 Lot 26) — INS 1.2, 1.3, 2.1 ont reçu un `ecart` qui invoque une règle RNIV différente de celle effectivement testée par le scénario.
- Bug Sunrise 2026-05-11 (V0.5 R7) — INS 7.2/7.3/7.4/7.5 ont cité « RNIV règle 5 » dans `sources_opposables[]` alors que le scénario teste règle 17. L'audit V0.4 Lot 26 scrutait uniquement `ecart` et ratait ces cas. INS 43.1/44.1 même pattern (règle 7 cité au lieu de règle 32).
- Bug Sunrise 2026-05-11 (V0.5 R7) — INS 7.1 ecart parle de matricule INS alors que le scénario teste DOB-only. INS 9.4 ecart parle de lockout alors que le scénario teste recherche tolérante au tiret. L'audit Lot 26 ne capture pas ces dérives car le ecart n'invoque AUCUN numéro de règle. Le topic-keyword check V0.5 R7 les capture.

**Audit déterministe à exécuter après l'étape 5 et avant l'étape 6** :

```python
import re, json
from pathlib import Path

RULE_FROM_SCEN = re.compile(r"v[ée]rifie\s+la\s+r[èe]gle.*?:?\s*n?[°o]?\s*(\d+)", re.IGNORECASE)
RULE_FROM_TEXT = re.compile(r"r[èe]gle\s+(?:n[°o]?\s*)?(\d+)", re.IGNORECASE)

# V0.5 R7 — dictionnaire de topic-keywords par règle RNIV.
# Pour chaque règle, les mots-clés caractéristiques de son scope.
# Si un ecart contient des keywords d'une règle Y ≠ règle testée X, → flag.
# Maintenir conservateur : keywords courts, distinctifs, peu ambigus.
RULE_TOPIC_KEYWORDS = {
    "1":  ["valid", "saisi", "distinct", "secu", "format ddn", "format date"],
    "2":  ["rapproch", "doublon", "fusion", "suspicion"],
    "3":  ["libell", "ihm", "fiche patient", "bandeau identit", "affich"],
    "4":  ["journal", "trace", "tracer", "log", "horodat"],
    "5":  ["obligatoire", "à la création", "alimentation requise", "champs requis"],
    "11": ["statut", "récupér", "qualifi"],
    "12": ["modification trait", "modification identit"],
    "16": ["suppression", "désactivation"],
    "17": ["recherch", "antériorit", "neutralisation", "tiret", "apostrophe", "diacrit", "accent"],
    "32": ["édition papier", "datamatrix", "document imprim", "rapport pdf", "édition"],
}
LOCKOUT_KEYWORDS = ["lockout", "verrouill", "tentatives erron", "verrouillage", "verrouillé"]
COMPLEXITY_KEYWORDS = ["complexit", "entropie", "longueur minimale", "majuscule"]

base = Path.home() / "missions" / "<client>" / "analysis"
official = json.loads(Path("skills/ANS/references/exigences_official_v1.json").read_text())
H = official["headers"]
i_scen = H.index("N° scénario")
i_scen_conf = H.index("Scénario de conformité")

# Map: n_scenario → règle testée par le scénario (None si non spécifiée)
scen_rule = {}
for r in official["rows"]:
    nid = r[i_scen]; txt = r[i_scen_conf] or ""
    m = RULE_FROM_SCEN.search(txt)
    scen_rule[nid] = m.group(1) if m else None

ass = json.loads((base / "assessments.v1-build.json").read_text())
items = ass if isinstance(ass, list) else ass.get("assessments", [])

mismatches = []
topic_drifts = []
for a in items:
    nid = a.get("n_scenario") or a.get("exigence_id")
    statut = (a.get("statut") or "").strip()
    if statut not in ("Non conforme", "Partiel", "Conforme à étayer"): continue

    target = scen_rule.get(nid)
    ecart = a.get("ecart") or ""
    sources_opposables = a.get("sources_opposables") or []
    so_text = " ".join(str(s) for s in sources_opposables)
    combined = (ecart + " " + so_text).lower()

    # ───── 1) Rule-number mismatch (V0.4 Lot 26 + V0.5 R7 — scan ecart ET sources_opposables)
    if target:
        cited_in_ecart = set(RULE_FROM_TEXT.findall(ecart))
        cited_in_so = set(RULE_FROM_TEXT.findall(so_text))
        cited_all = cited_in_ecart | cited_in_so
        if cited_all and target not in cited_all:
            mismatches.append({
                "exigence_id": nid,
                "regle_scenario": target,
                "regles_citees_ecart": sorted(cited_in_ecart),
                "regles_citees_sources_opposables": sorted(cited_in_so),
                "ecart_excerpt": ecart[:120],
                "sources_opposables": sources_opposables,
            })

    # ───── 2) Topic-keyword drift (V0.5 R7 — ecart parle du topic d'une AUTRE règle)
    if target and target in RULE_TOPIC_KEYWORDS:
        # Pour chaque AUTRE règle, voir si son topic-keyword est présent dans l'ecart
        target_kws = RULE_TOPIC_KEYWORDS[target]
        for other_rule, other_kws in RULE_TOPIC_KEYWORDS.items():
            if other_rule == target: continue
            other_hits = [kw for kw in other_kws if kw in combined]
            target_hits = [kw for kw in target_kws if kw in combined]
            # Drift si ecart porte sur le topic d'une autre règle ET pas du tout sur le topic de target
            if other_hits and not target_hits:
                topic_drifts.append({
                    "exigence_id": nid,
                    "regle_scenario": target,
                    "regle_topic_detected": other_rule,
                    "keywords_detected": other_hits,
                    "ecart_excerpt": ecart[:120],
                })
                break  # un seul drift par scenario suffit pour flag

    # ───── 3) IEPS 9.x / lockout vs complexity inversion (V0.5 R7 — case spécifique)
    # Si le scénario est IEPS 9.1 (lockout), ecart ne doit pas parler complexité.
    # Si le scénario est IEPS 9.2 (complexity), ecart ne doit pas parler lockout.
    if nid == "IEPS 9.1":
        if any(kw in combined for kw in COMPLEXITY_KEYWORDS) and not any(kw in combined for kw in LOCKOUT_KEYWORDS):
            topic_drifts.append({
                "exigence_id": nid, "regle_scenario": "—",
                "regle_topic_detected": "IEPS 9.2 (complexité MdP)",
                "keywords_detected": [kw for kw in COMPLEXITY_KEYWORDS if kw in combined],
                "ecart_excerpt": ecart[:120],
                "note": "IEPS 9.1 teste le lockout, pas la complexité.",
            })
    if nid == "IEPS 9.2":
        if any(kw in combined for kw in LOCKOUT_KEYWORDS) and not any(kw in combined for kw in COMPLEXITY_KEYWORDS):
            topic_drifts.append({
                "exigence_id": nid, "regle_scenario": "—",
                "regle_topic_detected": "IEPS 9.1 (lockout)",
                "keywords_detected": [kw for kw in LOCKOUT_KEYWORDS if kw in combined],
                "ecart_excerpt": ecart[:120],
                "note": "IEPS 9.2 teste la complexité MdP, pas le lockout.",
            })

(base / "rule-alignment-audit.json").write_text(json.dumps({
    "rule_number_mismatches": mismatches,
    "rule_number_mismatches_count": len(mismatches),
    "topic_drifts": topic_drifts,
    "topic_drifts_count": len(topic_drifts),
}, ensure_ascii=False, indent=2))

total = len(mismatches) + len(topic_drifts)
if total > 2:
    (base / ".last-run-status.json").write_text(json.dumps({
        "exit_code": 11, "reason_code": "rule_misalignment",
        "stage": "etape_5_7", "command": "ans-build",
        "rule_number_mismatches_count": len(mismatches),
        "topic_drifts_count": len(topic_drifts),
        "message_human": (
            f"{len(mismatches)} verdicts citent une règle RNIV différente de la règle testée par le scénario officiel "
            f"+ {len(topic_drifts)} verdicts dont l'ecart porte sur le topic d'une autre règle. "
            f"Re-rédiger ces ecart en alignant sur la règle effectivement ciblée (cf. rule-alignment-audit.json)."
        )
    }, ensure_ascii=False, indent=2))
    raise SystemExit(11)
print(f"✓ Rule alignment audit — {len(mismatches)} rule-number mismatches, {len(topic_drifts)} topic drifts (seuil > 2)")
```

**Tolérance** :
- Audit ignore les `À confirmer` et `Non applicable` (par construction sans citation règle obligatoire).
- Le check rule-number ignore les scénarios dont le champ « Scénario de conformité » n'expose pas explicitement un n° de règle.
- Le topic-keyword check ne s'applique qu'aux règles présentes dans `RULE_TOPIC_KEYWORDS` (10 règles couvertes). Pour étendre, ajouter au dictionnaire.

**Seuil** : `len(mismatches) + len(topic_drifts) > 2` → fail-build (1-2 reste tolérance pour cas borderline). Sinon, audit produit le rapport et l'agent passe à l'étape 6.

## Étape 6 — Self-review (subagent ans-self-reviewer)

Spawn `ans-self-reviewer`. Sortie : `analysis/disagreements.md` + `analysis/assessments.v2-self-review.json`.

## Étape 7 — Merge (V0.4 Lot 24 — l'evidence-backed gagne — V0.5 R8/R9)

→ Voir `skills/ANS/references/rules/disagreement.md` (réécrit Lot 24).

### Étape 7.0 — Collecter tous les overrides DP signés (V0.5 R8)

**Cause racine adressée** : audit Sunrise 2026-05-11 a trouvé 7 actions DP `action: "override"` signées en jalon 2 (PSC 5.1, IEU 1.1, 2.1, 4.1, 9.1, 11.1, 12.1) jamais appliquées au final.json. La cause : le merge ne lisait QUE `verdict_overrides[]` au top-level, pas `dp_decisions.jalon_2.a_confirmer_actions[]`. Idem pour ANN 5.1 reclassée N/A en jalon 3 mais restée NC.

**Avant toute fusion V1 ↔ SR, l'agent collecte trois sources d'overrides** :

```python
import re, json
from pathlib import Path

base = Path.home() / "missions" / "<client>"
brief = json.loads((base / "intake" / "project-brief.json").read_text(encoding="utf-8"))

overrides = {}  # {scenario_id: {verdict, rationale, source, signed_at, signed_by}}

# Source 1 — verdict_overrides[] (top-level, schema V0.4 historique)
for vo in brief.get("verdict_overrides") or []:
    sid = vo.get("exigence_id")
    if not sid: continue
    overrides[sid] = {
        "scenario_id": sid,
        "verdict": vo.get("override_to"),
        "rationale": vo.get("rationale") or "",
        "source": "verdict_overrides",
        "signed_at": vo.get("signed_at"),
        "signed_by": vo.get("signed_by"),
        "v1_verdict": vo.get("v1_verdict"),
    }

# Source 2 — dp_decisions.jalon_2.a_confirmer_actions[] où action == "override"
for ac in (brief.get("dp_decisions") or {}).get("jalon_2", {}).get("a_confirmer_actions") or []:
    if ac.get("action") != "override": continue
    sid = ac.get("exigence_id")
    if not sid: continue
    new_verdict = ac.get("override_verdict")
    if not new_verdict:
        continue  # action override sans verdict cible → ignorer
    # NB : si déjà présent dans overrides via source 1, on garde la source 1 (verdict_overrides)
    # MAIS on warn si les verdicts divergent.
    existing = overrides.get(sid)
    if existing:
        if existing.get("verdict") != new_verdict:
            print(f"[merge] override source mismatch on {sid}: verdict_overrides={existing['verdict']} vs a_confirmer_actions={new_verdict}. verdict_overrides prend la précédence.")
        continue
    overrides[sid] = {
        "scenario_id": sid,
        "verdict": new_verdict,
        "rationale": ac.get("override_rationale") or "",
        "source": "jalon_2.a_confirmer_actions",
        "signed_at": ac.get("signed_at"),
        "signed_by": ac.get("signed_by"),
        "axis": ac.get("axis"),
        "recipient": ac.get("recipient"),
    }

# Source 3 — dp_decisions.jalon_3.dynamic_points_responses[] (pattern-match texte)
# Format attendu : la response text peut mentionner "reclasser <ID> <verdict>"
# Ex. "Canal alternatif retenu — produire note d'audit et reclasser ANN 5.1 N/A audit-noted"
PATTERN_RECLASS = re.compile(
    r"reclasser\s+([A-Za-zÀ-ÿ]+\s+\d+\.\d+)\s+(N/A|Non\s+applicable|NC|Non\s+conforme|Partiel|Conforme(?:\s+à\s+étayer)?|À\s+confirmer)",
    re.IGNORECASE
)
VERDICT_NORMALIZE = {
    "n/a": "Non applicable", "non applicable": "Non applicable",
    "nc": "Non conforme", "non conforme": "Non conforme",
    "partiel": "Partiel",
    "conforme à étayer": "Conforme à étayer",
    "conforme": "Conforme",
    "à confirmer": "À confirmer",
}
for resp in (brief.get("dp_decisions") or {}).get("jalon_3", {}).get("dynamic_points_responses") or []:
    text = resp.get("response") or ""
    for m in PATTERN_RECLASS.finditer(text):
        sid = m.group(1).strip()
        raw_verdict = m.group(2).lower().strip()
        new_verdict = VERDICT_NORMALIZE.get(raw_verdict)
        if not new_verdict: continue
        existing = overrides.get(sid)
        if existing and existing.get("verdict") != new_verdict:
            print(f"[merge] override source mismatch on {sid}: existing={existing['verdict']} vs jalon_3={new_verdict}. jalon_3 prend la précédence (chronologie).")
        overrides[sid] = {
            "scenario_id": sid,
            "verdict": new_verdict,
            "rationale": text,  # texte intégral de la réponse — le plein contexte
            "source": "jalon_3.dynamic_points_responses",
            "point_id": resp.get("point_id"),
            "signed_at": resp.get("responded_at"),
        }

# Trace toutes les sources d'overrides agrégées
(base / "analysis" / "overrides-collected.json").write_text(json.dumps({
    "overrides_count": len(overrides),
    "by_source": {
        src: sum(1 for o in overrides.values() if o.get("source") == src)
        for src in ("verdict_overrides", "jalon_2.a_confirmer_actions", "jalon_3.dynamic_points_responses")
    },
    "overrides": overrides,
}, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"[merge] {len(overrides)} overrides DP collectés depuis 3 sources")
```

### Étape 7.1 — Appliquer les overrides (V0.5 R9 — replace, don't append)

**Cause racine adressée** : audit Sunrise 2026-05-11 a trouvé que les overrides INS 1.2/1.3/1.4/2.1 produisaient des ecart concaténés du type :

```
"Re-verdiction post-audit indépendant 2026-05-11. Le scénario de conformité INS 1.2 teste la règle 1...
[Ecart V1 antérieur conservé pour traçabilité] Absence de processus de rapprochement d'identité..."
```

Résultat : la prose finale contenait à la fois la correction ET le texte V1 erroné. Phase B lisait cette concaténation et était confuse.

**Règle V0.5 R9 — non négociable** : lorsqu'un override est appliqué à un assessment :

1. **`statut`** ← `override.verdict`. Override the V1 verdict completely.
2. **`ecart`** ← `override.rationale` (texte plein de l'override DP, en français QARA). N'ajoute PAS le V1 ecart, ne préfixe PAS « [Ecart V1 antérieur conservé pour traçabilité] ».
3. **`recommandation`** ← si l'override fournit une `recommandation` ou `override_rationale` qui contient des actions, l'utiliser ; sinon, repartir d'une recommandation alignée sur le nouveau verdict (l'agent rédige).
4. **`sources_client[]`** ← conservées du V1 si pertinentes pour le nouveau verdict ; ré-évaluées sinon (ex. override → Non applicable : pas besoin de sources_client).
5. **`audit_note`** ← rempli SEULEMENT si le nouveau verdict est `Non applicable`, alors `audit_note = override.rationale` ou texte dédié.
6. **`confirm_reason`** ← rempli SEULEMENT si le nouveau verdict est `À confirmer`, valeur enum standard.
7. **Tout résidu V1** (ecart V1, recommandation V1, sources V1) → archivé dans `merge-trace.json` sous la clé `merge_trace[scenario_id].v1_snapshot`, jamais dans l'Assessment final.

```python
# Snapshot V1 pour traçabilité avant override
merge_trace = {}

def apply_override(assessment, override):
    sid = assessment["n_scenario"]
    merge_trace[sid] = {
        "v1_snapshot": {
            "statut": assessment.get("statut"),
            "ecart": assessment.get("ecart"),
            "recommandation": assessment.get("recommandation"),
            "sources_client": assessment.get("sources_client"),
            "evidence": assessment.get("evidence"),
        },
        "override_applied": override,
    }
    # Replace fields
    assessment["statut"] = override["verdict"]
    assessment["ecart"] = override["rationale"] or ""
    if override["verdict"] == "Non applicable":
        assessment["audit_note"] = override["rationale"] or ""
        assessment["confirm_reason"] = None
        assessment["sources_client"] = []  # N/A doesn't need primary sources
        assessment["recommandation"] = ""  # cleaned, Phase B will regenerate reco_client minimaliste
    elif override["verdict"] == "À confirmer":
        assessment["confirm_reason"] = "dp_override_pending"  # par défaut, peut être surchargé
        assessment["audit_note"] = ""
        # recommandation : l'agent rédige une action courte alignée sur le verdict ÀC
    else:
        # Conforme / Conforme à étayer / Partiel / Non conforme
        assessment["audit_note"] = ""
        assessment["confirm_reason"] = None
        # sources_client : si l'override pointe vers des preuves spécifiques (engagement DP, doc nouvellement reçu),
        # l'agent peut les ajouter ici. Sinon, conserve les V1 si elles restent pertinentes.
    return assessment
```

### Étape 7.2 — Merger V1 ↔ SR pour les scénarios SANS override

Pour chaque scénario sans entrée dans `overrides[]`, appliquer dans l'ordre la règle V0.4 Lot 24 :

1. **DP override existant** → déjà traité en étape 7.1.
2. **Un seul evidence-backed, l'autre prudent** (V1 OU SR — symétrique) :
   - V1=NC sourcé + SR=ÀC prudent → garde V1
   - V1=ÀC prudent + SR=NC sourcé → garde **SR**
   Pas de reclassement abusif en ÀC.
3. **Les deux evidence-backed, divergents factuellement** → ÀC
   `dp_override_pending` (le DP arbitre).
4. **Aucun evidence-backed** → ÀC + re-trigger étape 5 si possible.

Si V1 == SR (accord), conserve le verdict tel quel.

### Étape 7.3 — Sanity check : tous les overrides signés sont appliqués (V0.5 R8)

```python
final = json.loads((base / "analysis" / "assessments.final.json").read_text())
items = final if isinstance(final, list) else final.get("assessments", [])
by_sid = {a.get("n_scenario"): a for a in items}

not_applied = []
for sid, ov in overrides.items():
    a = by_sid.get(sid)
    if not a:
        not_applied.append({"scenario": sid, "reason": "scenario not in final.json", "override": ov})
        continue
    if a.get("statut") != ov.get("verdict"):
        not_applied.append({
            "scenario": sid,
            "reason": "verdict mismatch",
            "expected": ov.get("verdict"),
            "got": a.get("statut"),
            "override_source": ov.get("source"),
        })

if not_applied:
    (base / "analysis" / ".last-run-status.json").write_text(json.dumps({
        "exit_code": 15, "reason_code": "merge_override_not_applied",
        "stage": "etape_7_3", "command": "ans-build",
        "not_applied_count": len(not_applied),
        "not_applied": not_applied[:20],
        "message_human": f"{len(not_applied)} overrides DP signés n'ont pas été appliqués au final.json. Voir overrides-collected.json + assessments.final.json. Re-lancer étape 7.1.",
    }, ensure_ascii=False, indent=2))
    raise SystemExit(15)
print(f"✓ Merge sanity — {len(overrides)} overrides signés tous appliqués")
```

Re-génère après tout cela :
- `analysis/assessments.final.json` (verdicts finaux post-override + post-merge V1/SR + champs d'audit interne PROPRES, sans concaténation V1)
- `analysis/merge-trace.json` (per-scenario : V1 snapshot + override applied + V1/SR merge decision)
- `analysis/overrides-collected.json` (audit trace : les 3 sources d'overrides agrégées)

**La xlsx n'est PAS générée à l'étape 7.** Elle est différée à l'étape 7.7, après la phase B (rendu prose-client) et son lint.

## Étape 7.5 — Phase B « render for client » (V0.5 — subagent ans-prose-renderer)

**Pourquoi cette étape existe** (cause racine Sunrise 2026-05-11) : les champs d'audit `ecart`, `evidence`, `recommandation` étaient copiés tels quels dans les colonnes 21/22 lues par le RAQ du client. Le retour senior a été « pas compréhensible, faire plus simple, enlever NC par triangulation ». Phase B sépare strictement la prose d'audit (champs internes) de la prose client (`obs_fr` col 21, `reco_client` col 22, `theodo_ops` pour le brief interne uniquement).

→ Voir `agents/ans-prose-renderer.md` pour le contrat complet.

Spawn `ans-prose-renderer` :

```
Tu reçois en input :
- mission_root: ~/missions/{{ args }}
- assessments_path: ~/missions/{{ args }}/analysis/assessments.final.json (post-merge)
- scenarios_path: skills/ANS/references/exigences_official_v1.json
- brief_path: ~/missions/{{ args }}/intake/project-brief.json
- writing_pack_dir: skills/ANS/references/writing_pack
- output_path: ~/missions/{{ args }}/analysis/assessments.final.json (in-place merge des nouveaux champs)

Pour chaque groupe « N° exigence » parent (INS 1, INS 7, INS 11, PSC 1, etc.),
rends obs_fr + reco_client + theodo_ops en suivant strictement le contrat
agents/ans-prose-renderer.md (voix client 2e personne, banned words bannis,
différenciation sibling obligatoire).

Pré-merge backup obligatoire : analysis/assessments.pre-render.json.

Output au main thread : résumé du rendu + groupes traités.
```

## Étape 7.6 — Lint client-prose (V0.5)

**Vérification déterministe** : aucun motif interne plugin ne doit subsister dans `obs_fr` ou `reco_client`. Un seul match → fail-build (exit_code 13, reason_code `client_prose_lint_violation`).

```bash
python3 - <<'PYEOF'
import json, re
from pathlib import Path

base = Path.home() / "missions" / "{{ args }}" / "analysis"
ass = json.loads((base / "assessments.final.json").read_text(encoding="utf-8"))
items = ass if isinstance(ass, list) else ass.get("assessments", [])

BANNED = [
    # Plugin internals
    (r"\bV[12]\b", "plugin-internal-v1-v2"),
    (r"Lot \d+", "plugin-internal-lot-N"),
    (r"\bself-review\b", "plugin-internal-sr"),
    (r"\brationale\b", "plugin-internal-rationale"),
    (r"triangulation", "plugin-internal-triangulation"),
    (r"silence coordonn", "plugin-internal-silence-coordonne"),
    (r"evidence-backed", "plugin-internal-evidence-backed"),
    (r"sub_decision", "plugin-internal-sub-decision"),
    (r"dp_override", "plugin-internal-dp-override"),
    (r"\baudit_note\b", "plugin-internal-audit-note"),
    (r"\bvoie_[ab]\b", "plugin-internal-voie-snake"),
    (r"mass-update", "plugin-internal-mass-update"),
    (r"\bconfirm_reason\b", "plugin-internal-confirm-reason"),
    (r"\bepistemic\b", "plugin-internal-epistemic"),
    # Plugin process
    (r"/ans-", "plugin-process-slash-command"),
    (r"\bplugin theodo", "plugin-process-name"),
    (r"\bétape \d+", "plugin-process-step-N"),
    (r"Triple gate", "plugin-process-triple-gate"),
    (r"reclassée en", "plugin-process-reclasse"),
    (r"post self-review", "plugin-process-post-sr"),
    # Internal Theodo acronyms (with word boundaries)
    (r"\bP[012]\b", "theodo-internal-priority-P0P1P2"),
    (r"\bSRS\b", "theodo-internal-SRS"),
    (r"\bSOP\b", "theodo-internal-SOP"),
    (r"\bRAQ\b", "theodo-internal-RAQ"),
    # Math/jargon
    (r"[∉∈∀∃≥≤]", "math-symbol"),
    # Process narration leakage
    (r"L'agent a", "process-narration-l-agent"),
    (r"cite à tort la règle", "process-narration-cite-a-tort"),
    (r"pioch[ée]e", "process-narration-piochee"),
]
PATTERNS = [(re.compile(p, re.IGNORECASE), name) for p, name in BANNED]

violations = []
for a in items:
    nid = a.get("n_scenario") or "?"
    for field in ("obs_fr", "reco_client"):
        text = a.get(field) or ""
        if not isinstance(text, str):
            continue
        for pat, name in PATTERNS:
            for m in pat.finditer(text):
                violations.append({
                    "n_scenario": nid,
                    "field": field,
                    "pattern": name,
                    "match": text[max(0, m.start()-10):m.end()+10],
                })

out = base / "client-prose-lint.json"
out.write_text(json.dumps({"violations": violations, "count": len(violations)},
                          ensure_ascii=False, indent=2), encoding="utf-8")

if violations:
    status = base / ".last-run-status.json"
    status.write_text(json.dumps({
        "exit_code": 13,
        "reason_code": "client_prose_lint_violation",
        "stage": "etape_7_6",
        "command": "ans-build",
        "violations_count": len(violations),
        "violations_preview": violations[:10],
        "message_human": f"{len(violations)} motifs internes ont fui dans obs_fr / reco_client. Voir client-prose-lint.json. La Phase B (ans-prose-renderer) doit être re-déclenchée sur les scénarios concernés.",
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"✗ CLIENT-PROSE-LINT — {len(violations)} violations détectées")
    for v in violations[:10]:
        print(f"  - {v['n_scenario']} / {v['field']} / {v['pattern']} : « {v['match']} »")
    raise SystemExit(13)
print(f"✓ Client-prose lint — {len(items)} assessments, 0 motif interne dans obs_fr/reco_client")
PYEOF
```

| exit_code | reason_code | Quand |
|---|---|---|
| 13 | client_prose_lint_violation | Au moins un motif banni présent dans obs_fr ou reco_client. La Phase B (étape 7.5) doit relancer sur les scénarios listés. |

**Note importante** : `confirm_reason` et `audit_note` restent légitimes dans les CHAMPS internes JSON et dans les colonnes Theodo extension (cols 29-31 de la xlsx). Le lint ne s'applique QU'à `obs_fr` et `reco_client` — les colonnes que le client lit.

## Étape 7.7 — Format `gap-analysis.xlsx` — V0.5 — TEMPLATE ANS DMN V1.2.2 (réel)

Le fichier DOIT répliquer **EXACTEMENT** les 25 colonnes officielles
de l'onglet « Exigences » du Sheet ANS Convergence (sauvegardé dans
`skills/ANS/references/exigences_official_v1.json`) **+ 6 colonnes
Theodo extension à droite** pour la traçabilité interne.

**Source de vérité** : `exigences_official_v1.json` (téléchargé du
Sheet officiel 2026-05-10). Les 103 lignes du JSON donnent l'**ordre
de lignes exact** et les valeurs des colonnes 1-18 + 23-25 (statiques
du référentiel). L'agent ne remplit QUE les colonnes 19-22 +
extensions Theodo.

**25 colonnes officielles ANS — copie verbatim** :

| # | Colonne | Remplie par |
|---|---|---|
| 1 | `PROFIL` | JSON officiel (col 0) |
| 2 | `N°` | JSON officiel (col 1) — index séquentiel |
| 3 | `ID Section` | JSON officiel (col 2) — INS / IEPS / IEU / PSC / ANN / ApCV / PORT / ADM / RGPD |
| 4 | `Section` | JSON officiel (col 3) |
| 5 | `Bloc` | JSON officiel (col 4) |
| 6 | `Fonction` | JSON officiel (col 5) |
| 7 | `Nature de l'exigence` | JSON officiel (col 6) — EXIGENCE / RECOMMANDATION |
| 8 | `N° exigence` | JSON officiel (col 7) |
| 9 | `Enoncé de l'exigence (DOIT) ou de la préconisation (DEVRAIT)` | JSON officiel (col 8) |
| 10 | `Version` | JSON officiel (col 9) |
| 11 | `N° scénario` | JSON officiel (col 10) |
| 12 | `Scénario de conformité` | JSON officiel (col 11) |
| 13 | `N° preuve 1` | JSON officiel (col 12) — **PRÉSERVER verbatim**, c'est l'identifiant ANS de la preuve attendue |
| 14 | `Preuve 1` | JSON officiel (col 13) — **PRÉSERVER verbatim**, description précise de la preuve attendue (input pour les probes + l'analyse) |
| 15 | `N° preuve 2` | JSON officiel (col 14) — idem (si applicable) |
| 16 | `Preuve 2` | JSON officiel (col 15) — idem (si applicable) |
| 17 | `N° preuve 3` | JSON officiel (col 16) — idem (si applicable) |
| 18 | `Preuve 3` | JSON officiel (col 17) — idem (si applicable) |
| 19 | `Applicable ?` | **L'agent remplit** — `Oui` / `Non` selon profils + rôle INS (Référentiel/Esclave d'identité) + sub_decision_impact |
| 20 | `Conforme ?` | **L'agent remplit** — `Oui` / `Non` / vide (vide = Non applicable ou À confirmer) |
| 21 | `Pourquoi conforme/non conforme ?` | **Phase B remplit** — `obs_fr` produit par `ans-prose-renderer` à l'étape 7.5. 1-2 phrases factuelles, voix client. PAS `ecart` (qui reste interne JSON). |
| 22 | `Reco Theodo HealthTech` | **Phase B remplit** — `reco_client` produit par `ans-prose-renderer` à l'étape 7.5. Impératif, dev-spec, bullets si plusieurs items. PAS `recommandation` (qui reste interne JSON). |
| 23 | `Impact UX ? (OUI/NON)` | **L'agent remplit** — `OUI` si la mise en conformité nécessite un changement UX visible (ajout de champ, écran, parcours), `NON` si purement backend (logs, intégrations, doc) |
| 24 | `Q&A` | **L'agent remplit** — questions ouvertes à poser au client/DP pour lever une ambiguïté (ex. « Les habilitations existantes couvrent-elles le scope `mettre à jour l'INS` ? »). Vide s'il n'y a pas de question. |
| 25 | `EPIC` | **JSON officiel verbatim** (col 24 du JSON) — donnée structurelle du référentiel, pas un output de l'agent. Sert au regroupement roadmap (ex. `CRÉATION DE PATIENT`, `RECHERCHE/FILTRE PATIENT`, `HABILITATION INS`, `TRAÇABILITÉ/JOURNALISATION`). 65/103 scénarios ont une valeur officielle ; les 38 autres restent vides. L'agent NE doit PAS générer de valeur EPIC pour les scénarios où la cellule officielle est vide. |

**6 colonnes Theodo extension** (à droite, traçabilité interne) :

| # | Colonne | Source |
|---|---|---|
| 26 | `Statut détaillé Theodo` | `statut` de l'Assessment (Conforme / Conforme à étayer / Partiel / NC / NA / À confirmer) |
| 27 | `Sév` | `severity_numeric` |
| 28 | `Cat. A` | `cat_A` (✓ si bloquant Convergence) |
| 29 | `confirm_reason` | enum (cf. verdict_taxonomy.md) |
| 30 | `audit_note` | justification N/A (≥10 chars si N/A) |
| 31 | `depends_on` | autres exigences impactées |

**IMPORTANT — colonnes Preuve 1/2/3 (13-18) PRÉSERVÉES verbatim**
depuis le JSON officiel. Ces colonnes décrivent **ce que l'ANS attend
comme preuve pour chaque scénario** (ex. « Démonstration capture d'écran
montrant l'alimentation du champ Nom de naissance »).

L'agent **DOIT** lire ces preuves attendues et :

1. **Pour l'analyse documentaire (étape 3 + 5)** : chercher dans
   `docs/` la trace exacte de la preuve attendue. Si la doc mentionne
   le comportement décrit (en clair ou par implication), évidence
   positive. Si silence + probe négative → NC (cf. absence-as-nc.md).

2. **Pour les probes Playwright (`/ans-probe`)** : générer les specs
   qui produisent **exactement** ces preuves attendues (capture du
   champ tel ou tel, action telle ou telle). Pas de probe générique
   qui teste autre chose.

3. **Pour le verdict (col 19/20/21)** : « Pourquoi conforme/non
   conforme ? » cite explicitement la (les) preuves attendue(s) +
   le statut observé.

Les colonnes 13-18 ne sont **pas modifiées par l'agent** — ce sont
les **specs ANS de la preuve à produire**, pas les preuves
effectivement produites. Le rattachement des captures probes sera
fait à une autre étape (par `/ans-publish` ou opération manuelle).

**Mapping verdict 6-statuts Theodo → colonnes officielles 19/20** :

| Statut Theodo | Col 19 Applicable | Col 20 Conforme |
|---|---|---|
| `Conforme` | Oui | Oui |
| `Conforme à étayer` | Oui | Oui (avec note `Reco` : à étayer par capture) |
| `Partiel` | Oui | Non |
| `Non conforme` | Oui | Non |
| `Non applicable` | Non | (vide) |
| `À confirmer` | (vide) | (vide) + `Pourquoi` cite la cause d'incapacité |

**Ordre des lignes** : strictement l'ordre du JSON officiel (qui est
l'ordre de l'onglet Exigences). Aucun tri secondaire — l'assesseur ANS
lit ligne par ligne dans cet ordre.

**Implémentation Python (référence)** :

```python
import json
from pathlib import Path
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

base = Path.home() / "missions" / "{{ args }}" / "analysis"

# 1) Charger source de vérité officielle
official_path = Path.home() / ".claude" / "plugins" / "cache" / "theodo-ans-local" / "theodo-ans-gap-analysis"
# Trouver la version actuelle (déterminer dynamiquement la plus récente)
versions = sorted([d for d in official_path.iterdir() if d.is_dir()], key=lambda p: p.name, reverse=True)
official_file = versions[0] / "skills" / "ANS" / "references" / "exigences_official_v1.json"
official = json.loads(official_file.read_text(encoding="utf-8"))
HEADERS_OFFICIAL = official["headers"]  # 25 colonnes
ROWS_OFFICIAL = official["rows"]        # 103 lignes verbatim

# 2) Charger les assessments produits étape 5
assessments = json.loads((base / "assessments.final.json").read_text(encoding="utf-8"))
items = assessments if isinstance(assessments, list) else assessments.get("assessments", [])
by_scenario = {a.get("n_scenario"): a for a in items}

# 3) Mapping verdict Theodo → cols officielles 19/20 (V0.4 Lot 27)
# Sémantique : `Applicable ?` est le scope (l'exigence s'applique au système ?),
# pas le verdict final. Un `À confirmer` reste applicable → col 19 = "Oui" et
# col 20 = "À vérifier" pour signaler au sub-NB que le verdict est pendant.
def map_verdict(statut: str) -> tuple[str, str]:
    return {
        "Conforme":          ("Oui", "Oui"),
        "Conforme à étayer": ("Oui", "Oui"),
        "Partiel":           ("Oui", "Non"),
        "Non conforme":      ("Oui", "Non"),
        "Non applicable":    ("Non", ""),
        "À confirmer":       ("Oui", "À vérifier"),
    }.get(statut, ("", ""))

# 4) Construire la xlsx
wb = Workbook()
ws = wb.active
ws.title = "Exigences"

# Headers : 25 officiels + 6 Theodo extension
EXTENSION_HEADERS = ["Statut détaillé Theodo", "Sév", "Cat. A",
                     "confirm_reason", "audit_note", "depends_on"]
ALL_HEADERS = HEADERS_OFFICIAL + EXTENSION_HEADERS
ws.append(ALL_HEADERS)
for c in range(1, len(ALL_HEADERS) + 1):
    cell = ws.cell(row=1, column=c)
    cell.font = Font(bold=True, color="FFFFFF")
    cell.fill = PatternFill("solid", fgColor="0A1F44")
    cell.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)

# Pour chaque ligne du JSON officiel
for row_official in ROWS_OFFICIAL:
    # Pad au cas où la ligne JSON est plus courte que les 25 colonnes
    padded = list(row_official) + [""] * (25 - len(row_official))
    n_scenario = padded[10]  # col 11 = N° scénario
    a = by_scenario.get(n_scenario, {})

    # Cols 19-25 = remplies par l'agent depuis l'assessment
    # V0.5 — cols 21/22 lisent obs_fr/reco_client (Phase B), PAS ecart/recommandation (audit interne).
    applicable, conforme = map_verdict(a.get("statut", ""))
    pourquoi = a.get("obs_fr") or ""    # col 21 — produit par ans-prose-renderer (étape 7.5)
    reco     = a.get("reco_client") or ""  # col 22 — produit par ans-prose-renderer (étape 7.5)
    impact_ux = a.get("impact_ux", "")  # OUI / NON — agent doit le déterminer per exigence
    qa = a.get("q_a", "")               # question(s) ouverte(s) ou vide
    # NB Lot 22 : EPIC vient du JSON officiel (col 24), pas de l'agent.
    # Donc on garde padded[24] tel qu'il est (verbatim).

    # Cols Preuve 1/2/3 (13-18) → PRÉSERVÉES verbatim depuis JSON officiel
    # (ces descriptions sont les specs ANS — input pour probes + analyse,
    # cf. § "colonnes Preuve 1/2/3 PRÉSERVÉES verbatim").
    # Les padded[12..17] gardent leur contenu original.

    # Cols 19-24 = remplies par l'agent
    padded[18] = applicable    # col 19 Applicable ?
    padded[19] = conforme      # col 20 Conforme ?
    padded[20] = pourquoi      # col 21 Pourquoi
    padded[21] = reco          # col 22 Reco Theodo
    padded[22] = impact_ux     # col 23 Impact UX ? (OUI/NON)
    padded[23] = qa            # col 24 Q&A
    # Col 25 EPIC : VERBATIM depuis JSON officiel (Lot 22) — pas touché par l'agent
    # padded[24] reste tel quel (déjà copié depuis row_official)

    # Extension Theodo
    extension = [
        a.get("statut", ""),
        a.get("severity_numeric", ""),
        "✓" if a.get("cat_A") else "",
        a.get("confirm_reason", "") or "",
        a.get("audit_note", "") or "",
        ", ".join(a.get("depends_on", []) or []),
    ]
    ws.append(padded + extension)

# Largeurs (officielles + extension)
widths_official = [10, 5, 9, 28, 24, 30, 14, 12, 70, 8, 14, 60, 12, 30, 12, 30, 12, 30, 12, 12, 60, 60, 10, 30, 22]
widths_extension = [20, 6, 8, 28, 50, 18]
for i, w in enumerate(widths_official + widths_extension, 1):
    ws.column_dimensions[get_column_letter(i)].width = w

# Wrap text sur colonnes longues
for r in range(2, ws.max_row + 1):
    for c in (9, 12, 14, 16, 18, 21, 22, 24, 30):  # libellé, scénario, preuves, pourquoi, reco, Q&A, audit
        ws.cell(row=r, column=c).alignment = Alignment(wrap_text=True, vertical="top")

wb.save(base / "gap-analysis.xlsx")
print(f"[lot18] xlsx générée : {ws.max_row - 1} scénarios × {len(ALL_HEADERS)} colonnes (25 ANS + 6 Theodo)")
```

L'agent peut adapter ce squelette mais DOIT respecter :
1. Source de vérité = `exigences_official_v1.json` (jamais
   dmn_exigences_full.md ni hardcodage de scénarios)
2. 25 colonnes officielles dans l'ordre exact (1=PROFIL... 25=EPIC)
3. **Colonnes Preuve 1/2/3 (13-18) laissées VIDES** — destinées à
   une autre opération
4. Ordre des lignes = ordre du JSON (= ordre du Sheet officiel)
5. 6 colonnes Theodo extension à droite (26-31)

### Anti-pattern Lot 18 — ne plus inventer

```python
# ❌ INTERDIT V0.4 Lot 18 :
# - Hardcoder une liste de scénarios à partir de dmn_exigences_full.md
# - Inventer des sections (SoR, HDS comme exigence ANS, SAVS) qui ne
#   sont pas dans la source officielle
# - Spéculer sur le libellé d'un scénario sans le lire dans le JSON
```

## Étape 8 — Quality threshold check (degenerate detection)

→ Voir `skills/ANS/references/quality_thresholds.md`. Compute multi-criteria heuristic + regression vs previous run. Output frontmatter dans `analysis/coverage.md` :

```
---
degenerate_check:
  triggered: true|false
  criteria_passed: [...]
  diagnostic: "..."
  suggested_action: "..."
---
```

Si `triggered: true` → state machine transition vers `degenerate-blocked` (cf. `run_state_machine.md`).

## Étape 9 — Brief de revue jalon 2

Génère `briefs-revue/jalon-2-gap-brute.md` (≤ 2 pages) avec :

- **Synthèse** : distribution des verdicts, % de NC Cat. A, signaux dégénérés s'il y a lieu.
- **NC Cat. A** : liste avec scenario_id + 1 ligne `obs_fr` (la version client) + lien vers `reco_client` complet.
- **Désaccords URGENTS** : restant `dp_override_pending` (cf. `disagreements.md`).
- **À confirmer prioritaires** : groupés par `confirm_reason` codé.
- **Actions internes Theodo (`theodo_ops`)** — V0.5 — **section nouvelle** : agrège tous les `theodo_ops[]` produits par la Phase B, dédupliqués et triés par fréquence. C'est la liste des tâches PM (probes mobiles, demandes de docs au RAQ, peuplement testing, accès admin) qui n'apparaissent JAMAIS dans la xlsx mais qu'on planifie avant le jalon 2. Format : checklist `- [ ] {action interne}  (impacte X scénarios)`.
- **Questions ouvertes pour le DP** : agrège `q_a` des assessments.
- **Demande validation** : signature DP du jalon 2.

```python
# Pseudocode pour la section theodo_ops du brief
from collections import Counter
all_ops = []
for a in items:
    all_ops.extend(a.get("theodo_ops") or [])
counts = Counter(all_ops)
# Bullets : "- [ ] {op}  (impacte {n} scénarios)"
```

Voir gabarit Sunrise pour la structure d'ensemble.

## Étape 10 — Coverage report

Génère `analysis/coverage.md` avec frontmatter degenerate_check + listing actions par axe (P0 PM client, P0 PM probe, P1 PM clarif intake, P2 extension scope).

## Étape 11 — State transition + status file (V0.4 Lot 3 / A6)

Si pas degenerate : transition `running → jalon-2-pending`.
Si degenerate : transition `running → degenerate-blocked`.

À la fin du build (succès ou degenerate non bloquant), écris
`analysis/.last-run-status.json` :

```bash
python3 - <<'PYEOF'
import json, datetime
from pathlib import Path

base = Path.home() / "missions" / "{{ args }}" / "analysis"
# Lecture du frontmatter degenerate_check de coverage.md (étape 8)
cov = base / "coverage.md"
degenerate = False
if cov.is_file():
    text = cov.read_text(encoding="utf-8", errors="replace")
    if "triggered: true" in text:
        degenerate = True

status = {
    "exit_code": 0,
    "reason_code": "degenerate" if degenerate else "success",
    "stage": "etape_11",
    "command": "ans-build",
    "message_human": (
        "Gap brute construite mais distribution suspecte — vérifier coverage.md"
        if degenerate else
        "Gap brute construite et self-reviewed — prête pour jalon 2"
    ),
    "finished_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
}
(base / ".last-run-status.json").write_text(
    json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8")
PYEOF
```

## Étape 12 — Output au PM

```
Gap brute terminée pour {{ args }}.

Distribution :
- Conforme : X
- Conforme à étayer : X
- Partiel : X
- Non conforme : X (dont X cat. A bloquantes)
- Non applicable : X (dont X mass-update voie B audit-N/A)
- À confirmer : X (cf. coverage.md pour les actions)

Self-review : X désaccords (X % du total) — Y soft / Z hard.
Désaccords HARD restant après merge : X — escalade DP recommandée.

Phase B (rendu prose-client, V0.5) :
- obs_fr produits : N / 103
- reco_client produits : N / 103
- theodo_ops agrégés : K tâches internes (cf. brief)
- Client-prose lint : ✓ aucun motif interne ou ✗ N violations (cf. client-prose-lint.json)

Degenerate check : <ok|triggered>
{si triggered : criteria + diagnostic + action suggérée}

Lis briefs-revue/jalon-2-gap-brute.md, prépare la réunion DP.
État mission : <jalon-2-pending|degenerate-blocked>.
```

## Discipline (rappel)

- Aucune Assessment sans source primaire client + référence opposable (sauf À confirmer / Non applicable)
- Self-review obligatoire — pas de skip
- Si subagent échoue 2 fois consécutivement → arrête et préviens le PM
- Lockfile relâché en EXIT trap (toujours, même si erreur)
