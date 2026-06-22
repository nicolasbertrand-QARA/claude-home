import json

GEN = "2026-06-19"

# Each entry: (seq, action, reason, existing_id_or_None, card_en, card_fr_overrides)
# card_fr_overrides only translates t, x, l. Other fields identical.

props = []

def add(seq, action, reason, card_en, fr, existing_id=None):
    p_en = {
        "id": f"proposal-{GEN}-{seq:03d}",
        "action": action,
        "reason": reason,
        "card": card_en,
    }
    p_fr_card = dict(card_en)
    p_fr_card["t"] = fr["t"]
    p_fr_card["x"] = fr["x"]
    p_fr_card["l"] = fr["l"]
    p_fr = {
        "id": f"proposal-{GEN}-{seq:03d}",
        "action": action,
        "reason": reason,
        "card": p_fr_card,
    }
    if existing_id:
        p_en["existing_id"] = existing_id
        p_fr["existing_id"] = existing_id
    props.append((p_en, p_fr))

# 1. MDR harmonised standards decision (EU) 2026/1231
add(1, "add",
    "EC announced Commission Implementing Decision (EU) 2026/1231 adding/updating MDR harmonised standards (page updated 17 Jun 2026); new presumption-of-conformity references manufacturers must map to GSPRs.",
    {"id": "2026-06-11--mdr-harmonised-standards-decision-2026-1231",
     "d": "2026-06-11", "l": "11 Jun 2026", "y": 2026,
     "t": "MDR Harmonised Standards — Decision (EU) 2026/1231",
     "x": "New/updated harmonised standards added under MDR conferring presumption of conformity. Read the OJEU list and refresh GSPR-to-standard conformity mapping.",
     "u": "https://health.ec.europa.eu/medical-devices-sector/new-regulations_en",
     "tp": ["mdr", "standards"], "tg": ["in-force"], "v": "n"},
    {"t": "Normes harmonisées MDR — Décision (UE) 2026/1231",
     "x": "Nouvelles normes harmonisées ajoutées au titre du MDR conférant présomption de conformité. Lire la liste au JOUE et mettre à jour la cartographie exigences essentielles / normes.",
     "l": "11 juin 2026"})

# 2. EU REP symbol transition
add(2, "add",
    "OJEU reference to EN ISO 15223-1:2021/A1:2025 plus MDCG 2021-5 Rev.1 Appendix formalised the EC REP to EU REP authorised-representative symbol change (17 Jun 2026); labelling change-control item with 2031 transition deadlines.",
    {"id": "2026-06-17--ec-rep-to-eu-rep-symbol-transition",
     "d": "2026-06-17", "l": "17 Jun 2026", "y": 2026,
     "t": "EC REP → EU REP Symbol Transition",
     "x": "EN ISO 15223-1:2021/A1:2025 cited in OJEU + MDCG 2021-5 Rev.1 Appendix. Editorial change of the authorised-representative symbol; no change to AR role. Transition to 15 Jun 2031 (MDR) / 17 Jun 2031 (IVDR).",
     "u": "https://medenvoyglobal.com/blog/mdcg-issues-guidance-on-transition-from-ec-rep-to-eu-rep-symbol-on-medical-device-labeling/",
     "tp": ["mdr", "standards"], "tg": ["new"], "v": "n"},
    {"t": "Transition du symbole EC REP → EU REP",
     "x": "EN ISO 15223-1:2021/A1:2025 citée au JOUE + appendice MDCG 2021-5 Rev.1. Modification éditoriale du symbole du mandataire; rôle du mandataire inchangé. Transition jusqu'au 15 juin 2031 (MDR) / 17 juin 2031 (IVDR).",
     "l": "17 juin 2026"})

# 3. SS(C)P in EUDAMED position paper
add(3, "add",
    "EC published a position paper on managing the Summary of Safety and (Clinical) Performance in EUDAMED now the first four modules are mandatory (18 Jun 2026); affects Class III/implantable/IVD C-D.",
    {"id": "2026-06-18--sscp-management-in-eudamed-position-paper",
     "d": "2026-06-18", "l": "18 Jun 2026", "y": 2026,
     "t": "SS(C)P Management in EUDAMED — Position Paper",
     "x": "EC position paper on handling the Summary of Safety and (Clinical) Performance now EUDAMED modules are mandatory. Relevant for Class III / implantable / IVD Class C-D. Aggregator label 'MDCG 2026-4' unconfirmed; verify before citing.",
     "u": "https://health.ec.europa.eu/medical-devices-sector/new-regulations_en",
     "tp": ["mdr"], "tg": ["new"], "v": "n"},
    {"t": "Gestion du SS(C)P dans EUDAMED — Position Paper",
     "x": "Note de position de la CE sur la gestion du résumé des caractéristiques de sécurité et des performances (cliniques) maintenant que les modules EUDAMED sont obligatoires. Concerne classe III / implantables / DIV classe C-D. Référence « MDCG 2026-4 » non confirmée; à vérifier avant citation.",
     "l": "18 juin 2026"})

