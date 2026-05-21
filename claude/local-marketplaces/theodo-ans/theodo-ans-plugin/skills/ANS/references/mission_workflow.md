# Workflow d'une mission ANS — 3 semaines

Cadence standard d'une mission Theodo ANS gap-analysis. Validée à l'issue de l'intake (jalon 1) et adaptée au calendrier client.

**Total** : 3 semaines effort PM (~ 0.7 FTE), 2h DP (1h intake + 2 × 30 min revues), 3 sem calendaires.

> **Cadence tendue par construction** : la marge pour les retards client est minimale. Si une dépendance externe (docs client manquants, creds testing en retard) glisse > 2j, escalade DP immédiate pour décider entre prolongation ou mode dégradé.

---

## Sem 0 — Prérequis avant kickoff

- [ ] DP : valide la pertinence commerciale de la mission
- [ ] PM : assigné, briefé sur la méthodo (a lu `epistemic_discipline.md`, `verdict_taxonomy.md`, `mission_workflow.md`)
- [ ] PM : `/ans-init <client>` exécuté → folder Drive Theodo créé, structure standard, README mission
- [ ] PM + DP : visio intake calendaire avec client (1h, début de sem 1, idéalement lundi/mardi)
- [ ] PM : 1Password vault `Theodo-ANS/<client>-testing` créé (vide, à remplir par client après intake)
- [ ] PM : la lettre de demande de docs (`document-request-letter.md`) est pré-rédigée et prête à envoyer le jour de l'intake

---

## Sem 1 — Intake + setup probes en parallèle

### Jour 1 (Lun) — Visio intake (jalon 1)

**Format** : 1h, présents = PM + DP + RAQ client + DPO client (cf. Q8-A).

**Déroulé** : suivre `intake_questionnaire.md` strictement.

**Output immédiat à la fin de la visio** :
- `intake/fiche-projet.md` rempli pendant la visio
- `intake/decisions.md` signé par DP **en fin de visio** (qualification + Voie INS + profils applicables) — **non négociable**, sinon mission compromise
- `intake/pathway-decision.md` (DMN nom de marque / ligne générique / PECAN / PECT / MES / Ségur)

### Jour 1-2 (Lun-Mar) — Foundation

- [ ] PM : `/ans-process-intake <client>` parse la fiche → produit le brief de revue jalon 1 (déjà signé en visio, formalisé écrit)
- [ ] PM : envoie au client la lettre de demande de documents **dans la journée de l'intake** (issue de `document_request_catalog.md`, personnalisée selon profils applicables) avec deadline P0 ≤ J+5
- [ ] PM : invitation client comme **reader** sur folder Drive (cf. Q7-A2)
- [ ] PM : invite client RAQ + DPO au 1Password vault partagé
- [ ] PM : calendrier des 2 jalons restants envoyé (réunion jalon 2 sem 2 jour 5, jalon 3 sem 3 jour 4)

### Jour 3-5 (Mer-Ven) — Setup probes en parallèle

Pendant que le client rassemble ses docs, le PM prépare l'infra de test :

- [ ] PM : si vault 1Password rempli par client, configure `probes/.env.local` avec `op read`
- [ ] PM : si stack Web identifiée à l'intake, lance le **probe-discovery** initial (`/ans-probe <client>` mode discovery) sur les pages publiques (login, signup) pour découvrir les sélecteurs
- [ ] PM : adapte les templates Playwright avec les sélecteurs trouvés
- [ ] PM : génère et envoie au client les capture protocols mobile/native (cf. `playwright_probe_patterns.md`) si stacks non-Web

⚠ **Si pas de docs P0 reçus en J+5** → escalade DP en début de sem 2 pour décider :
- (a) prolonger d'1 sem → mission devient 4 sem
- (b) mode dégradé → gap analysis sur ce qui est dispo + beaucoup de `À confirmer`
- (c) suspendre la mission

---

## Sem 2 — Réception docs + probes + gap analysis brute

### Jour 1-2 (Lun-Mar) — Probes + lecture docs

- [ ] PM : `/ans-probe <client>` lance Playwright Web (auto) **en background** pour les flux critiques :
  - Login HCP
  - Signup HCP (champs, password policy)
  - Fiche patient (RNIV fields)
  - Export PDF night report
  - Lockout 5 tentatives
  - Logout
- [ ] PM : si capture protocols mobile/native ont été envoyés au client en sem 1, relance pour réception
- [ ] PM : tracking des docs reçus dans `intake/docs-tracking.md`

### Jour 2-3 (Mar-Mer) — Lecture docs + gap brute

- [ ] PM : `/ans-build <client>` quand **tous les docs P0 reçus** + probes Web faits + captures mobile reçues
- [ ] Plugin :
  1. Subagent `ans-doc-reader` lit les PDFs/docx/SOPs → JSON structuré (1-2h)
  2. Main thread orchestre la gap analysis sur les 103 scénarios (2-4h)
  3. Subagent `ans-self-reviewer` en 2e passage indépendant → `disagreements.md` (1-2h)
  4. Merge → `analysis/gap-analysis-brute.xlsx` (avec colonne self-review pour chaque verdict)
  5. Génère `briefs-revue/jalon-2-gap-brute.md`

### Jour 4 (Jeu) — Préparation revue jalon 2

