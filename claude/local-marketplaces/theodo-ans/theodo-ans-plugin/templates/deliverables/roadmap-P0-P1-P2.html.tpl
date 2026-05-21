<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{ client_name }} — Roadmap mise en conformité ANS DMN</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&family=Public+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
/* {{ INLINE_CSS_HERE — substituer par le contenu de templates/charte/theodo-healthtech.css }} */
</style>
</head>
<body>

<header class="head">
  <div class="head-l">
    <h1>{{ client_name }} — Roadmap <em>P0/P1/P2</em></h1>
    <p class="sub">Mise en conformité ANS DMN V1.2.2 — pathway {{ pathway }} · cible Convergence {{ target_convergence }}</p>
  </div>
  <div class="head-r">
    <span class="br">theodo<span class="dot"></span><span class="sub">HealthTech</span></span>
    {{ date_delivery }} · Pré-kit Convergence
  </div>
</header>

<nav class="toc">
  <a href="#p0"><span>P0</span>Avant submission</a>
  <a href="#p1"><span>P1</span>Avant 1ère revue</a>
  <a href="#p2"><span>P2</span>Amélioration continue</a>
  <a href="#recap"><span>RC</span>Récap effort</a>
</nav>

<main>

<div class="callout">
  P0 = <strong>bloquant</strong> (sans cela, pas de submission). P1 = avant la 1ère revue Convergence. P2 = amélioration continue, peut être post-submission.
</div>

<section id="p0">
  <div class="sec-title">
    <span class="num">P0</span>
    <h2>Avant submission Convergence (sem 0-{{ p0_deadline_weeks }})</h2>
    <span class="meta">Effort total {{ p0_total_effort }}</span>
  </div>

  <h3>P0.1 — Raccordements ANS (à initier en parallèle)</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr>
        <td>Demande de raccordement Pro Santé Connect (sandbox)</td>
        <td><span class="id">PSC 1.1</span> <span class="id">PSC 2.1</span></td>
        <td>1 sem (admin) + 6-8 sem (dev OIDC)</td>
        <td>RAQ + Tech Lead</td>
        <td>sem 1 (demande) → sem 9 (prod)</td>
      </tr>
      <tr>
        <td>Contrat GIE Sesam-Vitale pour téléservice INSi</td>
        <td><span class="id">INS 37</span> <span class="id t">INS 39</span> <span class="id">INS 40</span></td>
        <td>4-6 sem (contrat + cert CPx ou IGC-Santé organisation)</td>
        <td>RAQ + Direction</td>
        <td>sem 1 (init) → sem 6 (signature)</td>
      </tr>
      <tr>
        <td>Attestation HDS de l'hébergeur</td>
        <td><span class="id">RGPD 1.1</span> + sous-thème HDS</td>
        <td>0-3 mois selon état</td>
        <td>RAQ + DSI</td>
        <td><span class="tag alert">À confirmer (1ère action)</span></td>
      </tr>
      <tr>
        <td>Création iSC sur Convergence</td>
        <td>Pré-requis</td>
        <td>1 sem</td>
        <td>RAQ</td>
        <td>sem 1</td>
      </tr>
    </tbody>
  </table>

  <h3>P0.2 — RGPD / DPIA</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr><td>Réaliser AIPD / DPIA (modèle CNIL)</td><td>RGPD art. 35</td><td>4-6 sem</td><td>DPO</td><td>sem 0-6</td></tr>
      <tr><td>Compiler registre des traitements (art. 30)</td><td>RGPD art. 30</td><td>1-2 sem</td><td>DPO</td><td>sem 1-3</td></tr>
      <tr><td>Vérifier DPA hébergeur avec addendum santé</td><td>RGPD art. 28</td><td>1 sem</td><td>DPO + Direction</td><td>sem 1-2</td></tr>
    </tbody>
  </table>

  <h3>P0.3 — Identité (Voie {{ voie_ins }})</h3>
  {{ voie_a_or_b_section_html }}

  <h3>P0.4 — Note de positionnement INS</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr>
        <td>Faire signer la note de positionnement INS — {{ voie_ins }} (livrée dans ce pré-kit)</td>
        <td>Guide INS V3.0 §1.2</td>
        <td>1 sem</td>
        <td>RAQ + DPO</td>
        <td>sem 1-2</td>
      </tr>
    </tbody>
  </table>
</section>

