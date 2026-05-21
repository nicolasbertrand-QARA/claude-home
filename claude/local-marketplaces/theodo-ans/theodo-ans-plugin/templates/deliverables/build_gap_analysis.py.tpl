#!/usr/bin/env python3
"""
DMN V1.2.2 Gap Analysis builder — paramétrable par client.
Template du plugin theodo-ans-gap-analysis.

Usage :
    python build_gap_analysis.py <client-folder>

Le folder client doit contenir :
    intake/decisions.md          # profil applicabilité (Voie A/B, profils)
    intake/fiche-projet.md       # contexte client
    docs/                        # PDFs/SOPs client
    probes/reports/artifacts/    # captures UI Playwright
    analysis/source-index.json   # produit par ans-doc-reader
    analysis/assessments.json    # produit par /ans-build (entrées Assessment)

Sortie :
    analysis/gap-analysis.xlsx
    analysis/coverage.md

Discipline (epistemic_discipline.md A+B+D obligatoire) :
- Toute Assessment a sources_client + sources_opposables (sauf À confirmer / N/A)
- Statut par défaut : À confirmer si evidence ambigüe
- Self-review obligatoire avant émission XLSX final
"""

import json
import os
import sys
from pathlib import Path
from typing import Optional

import openpyxl
from openpyxl.styles import Alignment, Font, PatternFill

# ---------------------------------------------------------------------------
# Configuration paramétrable
# ---------------------------------------------------------------------------

REFERENTIEL_SRC = os.environ.get(
    "ANS_REFERENTIEL_SRC",
    "/Users/nicolasbertrand/Downloads/Exigences_referentiel_FR_DMN_V1.2.2_1_(2) (1).xlsx",
)

# V0.5 — référence DMN markdown (parsée pour libellé + catégorie + type DOIT/DEVRAIT)
DMN_REF_MD = os.environ.get(
    "ANS_DMN_REF_MD",
    str(Path.home() / ".claude" / "plugins" / "cache" / "theodo-ans-local"
        / "theodo-ans-gap-analysis" / "0.3.0" / "skills" / "ANS" / "references"
        / "dmn_exigences_full.md"),
)


def parse_dmn_ref() -> dict:
    """Parse dmn_exigences_full.md → {exigence_id: {libelle, categorie, type}}.

    Format markdown attendu :
        - **INS 1** [profils] — _Catégorie > Sous-cat_
          Le Système DOIT ... [body multi-ligne]
          *Scénarios: INS 1.1, INS 1.2*
    """
    import re
    p = Path(DMN_REF_MD)
    if not p.is_file():
        return {}
    text = p.read_text(encoding="utf-8")
    header_re = re.compile(r"^\s*-\s*\*\*([A-Z]+\s+\d+(?:\.\d+)?)\*\*\s*\[([^\]]+)\]\s*—\s*_([^_]+)_")
    scenarios_re = re.compile(r"\*Sc[eé]narios?:\s*([^*]+)\*")
    out = {}
    current = None

    def flush():
        if current is None:
            return
        body = " ".join(l.strip() for l in current.pop("body_lines", [])).strip()
        body = re.sub(r"\s+", " ", body)
        current["libelle"] = body
        has_doit = bool(re.search(r"\bDOIT\b", body))
        has_devrait = bool(re.search(r"\bDEVRAIT\b", body))
        current["type"] = (
            "mixte" if has_doit and has_devrait
            else "DOIT" if has_doit
            else "DEVRAIT" if has_devrait else "—"
        )
        out[current.pop("_id")] = current

    for line in text.splitlines():
        m = header_re.match(line)
        if m:
            flush()
            current = {
                "_id": m.group(1).strip(),
                "categorie": m.group(3).strip(),
                "body_lines": [],
            }
            continue
        if current is None:
            continue
        sm = scenarios_re.search(line)
        if sm:
            continue
        stripped = line.strip()
        if not stripped:
            flush()
            current = None
            continue
        current["body_lines"].append(stripped)
    flush()
    return out


def dmn_lookup(table: dict, n_scenario: str, exigence_id: str) -> dict:
    """Résout l'entrée DMN : exigence_id direct, sinon parent du n_scenario."""
    import re
    if exigence_id and exigence_id in table:
        return table[exigence_id]
    if n_scenario:
        if n_scenario in table:
            return table[n_scenario]
        m = re.match(r"^([A-Z]+\s+\d+)", n_scenario)
        if m and m.group(1) in table:
            return table[m.group(1)]
    return {}