# 4. ISO 14155:2026 Edition 4
add(4, "add",
    "ISO 14155 Edition 4 was published 23 Mar 2026 and applies immediately to new clinical investigations with no transition period; not yet on the timeline and relevant where MDSW needs a clinical investigation.",
    {"id": "2026-03-23--iso-14155-2026-edition-4-in-force",
     "d": "2026-03-23", "l": "23 Mar 2026", "y": 2026,
     "t": "ISO 14155:2026 (Edition 4) In Force",
     "x": "Applies immediately to new clinical investigations, no transition. Adds mandatory risk-management integration, formal Clinical Events / Data Monitoring Committees and an estimand framework.",
     "u": "https://www.iso.org/standard/83968.html",
     "tp": ["standards"], "tg": ["in-force"], "v": "n"},
    {"t": "ISO 14155:2026 (édition 4) en vigueur",
     "x": "Applicable immédiatement aux nouvelles investigations cliniques, sans transition. Intègre obligatoirement la gestion des risques, des comités d'événements cliniques / de surveillance des données et un cadre d'estimands.",
     "l": "23 mars 2026"})

# 5. IMDRF AI best-practices consultation closed
add(5, "add",
    "IMDRF draft framework on best practices for AI-enabled medical devices closed public consultation 10 Jun 2026, building on 2025 GMLP; dispositions head to the Sep 2026 Management Committee. Likely future global reference text.",
    {"id": "2026-06-10--imdrf-ai-best-practices-consultation-closed",
     "d": "2026-06-10", "l": "10 Jun 2026", "y": 2026,
     "t": "IMDRF AI Best-Practices Framework — Consultation Closed",
     "x": "Draft framework harmonising best practices to mitigate AI-enabled device risks across the lifecycle (builds on 2025 GMLP). Comment period closed 10 Jun; dispositions to IMDRF Management Committee 14-18 Sep 2026, Singapore.",
     "u": "https://www.raps.org/resource/imdrf-drafts-framework-on-best-practices-for-using-ai-in-medical-devices.html",
     "tp": ["other", "ai"], "tg": ["new"], "v": "n"},
    {"t": "Cadre IMDRF bonnes pratiques IA — consultation close",
     "x": "Projet de cadre harmonisant les bonnes pratiques pour réduire les risques des DM intégrant de l'IA sur le cycle de vie (suite des GMLP 2025). Consultation close le 10 juin; suites au Comité de gestion IMDRF 14-18 sept. 2026, Singapour.",
     "l": "10 juin 2026"})

# 6. Health Canada ML guidance in force
add(6, "add",
    "Health Canada pre-market guidance for machine learning-enabled medical devices is in force since 1 Apr 2026 (lifecycle expectations + PCCP mechanism); a notable global change-control development not yet on the timeline.",
    {"id": "2026-04-01--health-canada-ml-device-guidance-in-force",
     "d": "2026-04-01", "l": "1 Apr 2026", "y": 2026,
     "t": "Health Canada ML-Enabled Device Guidance In Force",
     "x": "Lifecycle expectations for MLMDs (data quality, training/validation, bias, performance monitoring, transparency) plus a Predetermined Change Control Plan mechanism. Companion post-market monitoring guidance published 9 Apr 2026.",
     "u": "https://www.canada.ca/en/health-canada/services/drugs-health-products/medical-devices/application-information/guidance-documents/pre-market-guidance-machine-learning-enabled-medical-devices.html",
     "tp": ["other", "ai"], "tg": ["in-force"], "v": "n"},
    {"t": "Santé Canada — guide DM à apprentissage automatique en vigueur",
     "x": "Attentes cycle de vie pour les DM à apprentissage automatique (qualité des données, entraînement/validation, biais, surveillance des performances, transparence) plus un mécanisme de plan de contrôle des modifications prédéterminé. Guide complémentaire de surveillance post-marché publié le 9 avr. 2026.",
     "l": "1er avr. 2026"})

