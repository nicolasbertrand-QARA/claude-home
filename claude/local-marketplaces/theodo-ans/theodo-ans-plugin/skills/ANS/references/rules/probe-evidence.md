# Rule — Probe Evidence (V0.4 Lot 25 — règle stricte autoritaire)

**Applies to** : `/ans-build`, `/ans-self-review` (incl. `ans-self-reviewer` subagent).

## Principe non négociable

Quand `probes/exigences-coverage.json` contient un verdict pour une
exigence, **ce verdict EST AUTORITAIRE**. La probe a observé l'UI prod-like,
capturé des screenshots + JSON, et constitue une **source primaire client
au sens Q9-A** (cf. `epistemic_discipline.md`). Le `/ans-build` étape 4.5
écrit `analysis/probe-prefill.json` à partir de ce coverage — ce fichier
est le contrat liant probe → verdict assessment.

**Tu ne dois JAMAIS downgrader, upgrader, ou ignorer un probe verdict
clair sans citer dans `ecart` une evidence documentaire contraire
spécifique** (et c'est un cas rare).

## Mapping autoritaire (sans exception)

| Probe verdict | Statut Assessment OBLIGATOIRE | Sémantique |
|---|---|---|
| `pass` ✅ | `Conforme à étayer` (par défaut) ou `Conforme` (si doc QMS confirme aussi) | Probe a vu le comportement requis |
| `fail` ❌ | `Non conforme` (Cat A si Convergence-blocking) | Probe a vu l'absence ou le non-respect |
| `partial` 🟡 | `Partiel` | Probe a vu une partie seulement |
| `mobile_pending` ⏳ | `À confirmer` + `confirm_reason: evidence_ambiguous` | Probe HCP ne peut pas observer ce scénario, capture mobile prévue mais pas reçue. **PAS DE NC**. |
| `non_observable` ❓ | `À confirmer` + `confirm_reason: evidence_ambiguous` | Comportement backend pur, non observable par UI. **PAS DE NC** sauf si doc explicite. |

## Anti-patterns observés Sunrise 2026-05-11 (run #69/70)

### ❌ Pattern A : downgrader un probe positif/négatif en À confirmer

```
[IEPS 9.1] probe=pass     attendu=Conforme à étayer  → actual=À confirmer  ❌
[INS 7.1]  probe=fail     attendu=Non conforme       → actual=À confirmer  ❌
[IEPS 9.2] probe=partial  attendu=Partiel            → actual=À confirmer  ❌
```

Cause : V1 paresseux ignore le probe et flag ÀC sur silence doc.
Correction : le probe verdict gagne. Si probe=`fail` → Assessment NC.
La doc silente NE downgrade PAS un probe-positif/négatif.

### ❌ Pattern B : upgrader un mobile_pending / non_observable en NC

```
[IEU 5.1]  probe=mobile_pending  attendu=À confirmer  → actual=Non conforme       ❌
[INS 3.1]  probe=non_observable  attendu=À confirmer  → actual=Non conforme       ❌
[PSC 5.1]  probe=non_observable  attendu=À confirmer  → actual=Conforme à étayer  ❌
```

Cause : Lot 13 (silence coordonné = NC) appliqué là où il ne devrait
pas — `mobile_pending` et `non_observable` sont des DÉCLARATIONS
EXPLICITES de la probe que le canal observation choisi ne permet pas
de conclure. Ce n'est PAS un silence coordonné (qui présuppose qu'on
a CHERCHÉ partout). Le scénario reste légitimement à observer côté
mobile ou backend → ÀC.

**Distinction clé** :
- **Silence coordonné** (= NC par Règle 4) : UI probable observée +
  doc probable lue + élément absent des deux → preuve d'absence.
- **Non observable par cette probe** (= ÀC) : la probe elle-même
  déclare « ce scénario ne peut pas être conclu par mon canal ». Pas
  encore investigué — pas une preuve d'absence.

## Étape 4.5 du build — audit obligatoire (V0.4 Lot 25)

Après écriture de `assessments.v1-build.json`, l'agent **DOIT** exécuter
l'audit déterministe :

```python
import json
from pathlib import Path
base = Path.home() / "missions" / "<client>" / "analysis"
prefill = json.loads((base / "probe-prefill.json").read_text()).get("prefill", {})
ass = json.loads((base / "assessments.v1-build.json").read_text())
items = ass if isinstance(ass, list) else ass.get("assessments", [])
by_id = {a["n_scenario"]: a for a in items}

mismatches = []
for eid, p in prefill.items():
    a = by_id.get(eid)
    if not a: continue
    expected = p["statut_probe"]
    actual = a["statut"]
    if expected == actual: continue
    # Tolérance : sub_decision_impact mass-update (voie_b → NA) acceptable
    if actual == "Non applicable" and (
        "esclave d'identité" in (a.get("audit_note", "") or "").lower()
        or "voie_b" in (a.get("audit_note", "") or "").lower()
    ): continue
    mismatches.append({"exigence_id": eid, "expected": expected, "actual": actual,
                       "probe_verdict": p["probe_verdict"]})

(base / "probe-evidence-audit.json").write_text(json.dumps(
    {"mismatches": mismatches, "count": len(mismatches)},
    ensure_ascii=False, indent=2))

if len(mismatches) > 2:
    # FAIL build : trop de probe-verdicts ignorés
    (base / ".last-run-status.json").write_text(json.dumps({
        "exit_code": 10, "reason_code": "probe_evidence_ignored",
        "stage": "etape_4_5", "command": "ans-build",
        "mismatches_count": len(mismatches),
        "message_human": f"{len(mismatches)} verdicts assessment ne respectent pas le probe verdict autoritaire (cf. probe-evidence-audit.json). L'agent doit re-attribuer ces verdicts selon le mapping de rules/probe-evidence.md avant que le build ne soit finalisé.",
    }, ensure_ascii=False, indent=2))
    raise SystemExit(10)
```

**Tolérance unique** : si `actual = Non applicable` ET la justification
mentionne explicitement « Esclave d'identité » / `voie_b` (= mass-update
sub_decision_impact), c'est acceptable. Sinon, mismatch = bug à corriger.

## Discipline résumée

1. La probe est autoritaire. Ses verdicts sont **non négociables**.
2. `pass`, `fail`, `partial` → statut Assessment correspondant
   obligatoire (mapping ci-dessus).
3. `mobile_pending`, `non_observable` → `À confirmer` obligatoire, avec
   `confirm_reason: evidence_ambiguous`. NE PAS confondre avec silence
   coordonné (qui ferait NC).
4. Audit étape 4.5 fail-build si > 2 mismatches non-excusés.

## Cas limite : doc client confirme l'inverse

Très rare : la doc cite explicitement le comportement contraire à ce
que la probe a observé (probe-positif mais doc-négatif, ou inverse).
Dans ce cas l'agent peut diverger du mapping ci-dessus À CONDITION
de :
- citer la doc précise dans `sources_client`,
- décrire l'incohérence dans `ecart`,
- escalader au DP en marquant `confirm_reason: dp_override_pending`.

Hors ce cas (qui devrait survenir 1-2× sur 103), respect strict du
mapping.