# Profils ANS DMN — mapping standard
PROFILS = [
    "Général",
    "Référentiel d'identités",
    "Référentiel d'identités hors Etablissement de Santé",
    "Référentiel d'identités en Etablissement de Santé",
    "Stockage de copies de titres d'identités",
    "Accès Professionnel",
    "Accès Usager",
    "Accès Usager - ApCV",
]

COLOR = {
    "Conforme":          "C6EFCE",
    "Conforme à étayer": "DAEEF3",
    "Partiel":           "FFEB9C",
    "Non conforme":      "FFC7CE",
    "Non applicable":    "D9D9D9",
    "À confirmer":       "BDD7EE",
}

# ---------------------------------------------------------------------------
# Lecture de la configuration client
# ---------------------------------------------------------------------------


def load_client_config(client_dir: Path) -> dict:
    """Lit intake/decisions.md pour extraire profil applicabilité + Voie INS."""

    decisions_path = client_dir / "intake" / "decisions.md"
    if not decisions_path.exists():
        sys.exit(
            f"ÉCHEC : {decisions_path} manquant. La mission ne peut pas être analysée"
            " sans la décision DP du jalon 1."
        )

    text = decisions_path.read_text()

    # Parse simple — la structure de decisions.md est conventionnelle
    profils_applicable = {}
    for line in text.split("\n"):
        line_lower = line.lower()
        for profil in PROFILS:
            if profil.lower() in line_lower:
                if "[x]" in line_lower or "✓" in line:
                    profils_applicable[profil] = True
                elif "[ ]" in line_lower:
                    profils_applicable[profil] = False

    # Profil Général toujours applicable
    profils_applicable["Général"] = True

    voie_ins = "Voie A"  # default conservateur
    if "voie b" in text.lower() or "voie_b" in text.lower():
        voie_ins = "Voie B"

    pathway = "DMN nom de marque"  # default
    pathway_path = client_dir / "intake" / "pathway-decision.md"
    if pathway_path.exists():
        pathway_text = pathway_path.read_text().lower()
        for p in ["pecan", "pect", "ligne générique", "mes referencement", "ségur"]:
            if p in pathway_text:
                pathway = p.upper()
                break

    return {
        "profils_applicable": profils_applicable,
        "voie_ins": voie_ins,
        "pathway": pathway,
    }


def load_assessments(client_dir: Path) -> dict:
    """Lit analysis/assessments.json — produit par /ans-build."""

    path = client_dir / "analysis" / "assessments.json"
    if not path.exists():
        sys.exit(
            f"ÉCHEC : {path} manquant. Lance d'abord /ans-build pour produire les"
            " Assessments."
        )

    return json.loads(path.read_text())


# ---------------------------------------------------------------------------
# Validation epistemic_discipline.md (règles 1+2)
# ---------------------------------------------------------------------------


def validate_assessment(assessment: dict) -> Optional[str]:
    """Retourne None si OK, sinon un message d'erreur."""

    statut = assessment.get("statut")
    if statut not in COLOR:
        return f"Statut invalide : {statut}"

    if statut in ("Non applicable", "À confirmer"):
        return None  # pas de citation requise pour ces 2 statuts

    sources_client = assessment.get("sources_client", [])
    sources_opposables = assessment.get("sources_opposables", [])

    if not sources_client:
        return f"Statut '{statut}' sans source client — doit être 'À confirmer'"

    if not sources_opposables:
        return f"Statut '{statut}' sans référence opposable — doit être 'À confirmer'"

    return None


def detect_duplications(assessments: dict) -> list[tuple[str, str]]:
    """Retourne les paires de scénarios qui ont evidence + ecart + recommandation
    identiques (signal de boucle copier-coller, anti-pattern epistemic_discipline.md)."""

    seen = {}
    duplications = []
    for n, a in assessments.items():
        signature = (
            a.get("evidence", ""),
            a.get("ecart", ""),
            a.get("recommandation", ""),
        )
        if signature == ("", "", ""):
            continue  # ignore les vides
        if signature in seen:
            duplications.append((seen[signature], n))
        else:
            seen[signature] = n
    return duplications


# ---------------------------------------------------------------------------
# Construction XLSX
# ---------------------------------------------------------------------------


