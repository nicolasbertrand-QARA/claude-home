# theodo-ans-gap-analysis (V0.1)

Plugin Claude Code pour les missions de gap-analysis ANS DMN chez Theodo. Conçu pour des **PMs non-QARA** encadrés par un **Directeur de Projet (DP)** qui valide aux 3 jalons d'une mission de **3 semaines**.

> **Statut** : V0.1 — scaffold + skill enrichie + 5 slash commands + 2 subagents + templates clés. Validation Sunrise re-run en cours. Pas encore en V1 GA.

---

## Quick start

### Installation (PM Theodo)

```bash
# 1. Setup environnement Theodo (gws CLI, dépendances, 1Password)
~/theodo-ans-plugin/scripts/setup.sh

# 2. Installer le plugin dans Claude Code
# (depuis Claude Code)
/plugin marketplace add github:nicolasbertrand-QARA/theodo-ans-plugin
/plugin install theodo-ans-gap-analysis
```

### Workflow d'une mission

```
[Sem 0]  /ans-init <client>             → prépare le folder Drive + l'intake visio
[Sem 1] Visio intake 1h (PM + DP + RAQ + DPO client) — JALON 1 inclus
[Sem 1] /ans-process-intake <client>    → fiche projet, profils, pathway
[Sem 1] /ans-probe <client>             → Playwright Web auto + capture protocols mobile
[Sem 2] Réception docs client + /ans-build <client> → gap brute + self-review
[Sem 2] Réunion DP-2 (jalon 2, 30 min)  → DP valide gap brute
[Sem 3] /ans-deliverables <client>      → 10 livrables HTML (charte Theodo HealthTech)
[Sem 3] /ans-publish <client>           → conversion HTML → Google Docs sur Drive
[Sem 3] Réunion DP-3 (jalon 3, 30 min)  → DP valide pré-kit
[Sem 3] Remise du pré-kit au client (Google Docs)
[H+5y]  /ans-archive <client>           → archivage Drive cold + révocation 1Password
```

---

## Décisions de design (Q1-Q15)

| # | Décision |
|---|---|
| Q1 | Profil utilisateurs = **PMs non-QARA + revue DP** |
| Q2 | Périmètre = **DMN + MES + Ségur + PECAN + intra-ES** (large) |
| Q3 | Livrables = **pré-kit Convergence ~10 livrables** (3 sem mission) |
| Q4 | Revue DP = **réunion 30 min × 3 jalons** + `decisions.md` |
| Q5 | State = **Drive Theodo** (folders par mission) |
| Q6 | Distribution = **plugin marketplace + setup script** |
| Q7 | Docs = **email→PM upload Drive** ; creds = **1Password vault** ; archivage = NDA std |
| Q8 | Intake = **visio unique 1h** (PM + DP + client) |
| Q9 | Discipline épistémique = **citation obligatoire + défaut À confirmer + self-review** |
| Q10 | Architecture = **slash commands + subagents pour heavy lifting** |
| Q11 | Probes = **hybrid** (Playwright Web + capture protocol mobile/native) |
| Q12 | Validation V1 = **Sunrise re-run** (ground truth connu) |
| Q13 | Scope V1 = **full ship** (tous pathways) |
| Q14 | Ownership = **mainteneur unique** |
| Q15 | Cadence = **phasé sprints** (V0.5 sem 10, V1 GA sem 24) |

Voir `ROADMAP.md` pour le détail des sprints.

---

## Structure du repo