- [ ] PM : relit le brief, prépare la réunion jalon 2 (note les points qu'il veut clarifier)
- [ ] PM : si désaccords self-review URGENTS (radicaux NC ↔ Conforme), prévient le DP **la veille** pour mini-pré-revue informelle

### Jour 5 (Ven) — Réunion jalon 2 (30 min)

**Présents** : PM + DP. Pas de client (revue interne).

**Objectif** :
- DP relit `briefs-revue/jalon-2-gap-brute.md`
- DP relit l'XLSX en survol (focus sur les NC cat. A et désaccords self-review)
- Décisions sur les `À confirmer` non résolus : reclasser, demander client, ou laisser ouvert

**Output** :
- DP signe `intake/decisions.md` (gap brute validée OU corrections à apporter)
- Si corrections : PM les applique le lundi suivant, marge de 2 jours

---

## Sem 3 — Déliverables + remise

### Jour 1-2 (Lun-Mar) — Production des 10 livrables

- [ ] PM : `/ans-deliverables <client>` produit les 10 livrables :
  1. `gap-analysis.xlsx` (final, post-jalon 2)
  2. `executive-summary.md` (≤ 3 pages)
  3. `roadmap-P0-P1-P2.md`
  4. `note-positionnement-INS.md`
  5. `plan-gestion-identites.md`
  6. `matrice-rbac-identite.md`
  7. `dpia-template.md`
  8. `lettre-demande-PSC.md`
  9. `lettre-demande-INSi.md`
  10. `lettre-demande-MSSante.md`
- [ ] PM : relit chaque livrable, ajuste le contexte client (parfois manuel — un livrable n'est pas pleinement automatisable)

### Jour 3 (Mer) — Préparation revue jalon 3 + brief

- [ ] PM : prépare le brief de revue jalon 3
- [ ] PM : pré-relecture interne — vérification cohérence cross-livrables avant de soumettre au DP

### Jour 4 (Jeu) — Réunion jalon 3 (30 min)

**Présents** : PM + DP. Optionnel : un autre QARA Theodo en peer review.

**Objectif** :
- DP relit chaque livrable du pré-kit
- Vérification cohérence cross-livrables (ex : la roadmap P0/P1/P2 cite-t-elle les exigences NC du gap ? La note de positionnement INS est-elle cohérente avec la décision Voie A/B ?)
- Décision : pré-kit prêt pour remise client OU corrections finales

**Output** :
- DP signe `intake/decisions.md` (pré-kit validé)
- Si corrections : PM les applique dans la matinée du vendredi

### Jour 5 (Ven) — Remise du pré-kit + clôture

- [ ] PM : envoie le pré-kit au client (par email avec lien Drive du folder `deliverables/`)
- [ ] PM : visio courte (30 min, sans DP) pour présenter le pré-kit au client + répondre aux questions
- [ ] Client : fin de mission Theodo gap-analysis ; le client porte la suite (R&D, raccordements ANS, signature note positionnement, soumission Convergence)
- [ ] PM : retex interne (15 min, formel) avec le mainteneur du plugin → bugs / améliorations à intégrer

### H+30 — Archivage

- [ ] PM : `/ans-archive <client>` — archive Drive en cold storage, révoque accès 1Password, met à jour le master Notion des missions Theodo

---

## Variantes du calendrier

### Mission rapide (PECAN urgent, 2 sem)

Compresser au maximum, en sacrifiant la maturité de l'analyse :
- Sem 1 : intake + docs P0 (parallèle visio + envoi) + probes
- Sem 2 : gap analysis + self-review + déliverables + jalons 2+3 fusionnés en 1 réunion 1h en fin de sem

⚠ Risque élevé : peu de temps pour les `À confirmer` → beaucoup de questions au client en post-remise. Recommandé seulement pour clients très matures avec docs déjà bien organisés.

### Mission standard (3 sem, défaut) — décrite ci-dessus

### Mission complexe (Ségur multi-couloirs, 4-6 sem)

Étendre :
- Sem 1 : intake (parfois 2 visios pour explorer chaque couloir Ségur)
- Sem 2 : docs + probes (volume plus important)
- Sem 3 : gap analysis + self-review + jalon 2
- Sem 4 : déliverables (12-15 au lieu de 10) + jalon 3 + remise

### Mission avec client peu disponible

Si le client met > 5j à fournir les docs P0 :
- PM signale escalade fin sem 1
- DP peut décider : (a) prolongation (mission devient 4 sem), (b) mode dégradé (beaucoup de `À confirmer`), (c) suspension

---

## Métriques à tracker par mission

À reporter dans `analysis/metrics.md` à la fin de chaque mission, agrégées trimestriellement par le mainteneur du plugin :

| Métrique | Cible | Source |
|---|---|---|
| Durée totale (sem calendaires) | 3 (max 4 si glissement client) | git log + dates kickoff/livraison |
| Heures PM | ≈ 60h sur 3 sem (≈ 0.7 FTE) | self-report PM |
| Heures DP | ≈ 2h | self-report DP |
| Délai docs P0 reçus (j depuis intake) | ≤ 5 | docs-tracking.md |
| Nb docs reçus | ≥ 25 | docs-tracking.md |
| Nb verdicts par statut (final) | distribution standard cf. verdict_taxonomy.md | gap-analysis.xlsx |
| Taux de désaccord self-review | < 15 % | disagreements.md |
| Nb `À confirmer` finaux | < 5 | gap-analysis.xlsx |
| Satisfaction client (note /5) | ≥ 4 | feedback post-mission |

---

*Dernière mise à jour : 2026-05-07.*