# 7. TGA PCCP draft consultation closed
add(7, "add",
    "TGA draft guidance on Predetermined Change Control Plans for AI/software devices closed consultation 5 Jun 2026; finalisation expected to follow. Part of global PCCP convergence.",
    {"id": "2026-06-05--tga-pccp-draft-consultation-closed",
     "d": "2026-06-05", "l": "5 Jun 2026", "y": 2026,
     "t": "Australia TGA PCCP Draft Guidance — Consultation Closed",
     "x": "Draft guidance lets AI/software devices be modified post-market under a pre-approved change plan without a full new submission. Comment window closed 5 Jun 2026; finalisation to follow.",
     "u": "https://www.medicalrepublic.com.au/tga-giving-ai-updates-a-longer-leash/125029",
     "tp": ["other", "ai"], "tg": ["new"], "v": "n"},
    {"t": "TGA Australie — projet guide PCCP, consultation close",
     "x": "Projet de guide permettant de modifier les DM IA/logiciels après commercialisation selon un plan de modification pré-approuvé, sans nouvelle soumission complète. Consultation close le 5 juin 2026; finalisation à suivre.",
     "l": "5 juin 2026"})

# 8. MHRA Medical Devices (Amendment) Regulations 2026 consultation closed
add(8, "add",
    "MHRA pre-market consultation on the draft Medical Devices (Amendment) Regulations 2026 (international reliance routes, strengthened SaMD/IVD, UDI) closed 19 Jun 2026; expected adoption Dec 2026, entry into force Jun 2027.",
    {"id": "2026-06-19--mhra-medical-devices-amendment-regs-consult",
     "d": "2026-06-19", "l": "19 Jun 2026", "y": 2026,
     "t": "MHRA Medical Devices (Amendment) Regs 2026 — Consultation Closed",
     "x": "Pre-market reform: international reliance routes, strengthened SaMD/IVD requirements, mandatory UDI and implant cards, IVD risk-based classification. Expected adoption Dec 2026; entry into force Jun 2027.",
     "u": "https://www.gov.uk/government/news/mhra-invites-views-on-proposed-changes-to-medical-device-regulation",
     "tp": ["uk", "mdr"], "tg": ["new"], "v": "n"},
    {"t": "MHRA — projet de règlement DM (amendement) 2026, consultation close",
     "x": "Réforme pré-marché: voies de reconnaissance internationale, exigences renforcées SaMD/DIV, IUD et cartes d'implant obligatoires, classification DIV fondée sur le risque. Adoption attendue déc. 2026; entrée en vigueur juin 2027.",
     "l": "19 juin 2026"})

# 9. UK DUAA complaints process in force
add(9, "add",
    "Final tranche of the UK Data (Use and Access) Act 2025 commenced 19 Jun 2026, including a mandatory data-protection complaints process with no small-business exemption; directly relevant to health-data SaMD operators.",
    {"id": "2026-06-19--uk-duaa-2025-complaints-process-in-force",
     "d": "2026-06-19", "l": "19 Jun 2026", "y": 2026,
     "t": "UK DUAA 2025 — Mandatory Complaints Process In Force",
     "x": "Controllers must offer a clear complaints route, acknowledge within 30 days and investigate without undue delay. No small-business exemption. Applies to health-data SaMD operators.",
     "u": "https://ico.org.uk/about-the-ico/what-we-do/legislation-we-cover/data-use-and-access-act-2025/",
     "tp": ["uk", "data"], "tg": ["in-force"], "v": "n"},
    {"t": "UK DUAA 2025 — processus de réclamation obligatoire en vigueur",
     "x": "Les responsables de traitement doivent offrir une voie de réclamation claire, accuser réception sous 30 jours et instruire sans retard injustifié. Pas d'exemption pour les petites entreprises. Concerne les opérateurs SaMD traitant des données de santé.",
     "l": "19 juin 2026"})