```
theodo-ans-plugin/
├── .claude-plugin/plugin.json     # Manifest plugin
├── README.md                       # Ce fichier
├── ROADMAP.md                      # Sprints E15 détaillés
├── agents/                         # Subagents (heavy lifting)
│   ├── ans-doc-reader.md          # Lit les PDFs/docx client → JSON structuré
│   └── ans-self-reviewer.md       # 2e passage critique de la gap (Q9-D)
├── commands/                       # Slash commands (entry points PM)
│   ├── ans-init.md                # /ans-init <client> — kickoff mission
│   ├── ans-build.md               # /ans-build <client> — gap analysis
│   ├── ans-probe.md               # /ans-probe <client> — Playwright + capture protocols
│   ├── ans-deliverables.md        # /ans-deliverables <client> — pré-kit HTML
│   ├── ans-publish.md             # /ans-publish <client> — HTML → Google Docs sur Drive
│   └── ans-self-review.md         # /ans-self-review <client> — Q9-D explicit invocation
├── skills/
│   └── ANS/
│       ├── SKILL.md               # Méthodologie (existante, héritée)
│       └── references/
│           ├── dmn_exigences_full.md            # 84 exigences DMN V1.2.2
│           ├── ecosystem.md                      # Map ANS programs
│           ├── convergence_workflow.md           # Workflow Convergence
│           ├── referentiel_identites_qualification.md  # Voie A/B/C
│           ├── intake_questionnaire.md           # NEW — questions visio intake
│           ├── document_request_catalog.md       # NEW — 53 demandes types
│           ├── verdict_taxonomy.md               # NEW — Conforme/À étayer/Partiel/NC/NA/À confirmer
│           ├── epistemic_discipline.md           # NEW — Q9 A+B+D rules
│           ├── mission_workflow.md               # NEW — workflow 3 sem
│           ├── nb_assessor_lens.md               # NEW — méthode revue indépendante
│           ├── voie_a_vs_voie_b.md               # NEW — décision INS stratégique
│           ├── ai_act_interplay.md               # NEW — MDCG 2025-6 / EU AI Act
│           └── playwright_probe_patterns.md      # NEW — 8 patterns probes
├── templates/
│   ├── charte/                     # Charte graphique Theodo HealthTech
│   │   ├── theodo-healthtech.css   # CSS source (à inliner dans chaque HTML)
│   │   └── README.md               # Doc usage des composants
│   ├── playwright/                 # Templates Playwright .spec.ts
│   │   ├── probe-login.spec.ts.tpl
│   │   └── README.md               # Roadmap autres probes V0.x+
│   ├── capture-protocols/          # Pour mobile/native (capture-first) — V0.4
│   ├── deliverables/               # Livrables HTML (charte appliquée)
│   │   ├── build_gap_analysis.py.tpl                      # Python builder XLSX (natif)
│   │   ├── executive-summary.html.tpl                     # ✓ V0.1
│   │   ├── roadmap-P0-P1-P2.html.tpl                      # ✓ V0.1
│   │   ├── note-positionnement-INS-Voie-A.html.tpl        # ✓ V0.1
│   │   ├── note-positionnement-INS-Voie-B.html.tpl        # 🚧 V0.2
│   │   ├── plan-gestion-identites.html.tpl                # 🚧 V0.2
│   │   ├── matrice-rbac-identite.html.tpl                 # 🚧 V0.2
│   │   ├── dpia-template.html.tpl                         # 🚧 V0.2
│   │   ├── lettre-demande-PSC.html.tpl                    # 🚧 V0.2
│   │   ├── lettre-demande-INSi.html.tpl                   # 🚧 V0.2
│   │   └── lettre-demande-MSSante.html.tpl                # 🚧 V0.2
│   └── intake/                     # Fiche intake (HTML, rempli en visio)
│       └── intake-fiche-projet.html.tpl  # ✓ V0.1
├── scripts/
│   ├── setup.sh                    # Onboarding PM (gws auth, deps, 1Password)
│   └── init-mission.sh             # Crée le folder Drive standard
└── tests/
    └── fixtures/
        └── sunrise/                # Ground truth Q12-A
            ├── intake-fiche.md     # Intake fictif (la mission Sunrise n'a pas eu de visio)
            ├── docs/               # Liens vers les 6 PDFs Sunrise (gitignored)
            ├── expected/
            │   ├── gap-analysis.xlsx
            │   ├── disagreements.md
            │   └── deliverables/
            └── README.md
```

---

## Format des livrables — HTML autonome → Google Docs natifs

Tous les livrables narratifs (synthèse, roadmap, notes de positionnement, lettres de demande) sont produits en **HTML autonome** avec la charte Theodo HealthTech inlinée (cf. `templates/charte/`), puis convertis en **Google Docs natifs** sur le Drive client via `/ans-publish`.

**Pourquoi pas de Markdown** : la charte Theodo HealthTech (couleurs navy/yellow/terra, polices Manrope/Public Sans/JetBrains Mono, composants pills/blocks/callouts) ne se rend pas en Markdown. HTML + Google Docs préserve la qualité visuelle attendue côté client.

**Working docs internes** (intake decisions, briefs de revue, kickoff info, coverage report) restent en `.md` — ils ne sortent pas du folder mission.

| Type | Format | Audience |
|---|---|---|
| Livrables (synthèse, roadmap, notes, lettres) | HTML → Google Doc | Client |
| Gap analysis | XLSX | Client + ANS Convergence |
| Working docs (decisions, briefs, kickoff) | Markdown | PM + DP Theodo |
| Probes (Playwright, capture protocols) | TS / MD protocol | PM Theodo |

## Discipline épistémique (Q9 A+B+D — non négociable)

Tout verdict émis par le plugin DOIT respecter :

1. **Citation obligatoire** : (1) source primaire client (`PRO-460 V20 §5.2 SRS-SSP-014 p.22`) ET (2) référence opposable (`Guide INS V3.0 EXI ID 39`). Si l'une manque → statut = `À confirmer`.
2. **Défaut conservateur** : sans evidence claire → `À confirmer`. Pas de `NC` sans preuve d'absence. Pas de `Conforme` sans preuve de présence.
3. **Self-review systématique** : `/ans-build` spawn `ans-self-reviewer` (subagent indépendant) qui critique chaque verdict. Désaccords → reclassés `À confirmer` + listés dans le brief de revue jalon 2.

Voir `skills/ANS/references/epistemic_discipline.md` pour les règles complètes + exemples Sunrise V1.

---

## Versioning et compatibilité

- Plugin pinné à **DMN référentiel V1.2.2** (ANS, 2023-02-22)
- **Guide INS V3.0** (ANS, déc. 2024) intégré
- Une release majeure quand un référentiel change (cf. ROADMAP.md)
- Missions en cours figées sur la version du plugin au moment du `/ans-init`

---

## Contribution

V0.1 — mainteneur unique (Q14-A). PRs ouvertes pour bugs / corrections de références ; les nouveaux templates ou pathways passent par discussion préalable avec le mainteneur.

---

*Document créé : 2026-05-06. Version plugin : 0.1.0.*
