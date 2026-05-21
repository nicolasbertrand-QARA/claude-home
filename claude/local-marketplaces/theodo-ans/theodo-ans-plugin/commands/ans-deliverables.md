---
description: Produit les 10 livrables du pré-kit Convergence à partir de la gap analysis validée.
argument-hint: <client-slug>
applies_rules: []
requires_tier_at_least: T3
retry_policy: transient_only
criticality: blocking
failure_blocks: [ans-publish]
---

# /ans-deliverables {{ args }}

Tu produis le pré-kit Convergence pour la mission **{{ args }}**. Pré-requis : `/ans-build` exécuté + gap brute validée par DP au jalon 2 (`intake/decisions.md` signé).

## Charges immédiates

```
skills/ANS/SKILL.md
skills/ANS/references/convergence_workflow.md
skills/ANS/references/referentiel_identites_qualification.md
templates/charte/theodo-healthtech.css                (charte graphique à inliner)
templates/charte/README.md                            (composants HTML disponibles)
intake/fiche-projet.html                              (au format HTML aligné charte)
intake/decisions.md                                   (vérifier signature jalon 2)
analysis/gap-analysis.xlsx                            (final post-self-review)
analysis/coverage.md
templates/deliverables/*.html.tpl                     (templates HTML aligné charte Theodo)
```

## Format des livrables

Les livrables sont produits en **HTML autonome** (CSS de la charte Theodo HealthTech inliné), prêt à être :
1. **Visualisé** directement dans le navigateur (rendu fidèle à la charte)
2. **Uploadé sur Drive** via `/ans-publish` qui les convertit en **Google Docs natifs** (avec conversion automatique gws CLI)

**Pas de Markdown.** Tous les livrables narratifs (synthèse, roadmap, note de positionnement, etc.) sont en HTML.

L'unique exception : `gap-analysis.xlsx` reste en XLSX natif (pour Excel / LibreOffice / Google Sheets).

## Étapes

### 1. Vérification pré-requis

- [ ] `/ans-build` a été lancé et a produit `analysis/gap-analysis.xlsx`
- [ ] DP a signé le jalon 2 dans `decisions.md`
- [ ] Aucun désaccord self-review URGENT en attente

Si manque → ÉCHEC, expliquer au PM ce qui bloque.

### 2. Lecture des inputs

Récupère depuis la mission :
- Profils applicables (`decisions.md`)
- Pathway visé (`pathway-decision.md`)
- Voie INS choisie (Voie A ou Voie B, depuis `decisions.md`)
- Distribution des verdicts (`gap-analysis.xlsx`)
- Liste des NC cat. A bloquantes
- Liste des actions P0/P1/P2 (`coverage.md`)
- **V0.4 Lot 4 / A3** — `dp_decisions.jalon_3.delivery_with_pending_evidence[]`
  depuis le project-brief.json. Si non vide, le DP a signé un override
  pour livrer un pré-kit sous réserve (capture mobile reportée, doc
  client en attente, etc.). Renseigne alors la variable de template
  `pending_evidence_banner_html` (cf. § 3 ci-dessous).

#### V0.4 — Helper `render_pending_evidence_banner()`

Génère le bandeau jaune « livrable sous réserve » à inliner dans CHAQUE
livrable HTML :

```python
def render_pending_evidence_banner(brief):
    items = (brief.get("dp_decisions", {})
                  .get("jalon_3", {})
                  .get("delivery_with_pending_evidence", []))
    if not items:
        return ""  # cas nominal — livrable final, pas de bandeau
    items_html = "\n".join(
        f"<li><strong>{i.get('label','?')}</strong> — {i.get('rationale','')}</li>"
        for i in items
    )
    due = items[0].get("evidence_due_date", "à confirmer")
    signed = items[0].get("signed_at", "?")
    return (
        "<aside class=\"callout warn\" style=\"margin-bottom:24px;"
        "border-left:4px solid #d4a017;background:#fff8e6;padding:12px 16px;\">"
        "<strong style=\"color:#a5780f;\">⚠ Livrable sous réserve — version preliminary</strong>"
        f"<p style=\"margin:6px 0 0;\">Ce pré-kit est remis sous réserve. "
        "Le DP a signé un override couvrant les éléments suivants :</p>"
        f"<ul style=\"margin:6px 0 0 20px;\">{items_html}</ul>"
        f"<p style=\"margin:6px 0 0;font-size:0.88rem;color:#666;\">"
        f"Date de régularisation prévue : {due} · Signature DP : {signed}</p>"
        "</aside>"
    )
```