# 10. MHRA AI Airlock Phase 2 report
add(10, "add",
    "MHRA published its AI Airlock Phase 2 programme report (9 Jun 2026) with five insights (notably human oversight is not static across the lifecycle); Phase 3 funded GBP 1.2m/yr to 2029 to feed the forthcoming AIaMD framework.",
    {"id": "2026-06-09--mhra-ai-airlock-phase-2-report",
     "d": "2026-06-09", "l": "9 Jun 2026", "y": 2026,
     "t": "MHRA AI Airlock Phase 2 Report",
     "x": "Seven AI technologies, five insights: real-world performance hard to replicate in controlled settings; human oversight cannot be treated as static across the lifecycle. Phase 3 funded GBP 1.2m/yr (2026-2029) to feed the AIaMD framework.",
     "u": "https://medregs.blog.gov.uk/2026/06/09/advancing-ai-regulation-in-healthcare-insights-from-ai-airlock-phase-2/",
     "tp": ["uk", "ai"], "tg": ["new"], "v": "n"},
    {"t": "MHRA — rapport AI Airlock phase 2",
     "x": "Sept technologies IA, cinq enseignements: la performance en conditions réelles est difficile à reproduire en environnement contrôlé; la supervision humaine ne peut être figée sur le cycle de vie. Phase 3 financée 1,2 M£/an (2026-2029) pour alimenter le cadre AIaMD.",
     "l": "9 juin 2026"})

# 11. CNIL MR-001/MR-003 update
add(11, "add",
    "CNIL updated and widened the scope of reference methodologies MR-001 and MR-003 for health research, applicable to research initiated from 23 May 2026; relevant to French-market MDSW running clinical research.",
    {"id": "2026-05-23--cnil-mr-001-mr-003-updated",
     "d": "2026-05-23", "l": "23 May 2026", "y": 2026,
     "t": "CNIL MR-001 / MR-003 Updated (France)",
     "x": "Updated and widened reference methodologies for health research, applicable to research initiated from 23 May 2026. A consolidated guidance on the dossier patient informatisé is planned for 2026.",
     "u": "https://www.cnil.fr/fr/recherche-en-sante-la-cnil-met-jour-et-elargit-le-champ-des-methodologies-de-reference-001-et-003",
     "tp": ["france", "data"], "tg": ["new"], "v": "n"},
    {"t": "CNIL MR-001 / MR-003 mises à jour (France)",
     "x": "Méthodologies de référence pour la recherche en santé mises à jour et au champ élargi, applicables aux recherches initiées à partir du 23 mai 2026. Un document consolidé sur le dossier patient informatisé est prévu en 2026.",
     "l": "23 mai 2026"})

# 12. UPDATE prEN 18286
add(12, "update",
    "Existing prEN 18286 card asserts a 'failed Jan 2026 vote' that could not be substantiated against primary sources this week; corrected to reflect the public enquiry closed 22 Jan 2026 and AI Act harmonised-standards delivery slipping to end-2026 at the earliest.",
    {"id": "2026-10-15--pren-18286-ai-act-qms-standard-revised",
     "d": "2026-10-15", "l": "Late 2026", "y": 2026,
     "t": "prEN 18286 — AI Act QMS Standard Still In Pipeline",
     "x": "First harmonised standard for AI Act QMS (Article 17). CEN/CENELEC JTC 21 public enquiry ran 30 Oct 2025 to 22 Jan 2026; AI Act harmonised-standards delivery now slipped to end-2026 at the earliest. Not yet cited in the OJEU.",
     "u": "https://cms-lawnow.com/en/ealerts/2025/12/the-first-draft-ai-act-standard-for-public-consultation-what-pren-18286-quality-management-system-for-eu-ai-act-regulatory-purposes-signals-for",
     "tp": ["ai", "standards"], "tg": ["medium"], "v": "n"},
    {"t": "prEN 18286 — norme SMQ IA Act toujours en cours",
     "x": "Première norme harmonisée pour le SMQ au titre de l'IA Act (article 17). L'enquête publique CEN/CENELEC JTC 21 s'est tenue du 30 oct. 2025 au 22 janv. 2026; la livraison des normes harmonisées IA Act glisse désormais à fin 2026 au plus tôt. Pas encore citée au JOUE.",
     "l": "fin 2026"},
    existing_id="2026-10-15--pren-18286-ai-act-qms-standard-revised")

en = {"generated": GEN, "proposals": [p[0] for p in props]}
fr = {"generated": GEN, "proposals": [p[1] for p in props]}

with open("/Users/nicolasbertrand/.claude/regulatory-watch/repo/proposals.json", "w", encoding="utf-8") as f:
    json.dump(en, f, ensure_ascii=False, indent=2)
with open("/Users/nicolasbertrand/.claude/regulatory-watch/repo/proposals-fr.json", "w", encoding="utf-8") as f:
    json.dump(fr, f, ensure_ascii=False, indent=2)

print(f"Wrote {len(props)} proposals (EN + FR).")
print("Actions:", {a: sum(1 for p,_ in props if p['action']==a) for a in set(p['action'] for p,_ in props)})
