#!/usr/bin/env python3
"""Extract gold exemplars from Okeiro + LibreView reference sheets.

Sources:
  okeiro_full.json   — Okeiro (Done ✅, French only)
  libreview_full.json — LibreView (rows with EN/FR == "FR", Done ✅ implicit)

Output:
  ../exemplars.json — flat list of usable gold exemplars indexed by scenario_id
"""
import json, re
from pathlib import Path

HERE = Path(__file__).parent
OUT = HERE.parent / "exemplars.json"


def strip_keyring_prefix(s: str) -> str:
    """gws prepends 'Using keyring backend: keyring\\n' before JSON."""
    s = s.lstrip()
    if s.startswith("Using keyring backend"):
        s = s.split("\n", 1)[1]
    return s


def load_sheet(path: Path):
    raw = strip_keyring_prefix(path.read_text(encoding="utf-8"))
    data = json.loads(raw)
    return data["values"]


def is_blank(v):
    return v is None or v == "" or (isinstance(v, str) and v.strip() == "")


def extract_okeiro(rows):
    """Okeiro columns (0-indexed):
       0 PROFIL, 1 N°, 2 ID Section, 3 Section, 4 Bloc, 5 Fonction, 6 Nature,
       7 N° exigence, 8 Enoncé, 9 Version, 10 N° scénario, 11 Scénario,
       12 N° preuve 1, 13 Preuve 1, 14 N° preuve 2, 15 Preuve 2,
       16 N° preuve 3, 17 Preuve 3,
       18 Applicable, 19 Pourquoi pas applicable, 20 Conforme,
       21 Reco Theodo, 22 Impact UX, 23 Whimsical,
       24 Question Okeiro, 25 Réponse Theodo, 26 Status
    """
    out = []
    for r in rows[1:]:  # skip header
        if len(r) < 21:
            continue
        scenario_id = r[10] if len(r) > 10 else ""
        if not scenario_id or not re.match(r"^[A-Za-z]+\s+\d+\.\d+$", scenario_id):
            continue
        status = r[26] if len(r) > 26 else ""
        if "Done" not in status:
            continue
        reco = r[21] if len(r) > 21 else ""
        if is_blank(reco) or reco.strip().upper() in ("NA", "N/A", "SAME AS ABOVE"):
            # Drop empty / placeholder recos — they don't teach style
            continue
        out.append({
            "source": "okeiro",
            "scenario_id": scenario_id,
            "profil": r[0] if len(r) > 0 else "",
            "id_section": r[2] if len(r) > 2 else "",
            "section": r[3] if len(r) > 3 else "",
            "fonction": r[5] if len(r) > 5 else "",
            "n_exigence": r[7] if len(r) > 7 else "",
            "enonce": r[8] if len(r) > 8 else "",
            "scenario_text": r[11] if len(r) > 11 else "",
            "preuve_1_text": r[13] if len(r) > 13 else "",
            "applicable": r[18] if len(r) > 18 else "",
            "non_applicable_reason": r[19] if len(r) > 19 and r[19] != "NA" else "",
            "conforme": r[20] if len(r) > 20 else "",
            "gold_reco_unified": reco.strip(),
            "impact_ux": r[22] if len(r) > 22 else "",
            "whimsical_url": r[23] if len(r) > 23 else "",
            "client_question": r[24] if len(r) > 24 else "",
            "theodo_answer": r[25] if len(r) > 25 else "",
        })
    return out


def extract_libreview(rows):
    """LibreView columns (0-indexed):
       0 EN/FR, 1 PROFIL, 2 N°, 3 ID Section, 4 Section, 5 Bloc, 6 Fonction,
       7 Nature, 8 N° exigence, 9 Enoncé, 10 Version, 11 N° scénario, 12 Scénario,
       13 N° preuve 1, 14 Preuve 1, 15 N° preuve 2, 16 Preuve 2, 17 (empty),
       18 Preuve 3, 19 Applicable, 20 Why not compliant, 21 Conforme,
       22 Reco Theodo, 23 Impact UX, 24 Whimsical,
       25 Questions Abbott, 26 Réponses Theodo
    """
    out = []
    for r in rows[1:]:
        if len(r) < 23:
            continue
        if (r[0] if len(r) > 0 else "").strip().upper() != "FR":
            continue
        scenario_id = r[11] if len(r) > 11 else ""
        if not scenario_id or not re.match(r"^[A-Za-z]+\s+\d+\.\d+$", scenario_id):
            continue
        reco = r[22] if len(r) > 22 else ""
        if is_blank(reco) or reco.strip().lower() in ("same as above", "na", "n/a"):
            continue
        out.append({
            "source": "libreview",
            "scenario_id": scenario_id,
            "profil": r[1] if len(r) > 1 else "",
            "id_section": r[3] if len(r) > 3 else "",
            "section": r[4] if len(r) > 4 else "",
            "fonction": r[6] if len(r) > 6 else "",
            "n_exigence": r[8] if len(r) > 8 else "",
            "enonce": r[9] if len(r) > 9 else "",
            "scenario_text": r[12] if len(r) > 12 else "",
            "preuve_1_text": r[14] if len(r) > 14 else "",
            "applicable": r[19] if len(r) > 19 else "",
            "non_applicable_reason": "",
            "conforme": r[21] if len(r) > 21 else "",
            "gold_reco_unified": reco.strip(),
            "impact_ux": r[23] if len(r) > 23 else "",
            "whimsical_url": r[24] if len(r) > 24 else "",
            "client_question": r[25] if len(r) > 25 else "",
            "theodo_answer": r[26] if len(r) > 26 else "",
        })
    return out


def main():
    okeiro = extract_okeiro(load_sheet(HERE / "okeiro_full.json"))
    libreview = extract_libreview(load_sheet(HERE / "libreview_full.json"))
    all_ex = okeiro + libreview

    # Index by section for stats
    by_section = {}
    for e in all_ex:
        by_section.setdefault(e["id_section"], []).append(e["scenario_id"])

    out = {
        "schema_version": "v1",
        "generated_at": "2026-05-11",
        "sources": {
            "okeiro": "Spreadsheet 10hez1I1TDviM1mVZ6HFSQbE3nJ4JipCBQa2SN4N67D4",
            "libreview": "Spreadsheet 1S827AH_83YNXgct30i7o8pBob8gGTpMm6QvcoQ2Q-vM",
        },
        "stats": {
            "total": len(all_ex),
            "okeiro_count": len(okeiro),
            "libreview_count": len(libreview),
            "by_section": {k: len(v) for k, v in by_section.items()},
        },
        "exemplars": all_ex,
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[extract] wrote {len(all_ex)} exemplars to {OUT}")
    print(f"  by section: {out['stats']['by_section']}")


if __name__ == "__main__":
    main()