def get_assessment(n_scenario: str, profil: str, config: dict, assessments: dict) -> tuple:
    """Retourne (statut, methode, evidence, ecart, recommandation, sources_client_str,
    sources_opposables_str, disagreement)."""

    profil_app = config["profils_applicable"].get(profil, False)

    if not profil_app:
        return (
            "Non applicable",
            "Documentation",
            f"Profil '{profil}' non applicable au périmètre client (cf. intake/decisions.md).",
            "—",
            "Marquer 'Non applicable' dans Convergence avec justification écrite signée RAQ.",
            "",
            "",
            "",
        )

    a = assessments.get(n_scenario)
    if not a:
        # Scénario non couvert par /ans-build — défaut conservateur
        return (
            "À confirmer",
            "Documentation",
            "Pas d'évaluation produite par /ans-build pour ce scénario.",
            "À examiner manuellement avant remise du pré-kit.",
            "À documenter par le PM.",
            "",
            "",
            "",
        )

    # Validation
    error = validate_assessment(a)
    if error:
        # Force À confirmer si validation échoue (épistémique défaut)
        return (
            "À confirmer",
            a.get("methode", "Documentation"),
            f"[Validation échouée : {error}] " + a.get("evidence", ""),
            a.get("ecart", ""),
            a.get("recommandation", ""),
            "; ".join(f"{d}, {p}" for d, p in a.get("sources_client", [])),
            "; ".join(a.get("sources_opposables", [])),
            "",
        )

    sources_client_str = "; ".join(f"{d}, {p}" for d, p in a.get("sources_client", []))
    sources_opposables_str = "; ".join(a.get("sources_opposables", []))

    return (
        a["statut"],
        a.get("methode", "Documentation"),
        a.get("evidence", ""),
        a.get("ecart", ""),
        a.get("recommandation", ""),
        sources_client_str,
        sources_opposables_str,
        a.get("disagreement", ""),
    )


def build_xlsx(client_dir: Path, config: dict, assessments: dict) -> dict:
    """Construit le XLSX final dans analysis/gap-analysis.xlsx. Retourne les counters."""

    src_wb = openpyxl.load_workbook(REFERENTIEL_SRC, data_only=True)
    src_ws = src_wb["Exigences"]

    dst_wb = openpyxl.Workbook()
    cov = dst_wb.active
    cov.title = "Synthèse"
    ws = dst_wb.create_sheet("Analyse des écarts")

    header_row = list(next(src_ws.iter_rows(values_only=True)))
    new_cols = [
        "Applicabilité",
        "Statut",
        "Méthode de vérification",
        "Preuve recueillie / Source",
        "Écart identifié",
        "Recommandation",
        "Sources primaires client",
        "Références opposables",
        "Désaccord self-review",
    ]
    full_header = header_row + new_cols
    for c_i, val in enumerate(full_header, 1):
        c = ws.cell(row=1, column=c_i, value=val)
        c.font = Font(bold=True, color="FFFFFF")
        c.fill = PatternFill("solid", fgColor="305496")
        c.alignment = Alignment(wrap_text=True, vertical="top", horizontal="center")

    counters = {k: 0 for k in COLOR}

    for r_i, row in enumerate(src_ws.iter_rows(min_row=2, values_only=True), start=2):
        if not any(row):
            continue
        profil = row[0]
        n_scenario = row[10]
        (
            statut,
            methode,
            evidence,
            ecart,
            reco,
            srcs_c,
            srcs_o,
            disagreement,
        ) = get_assessment(n_scenario, profil, config, assessments)
        applicabilite = (
            "Applicable" if config["profils_applicable"].get(profil, False) else "Non applicable (profil)"
        )
        counters[statut] = counters.get(statut, 0) + 1

        full_row = list(row) + [
            applicabilite,
            statut,
            methode,
            evidence,
            ecart,
            reco,
            srcs_c,
            srcs_o,
            disagreement,
        ]
        for c_i, val in enumerate(full_row, 1):
            c = ws.cell(row=r_i, column=c_i, value=val)
            c.alignment = Alignment(wrap_text=True, vertical="top")
            if c_i == len(row) + 2:  # Statut
                c.fill = PatternFill("solid", fgColor=COLOR.get(statut, "FFFFFF"))
                c.font = Font(bold=True)

    widths = [13, 5, 8, 22, 22, 25, 12, 12, 45, 8, 12, 45, 12, 35, 12, 25, 12, 25, 14, 14, 16, 45, 45, 60, 35, 35, 18]
    for i, w in enumerate(widths[:len(full_header)], 1):
        ws.column_dimensions[openpyxl.utils.get_column_letter(i)].width = w
    ws.row_dimensions[1].height = 40
    ws.freeze_panes = "A2"

    # Cover sheet
    write_cover_sheet(cov, client_dir, config, counters)

    out_path = client_dir / "analysis" / "gap-analysis.xlsx"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    dst_wb.save(out_path)
    print(f"Wrote {out_path}")

    return counters