Le helper est appelé pour chaque template HTML qui contient le marqueur
`{{ pending_evidence_banner_html }}` (présent à minima sur
`executive-summary.html.tpl` ; à étendre aux autres templates au besoin).

### 3. Production des livrables (HTML)

Pour chacun des 10 livrables, instancie le template approprié (`*.html.tpl`) et adapte au contexte client.

**Workflow par livrable** :
1. Copier le template `.html.tpl` vers `deliverables/NN-nom.html`
2. Substituer les placeholders `{{ variable }}` (ex: `{{ client_name }}`, `{{ count_nc }}`, etc.) avec les données issues de `intake/fiche-projet.html` + `analysis/gap-analysis.xlsx`
3. Inliner le CSS de la charte : remplacer le placeholder `{{ INLINE_CSS_HERE }}` par le contenu de `templates/charte/theodo-healthtech.css`
4. Output final : HTML autonome, prêt pour `/ans-publish`

#### Livrable 1 — `gap-analysis.xlsx` (déjà fait)

Copier `analysis/gap-analysis.xlsx` vers `deliverables/01-gap-analysis.xlsx`.

#### Livrable 2 — `02-executive-summary.html` (≤ 3 pages imprimées)

Template : `templates/deliverables/executive-summary.html.tpl`

Contenu :
- 1 paragraphe : positionnement du client (CE class, finalité, hébergement)
- 1 paragraphe : statut global (% Conforme à étayer / Partiel / NC / À confirmer)
- 5 NC cat. A bloquantes (puces)
- 3 forces du dossier (puces)
- Recommandation pathway (LATM / PECAN / etc.) + calendrier
- Prochaines étapes (3 puces)

Ne pas dépasser 3 pages. Pas de jargon : ce livrable est lu par le COMEX du client.

#### Livrable 3 — `roadmap-P0-P1-P2.html`

Template : `templates/deliverables/roadmap-P0-P1-P2.html.tpl`

Contenu :
- **P0 (avant submission Convergence, sem 0-4)** : NC cat. A bloquantes + actions client immédiates (raccordement PSC, INSi, attestation HDS, AIPD)
- **P1 (avant 1ère revue Convergence, sem 4-12)** : matrice RBAC, PGI, plan identitovigilance, Annuaire Santé
- **P2 (amélioration continue, sem 12+)** : 2FA mandatory, FranceConnect+, Annuaire Santé MSSanté complet, idle timeout, INS template PDF

Pour chaque action : référence à l'exigence DMN concernée + ETA estimé + responsable interne client.

#### Livrable 4 — `note-positionnement-INS.html`

Template selon le rôle INS choisi en jalon 1 (V0.4 — terminologie ANS, cf.
`referentiel_identites_qualification.md` § 5) :
- **Référentiel d'identité** (`voie_a`) : `templates/deliverables/note-positionnement-INS-Voie-A.html.tpl`
- **Esclave d'identité** (`voie_b`) : `templates/deliverables/note-positionnement-INS-Voie-B.html.tpl`

Le titre + corps du livrable doit utiliser **« Référentiel d'identité »** ou
**« Esclave d'identité »** (jamais « Voie A » / « Voie B » en texte client —
ces labels ne portent aucune sémantique métier pour l'INS).

Contenu (rôle Référentiel d'identité) :
- Référence au Guide INS V3.0 §1.2
- Justification du statut « référentiel d'identité » (note d'extension)
- Liste des ~30 exigences INS étendues acceptées
- Plan d'action pour la qualification INSi (raccordement, certificats CPx ou IGC-Santé)
- Impact organisationnel (RAQ, équipe identitovigilance)
- Signatures attendues : RAQ client + DPO client

