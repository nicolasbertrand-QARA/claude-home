# Roadmap — theodo-ans-gap-analysis

Cadence de développement choisie en Q15 : **phasé sprints**, V0.5 à sem 10, V1 GA à sem 24. Calendrier théorique en 0.3 FTE (3j/sem). Doublé si 0.15 FTE.

---

## ✅ Sprint 1 (sem 1-2) — Skill enrichment + scaffold

**Objectif** : Méthodologie écrite, structure du plugin posée, prêt à coder.

- [x] Repo plugin créé + structure de dossiers
- [x] `plugin.json` + `README.md`
- [x] Migration des 4 références skill ANS existantes (`dmn_exigences_full`, `ecosystem`, `convergence_workflow`, `referentiel_identites_qualification`)
- [x] Skill `SKILL.md` adapté (héritage)
- [x] **5 nouvelles références écrites** (V0.1) :
  - `epistemic_discipline.md` — règles Q9 A+B+D
  - `verdict_taxonomy.md` — 6 statuts + critères
  - `intake_questionnaire.md` — questions visio intake (par pathway)
  - `mission_workflow.md` — 4-6 sem cadencé
  - `document_request_catalog.md` — 53 demandes types
- [ ] **3 références à compléter** (V0.2, sprint 5-6) :
  - `nb_assessor_lens.md`
  - `voie_a_vs_voie_b.md` (extension de la ref existante)
  - `ai_act_interplay.md`
  - `playwright_probe_patterns.md`

---

## 🚧 Sprint 2 (sem 3-4) — `/ans-build` MVP + Sunrise re-run

**Objectif** : Plugin produit la gap analysis Sunrise depuis les PDFs avec ≤ 5 % delta vs ground truth.

- [x] Slash command `/ans-build` (V0.1, contenu basique)
- [x] Subagent `ans-doc-reader` (V0.1)
- [x] Subagent `ans-self-reviewer` (V0.1)
- [x] Template `build_gap_analysis.py.tpl` paramétrable
- [ ] Test end-to-end : reproduire Sunrise_DMN_GapAnalysis.xlsx depuis les PDFs
- [ ] Tag `v0.1`

---

## 🔜 Sprint 3 (sem 5-6) — `/ans-init` + intake

- [x] Slash command `/ans-init` (V0.1)
- [ ] Slash command `/ans-process-intake` (à coder sprint 3)
- [ ] Template `intake-fiche-projet.md.tpl`
- [ ] Routing pathway depuis intake (DMN nom de marque vs ligne générique vs PECAN vs MES vs Ségur)
- [ ] Génération du brief de revue jalon 1
- [ ] Tag `v0.2`

---

## 🔜 Sprint 4 (sem 7-8) — `/ans-probe`

- [x] Slash command `/ans-probe` (V0.1, Web + capture-protocol)
- [ ] 8 templates Playwright (login, signup, patient-form, pdf-export, password-policy, lockout, logout, idle-timeout)
- [ ] 4 capture protocols (iOS, Android, Electron, Flutter Web)
- [ ] Lecture creds depuis 1Password vault
- [ ] Lien probe ↔ exigence via nommage de fichiers
- [ ] Tag `v0.3`

---

## 🔜 Sprint 5 (sem 9-10) — `/ans-deliverables` (5 livrables)

**Objectif V0.5** : Plugin produit le pré-kit Sunrise-comparable bout-en-bout.

- [ ] `gap-analysis.xlsx` (déjà ok via `/ans-build`)
- [ ] `executive-summary.md`
- [ ] `roadmap-P0-P1-P2.md`
- [ ] `note-positionnement-INS-Voie-A.md`
- [ ] `lettre-demande-PSC.md`
- [ ] **V0.5 GA** — Tag `v0.5`. Bêta interne avec 1 PM volontaire.

---

## 🔜 Sprint 6-8 (sem 11-16) — Extension pathways + 5 livrables restants

- [ ] Pathway PECAN (intake + déliverables spécifiques)
- [ ] Pathway ligne générique (5 pathologies HAS)
- [ ] Pathway MES referencement (REM/DSR)
- [ ] Pathway Ségur vague 2
- [ ] Profil intra-ES (INS 39.1 applicable)
- [ ] Voie B INS (refonte parcours)
- [ ] 5 livrables restants : `plan-gestion-identites.md`, `matrice-rbac-identite.md`, `dpia-template.md`, `lettre-demande-INSi.md`, `lettre-demande-MSSante.md`
- [ ] Tag `v0.9-rc1`

---

## 🔜 Sprint 9-10 (sem 17-20) — Self-review + polish + marketplace

- [ ] Self-review systématique dans `/ans-build` (Q9-D — déjà partiellement codé en V0.1, à durcir)
- [ ] Score de couverture par exigence
- [ ] Marketplace setup (à migrer vers org Theodo officielle quand dispo, actuellement `nicolasbertrand-QARA/theodo-ans-plugin`)
- [ ] Setup script complet (gws auth, dépendances, 1Password CLI)
- [ ] Documentation onboarding PM (1 page)
- [ ] Tag `v0.9-rc2`

---

## 🎯 Sprint 11-12 (sem 21-24) — V1 GA

- [ ] Formation interne Theodo (1h)
- [ ] Migration des missions en cours sur le plugin (si applicable)
- [ ] Tag `v1.0`
- [ ] Communication interne Theodo

---

## V2 (mois 7+) — Features différées

- Multi-langue support (clients dossiers en EN/DE/NL/IT)
- MCP server pour exposer le référentiel ANS à d'autres outils
- Mode « live interview » (Q8 option D — outil affiche les questions en temps réel pendant la visio)
- Anonymisation auto pour formation
- Watermark de confiance par verdict (Q9 option C)
- Détection automatique de stack à partir d'analyse passive

---

*Roadmap créée : 2026-05-06. Mise à jour à chaque tag.*