def write_cover_sheet(cov, client_dir: Path, config: dict, counters: dict) -> None:
    """Écrit la synthèse de couverture sur l'onglet 'Synthèse'."""

    cov["A1"] = f"Gap analysis DMN V1.2.2 — {client_dir.name}"
    cov["A1"].font = Font(size=16, bold=True)

    cov["A3"] = "Date :"
    cov["B3"] = "auto"
    cov["A4"] = "Pathway visé :"
    cov["B4"] = config.get("pathway", "?")
    cov["A5"] = "Voie INS :"
    cov["B5"] = config.get("voie_ins", "?")

    cov["A7"] = "Profils applicables"
    cov["A7"].font = Font(bold=True, size=12)
    r = 8
    for p, app in config["profils_applicable"].items():
        cov.cell(row=r, column=1, value=p)
        cov.cell(row=r, column=2, value="Applicable" if app else "Non applicable")
        if app:
            cov.cell(row=r, column=2).fill = PatternFill("solid", fgColor=COLOR["Conforme"])
        else:
            cov.cell(row=r, column=2).fill = PatternFill("solid", fgColor=COLOR["Non applicable"])
        r += 1

    r += 2
    cov.cell(row=r, column=1, value="Synthèse statut")
    cov.cell(row=r, column=1).font = Font(bold=True, size=12)
    r += 1
    total = sum(counters.values())
    for st in ["Conforme", "Conforme à étayer", "Partiel", "Non conforme", "Non applicable", "À confirmer"]:
        n = counters.get(st, 0)
        cov.cell(row=r, column=1, value=st)
        cov.cell(row=r, column=2, value=n)
        cov.cell(row=r, column=3, value=f"{(n / total * 100):.0f}%" if total else "0%")
        cov.cell(row=r, column=1).fill = PatternFill("solid", fgColor=COLOR.get(st, "FFFFFF"))
        r += 1
    cov.cell(row=r, column=1, value="Total")
    cov.cell(row=r, column=2, value=total)
    cov.cell(row=r, column=1).font = Font(bold=True)

    cov.column_dimensions["A"].width = 60
    cov.column_dimensions["B"].width = 18
    cov.column_dimensions["C"].width = 60


def write_coverage_md(client_dir: Path, assessments: dict, counters: dict) -> None:
    """Écrit analysis/coverage.md listant les actions par priorité."""

    a_confirmer = [n for n, a in assessments.items() if a.get("statut") == "À confirmer"]
    nc_cat_a = [n for n, a in assessments.items() if a.get("statut") == "Non conforme" and a.get("category") == "A"]

    out = client_dir / "analysis" / "coverage.md"
    with out.open("w") as f:
        f.write(f"# Coverage gap — {client_dir.name}\n\n")
        f.write("## Synthèse\n\n")
        for st, n in counters.items():
            f.write(f"- {st} : {n}\n")
        f.write(f"\n## Action P0 PM — `À confirmer` à résoudre ({len(a_confirmer)} items)\n\n")
        for n in a_confirmer:
            f.write(f"- {n} : {assessments[n].get('ecart', 'à clarifier')}\n")
        f.write(f"\n## NC cat. A bloquantes ({len(nc_cat_a)} items)\n\n")
        for n in nc_cat_a:
            f.write(f"- {n} : {assessments[n].get('ecart', '')}\n")
    print(f"Wrote {out}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main(client_dir: Path) -> None:
    config = load_client_config(client_dir)
    assessments = load_assessments(client_dir)

    duplications = detect_duplications(assessments)
    if duplications:
        print(f"⚠ {len(duplications)} duplications détectées (anti-pattern boucle copier-coller) :")
        for a, b in duplications[:10]:
            print(f"  {a} ≡ {b}")
        print("Veuillez réécrire les Assessments concernés (chaque scénario a sa logique propre).")

    counters = build_xlsx(client_dir, config, assessments)
    write_coverage_md(client_dir, assessments, counters)

    total = sum(counters.values())
    print("Distribution :")
    for k, v in counters.items():
        print(f"  {k} : {v} ({(v / total * 100):.0f}%)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("Usage: python build_gap_analysis.py <client-folder>")
    client_path = Path(sys.argv[1]).expanduser().resolve()
    if not client_path.exists():
        sys.exit(f"Folder client introuvable : {client_path}")
    main(client_path)