Contenu (rôle Esclave d'identité) :
- Référence au Guide INS V3.0 §2.2.2
- Justification du statut « esclave d'identité » (consommateur de flux INS qualifié)
- Architecture cible : réception flux IHE PAM depuis SI prescripteur
- Liste des exigences retirées (~30)
- Liste des exigences résiduelles (INS 1, 2, 3, 5, 7-10, 41, 42-44, 45)

Cette note doit être signée par le client RAQ + DPO et téléversée dans Convergence.

#### Livrable 5 — `plan-gestion-identites.html` (PGI squelette, applicable Voie A)

Template : `templates/deliverables/plan-gestion-identites.html.tpl`

Contenu :
- Périmètre (référentiel d'identités hors / en ES)
- Acteurs : RAQ identitovigilance, DPO, support, équipe support
- Procédures :
  - Création d'identité (saisie manuelle, INSi)
  - Qualification (machine à états : provisoire → récupérée → validée → qualifiée)
  - Modification (traits stricts vs complémentaires)
  - Détection doublons et fusion
  - Gestion des homonymes
  - Gestion des identités douteuses / fictives
  - Rétrogradation et invalidation
- Outils : INSi proxy, audit log identité, dashboard identitovigilance
- KPIs : nb identités qualifiées / total, nb fusions / mois, etc.

Squelette à compléter par le client. Marquer clairement les sections « À compléter par le RAQ client » vs sections pré-remplies.

#### Livrable 6 — `matrice-rbac-identite.html`

Template : `templates/deliverables/matrice-rbac-identite.html.tpl`

Contenu : tableau Markdown rôles × actions × droits. Lignes = rôles du client (depuis fiche projet). Colonnes = actions sur identité (consulter, créer, modifier strict, modifier complémentaire, qualifier, fusionner, rétrograder, archiver, exporter).

Cellules : ✓ / ✗. Note de bas de table pour les cas spéciaux.

Squelette à compléter avec les rôles spécifiques client.

#### Livrable 7 — `dpia-template.html`

Template : `templates/deliverables/dpia-template.html.tpl` (basé sur le modèle CNIL)

Contenu :
- Identification du traitement (finalité, base légale, durée conservation)
- Description du traitement (catégories de données, destinataires, sous-traitants)
- Évaluation des risques (sources, mesures de sécurité, impact sur les personnes)
- Mesures pour traiter les risques
- Validation (DPO, responsable de traitement)

Squelette à compléter par le client DPO. Lister les contraintes spécifiques au pathway DMN du client.

#### Livrable 8 — `lettre-demande-PSC.html`

Template : `templates/deliverables/lettre-demande-PSC.html.tpl`

Contenu :
- Lettre type pour la demande de raccordement PSC sur https://industriels.esante.gouv.fr
- Identification du produit, finalité, profils utilisateurs
- Engagement de respect du référentiel PSC v3 (cf. PSC 3)
- Calendrier de raccordement (sandbox ≈ 1 sem, prod ≈ 4-8 sem)
- Document à signer par RAQ client puis téléversé sur le portail iSC

#### Livrable 9 — `lettre-demande-INSi.html`

Template : `templates/deliverables/lettre-demande-INSi.html.tpl`

Contenu :
- Lettre type pour le contrat avec le GIE Sesam-Vitale (téléservice INSi)
- Choix d'authentification : CPx individuelles ou IGC-Santé organisation (recommandation = organisation pour SaaS)
- Calendrier prévisionnel du raccordement
- Engagements opérationnels (procédure d'identitovigilance, traçabilité des appels)

Note : seulement si Voie A INS retenue.

#### Livrable 10 — `lettre-demande-MSSante.html`

Template : `templates/deliverables/lettre-demande-MSSante.html.tpl`

Contenu :
- Lettre type pour le raccordement MSSanté (opérateur tiers OU DNS organisation)
- Cas d'usage prévu (messagerie HCP→HCP, alimentation DMP)
- Choix opérateur ou DNS organisation

Note : seulement si la fiche projet identifie un cas d'usage messagerie (sinon `Non applicable` à expliciter dans la note).

### 4. Vérification cross-livrables

Avant de finaliser, vérifie la cohérence :
- [ ] La roadmap P0/P1/P2 cite les NC cat. A du gap-analysis.xlsx
- [ ] La note de positionnement INS est cohérente avec la Voie décidée en jalon 1
- [ ] La matrice RBAC liste tous les rôles vus dans le gap (Section 5)
- [ ] La DPIA mentionne les sous-traitants identifiés en intake
- [ ] Les 3 lettres de demande sont applicables aux profils retenus

Si incohérence → corriger avant de produire le brief jalon 3.

### 5. Brief de revue jalon 3 — V0.3 (humain + machine-readable)

Génère **deux** fichiers en sortie :

#### a) `briefs-revue/jalon-3-pre-kit.md` (humain, ≤ 2 pages)

Voir gabarit Sunrise (`/Users/nicolasbertrand/missions/Sunrise/briefs-revue/jalon-3-pre-kit.md`) pour la structure : Inventaire / Cohérence cross-livrables / Points de discussion / Risques résiduels / Demande de validation.

#### b) `briefs-revue/jalon-3-decision-points.json` (machine-readable, schema decision-points.v1.json)

Auto-render dans le formulaire UI Jalon 3. Pour chaque point de discussion ou check de cohérence cross-livrables, émet une entrée :

```json
{
  "schema_version": "v1",
  "mission_id": "{{ args }}",
  "generated_at": "<iso>",
  "points": [
    {
      "id": "jalon-3.1-validation-prekit",
      "title": "Validation pré-kit pour remise client",
      "type": "radio",
      "options": ["Validé", "Corrections finales"],
      "criticality": "blocking",
      "category": "validation"
    },
    {
      "id": "jalon-3.2-coherence-roadmap-cite-nc-cat-a",
      "title": "Roadmap P0/P1/P2 cite les NC Cat. A",
      "type": "ack_only",
      "criticality": "blocking",
      "category": "coherence_cross_livrables",
      "auto_check_outcome": "pass",
      "linked_artefacts": ["deliverables/03-roadmap-P0-P1-P2.html", "deliverables/01-gap-analysis.xlsx"]
    },
    {
      "id": "jalon-3.5-INS-17-1-V5-vs-V6",
      "title": "Décision INS 17.1 — V5 (Conforme à étayer) vs V6 (Non applicable)",
      "type": "radio",
      "options": ["Confirme V6 (N/A — symétrique aux 31 autres)", "Restaure V5 (Conforme à étayer — carve-out)"],
      "recommended_default": "Confirme V6 (N/A — symétrique aux 31 autres)",
      "rationale": "V5 avait gardé Conforme à étayer (carve-out). V6 a reclassé N/A symétriquement aux 31 autres scénarios profil Référentiel d'identités.",
      "criticality": "blocking",
      "category": "mission_specific"
    }
    /* ... etc */
  ]
}
```

Les `auto_check_outcome` sont calculés par parsing des livrables (e.g., grep des NC Cat. A dans roadmap). UI affiche les checks `pass` cochés par défaut, `fail` rouges, le DP confirme/débraye/override-with-rationale.

### 6. Output au PM

```
Pré-kit Convergence {{ args }} — produit dans deliverables/.

10 livrables :
1. gap-analysis.xlsx (final)
2. executive-summary.html
3. roadmap-P0-P1-P2.html
4. note-positionnement-INS.html (Voie A/B selon décision)
5. plan-gestion-identites.html (squelette, à compléter client)
6. matrice-rbac-identite.html (squelette)
7. dpia-template.html
8. lettre-demande-PSC.html
9. lettre-demande-INSi.html (si Voie A)
10. lettre-demande-MSSante.html (si applicable)

Cohérence cross-livrables : OK / corrections nécessaires (cf. brief jalon 3).

Lis briefs-revue/jalon-3-pre-kit.md, prépare la réunion DP avec ce brief.
Après validation DP, le pré-kit est prêt pour remise au client.
```

## Discipline

- Aucun livrable ne doit contenir des verdicts « inventés » non issus du gap-analysis.xlsx
- Les templates sont **squelettes** — clairement marquer les sections à compléter par le client (ne pas faire semblant que c'est rempli)
- La note de positionnement INS est **signée par le client**, pas par Theodo (Theodo l'a rédigée, le client porte la responsabilité)