<section id="p1">
  <div class="sec-title">
    <span class="num">P1</span>
    <h2>Avant 1ère revue Convergence (sem {{ p0_deadline_weeks }}-{{ p1_deadline_weeks }})</h2>
    <span class="meta">Effort total {{ p1_total_effort }}</span>
  </div>

  <p class="note">Ces actions enrichissent le dossier mais ne bloquent pas la submission initiale.</p>

  <h3>P1.1 — Procédures et SOPs</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr><td>Compléter le Plan de gestion des identités (livré en squelette)</td><td><span class="id">INS 4</span> + Voie A</td><td>4-6 sem</td><td>RAQ identitovigilance</td><td>sem 6-12</td></tr>
      <tr><td>Compléter la matrice RBAC × identité (livrée en squelette)</td><td><span class="id">ADM 1.1</span> <span class="id">INS 5</span></td><td>2-3 sem</td><td>RAQ + Tech Lead</td><td>sem 8-11</td></tr>
      <tr><td>Procédure d'identitovigilance (création / qualification / fusion / homonymes)</td><td><span class="id">INS 17, 22-28</span></td><td>4 sem</td><td>RAQ identitovigilance</td><td>sem 8-12</td></tr>
      <tr><td>Procédure de réaction aux incidents cyber (signalement CERT Santé)</td><td>PGSSI-S</td><td>2 sem</td><td>DSI + RAQ</td><td>sem 6-8</td></tr>
    </tbody>
  </table>

  <h3>P1.2 — Annuaire Santé et MSSanté</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr><td>Intégration Annuaire Santé (FHIR R4 Practitioner / PractitionerRole)</td><td><span class="id">ANN 1-5</span></td><td>4-6 sem</td><td>Tech Lead</td><td>sem 8-14</td></tr>
      <tr><td>Raccordement MSSanté (opérateur ou DNS organisation)</td><td><span class="id">ANN 5</span> + MSSanté</td><td>8-12 sem</td><td>Tech Lead + RAQ</td><td>sem 6-18 (si applicable)</td></tr>
    </tbody>
  </table>

  <h3>P1.3 — Captures UI authentifiées</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr><td>Captures de tous les flux marqués « Conforme à étayer »</td><td>{{ count_a_etayer }} exigences</td><td>1-2 sem</td><td>PM client + QA</td><td>sem 12-14</td></tr>
    </tbody>
  </table>
</section>

<section id="p2">
  <div class="sec-title">
    <span class="num">P2</span>
    <h2>Amélioration continue (sem {{ p1_deadline_weeks }}+)</h2>
    <span class="meta">Optimisations post-submission</span>
  </div>

  <h3>P2.1 — Authentification renforcée</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr><td>Imposer la 2FA Usager OU raccordement FranceConnect+</td><td><span class="id t">IEU 9.1</span></td><td>3-4 sem (A) ou 8-12 sem (B)</td><td>Tech Lead</td><td>sem 16+</td></tr>
      <tr><td>Idle timeout côté Platform et App</td><td><span class="id">IEPS 13</span> <span class="id">IEU 12</span></td><td>1-2 sem</td><td>Tech Lead</td><td>sem 16+</td></tr>
      <tr><td>Politique mot de passe — passer à 12 chars min ou aligner SRS avec UI/REP</td><td><span class="id">IEPS 9.2</span></td><td>1 sem</td><td>Tech Lead</td><td>sem 16+</td></tr>
    </tbody>
  </table>

  <h3>P2.2 — Format d'export interopérable</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr><td>Mapping documenté → FHIR R4 → CI-SIS FR Core</td><td><span class="id">PORT 1.1</span></td><td>4-6 sem</td><td>Tech Lead + Architecte</td><td>sem 16+</td></tr>
      <tr><td>Inclusion INS + OID dans Patient.identifier de l'export</td><td><span class="id">PORT 1.1</span> + INS</td><td>1-2 sem</td><td>Tech Lead</td><td>post INS</td></tr>
    </tbody>
  </table>

  <h3>P2.3 — Template PDF avec INS</h3>
  <table class="tbl">
    <thead>
      <tr><th>Action</th><th>Exigence</th><th>Effort</th><th>Responsable</th><th>ETA</th></tr>
    </thead>
    <tbody>
      <tr><td>Refonte template avec champs RNIV + code-barres INS</td><td><span class="id">INS 42-44</span></td><td>3-4 sem</td><td>Tech Lead</td><td>post INS</td></tr>
    </tbody>
  </table>
</section>

<section id="recap">
  <div class="sec-title">
    <span class="num">RC</span>
    <h2>Récap effort {{ client_name }}</h2>
  </div>

  <table class="tbl">
    <thead>
      <tr><th>Phase</th><th>Effort estimé</th><th>Coût indicatif</th></tr>
    </thead>
    <tbody>
      <tr><td>P0</td><td>{{ p0_total_effort }}</td><td>{{ p0_total_cost }}</td></tr>
      <tr><td>P1</td><td>{{ p1_total_effort }}</td><td>{{ p1_total_cost }}</td></tr>
      <tr><td>P2</td><td>{{ p2_total_effort }}</td><td>{{ p2_total_cost }}</td></tr>
      <tr><td><strong>Total avant submission</strong></td><td><strong>{{ total_pre_submission_effort }}</strong></td><td><strong>{{ total_pre_submission_cost }}</strong></td></tr>
    </tbody>
  </table>

  <p class="note">Theodo Tech peut accompagner sur les phases P0, P1, P2 — devis sur demande.</p>
</section>

</main>

<footer>
  <span>Roadmap P0/P1/P2 · {{ client_name }} · {{ date_delivery }}</span>
  <span><span class="y">theodo. HealthTech</span> · usage interne</span>
</footer>

</body>
</html>
