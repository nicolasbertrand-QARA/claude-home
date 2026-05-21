<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{ client_name }} — Synthèse exécutive ANS</title>
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
    <h1>{{ client_name }} — Synthèse <em>exécutive</em> ANS</h1>
    <p class="sub">Pré-kit Convergence DMN V1.2.2 — résultats d'audit gap analysis</p>
  </div>
  <div class="head-r">
    <span class="br">theodo<span class="dot"></span><span class="sub">HealthTech</span></span>
    {{ date_delivery }} · Mission {{ pm_name }}
  </div>
</header>

<nav class="toc">
  <a href="#s1"><span>01</span>Positionnement</a>
  <a href="#s2"><span>02</span>Statut conformité</a>
  <a href="#s3"><span>03</span>Bloquants A</a>
  <a href="#s4"><span>04</span>Forces</a>
  <a href="#s5"><span>05</span>Pathway</a>
  <a href="#s6"><span>06</span>Prochaines étapes</a>
  <a href="#s7"><span>07</span>Livrables</a>
</nav>

<!--
  V0.4 Lot 4 / A3 — Bandeau "livrable sous réserve".
  Substituer par le helper `render_pending_evidence_banner()` du builder
  HTML, qui renvoie le bloc ci-dessous SI
  dp_decisions.jalon_3.delivery_with_pending_evidence est non vide :

  <aside class="callout warn" style="margin-bottom:24px;border-left:4px solid #d4a017;background:#fff8e6;padding:12px 16px;">
    <strong style="color:#a5780f;">⚠ Livrable sous réserve — version preliminary</strong>
    <p style="margin:6px 0 0;">
      Ce pré-kit est remis sous réserve. Le DP a signé un override
      « delivery_with_pending_evidence » couvrant les éléments suivants,
      à régulariser avant submission Convergence&nbsp;:
    </p>
    <ul style="margin:6px 0 0 20px;">
      {{ pending_evidence_items_html }}
    </ul>
    <p style="margin:6px 0 0;font-size:0.88rem;color:#666;">
      Date de régularisation prévue&nbsp;: {{ pending_evidence_due_date }}
      · Signature DP&nbsp;: {{ pending_evidence_dp_signed_at }}
    </p>
  </aside>

  Si le tableau est vide (cas nominal — livrable final), ne rien rendre.
-->
{{ pending_evidence_banner_html }}

<main>

<section id="s1">
  <div class="sec-title">
    <span class="num">01</span>
    <h2>Positionnement {{ client_name }} face à l'ANS</h2>
  </div>

  <p class="lead">
    {{ client_name }} est un <strong>{{ samd_type }}</strong> {{ medical_purpose }}, classé <strong>{{ ce_class }}</strong> sous MDR (règle {{ ce_rule }}), hébergé en <strong>{{ hosting }}</strong>. Le produit cible le pathway <strong>{{ pathway }}</strong> avec une cible de submission Convergence en <strong>{{ target_convergence }}</strong>.
  </p>

  <p>L'analyse couvre les <strong>103 scénarios de conformité</strong> du référentiel ANS DMN V1.2.2 sur les profils applicables :</p>
  <ul>
    {{ profils_applicables_list_html }}
  </ul>
</section>

<section id="s2">
  <div class="sec-title">
    <span class="num">02</span>
    <h2>Statut global de conformité</h2>
  </div>

  <table class="tbl">
    <thead>
      <tr><th>Statut</th><th>Nombre</th><th>%</th></tr>
    </thead>
    <tbody>
      <tr><td>Conforme</td><td>{{ count_conforme }}</td><td>{{ pct_conforme }}</td></tr>
      <tr><td>Conforme à étayer</td><td>{{ count_a_etayer }}</td><td>{{ pct_a_etayer }}</td></tr>
      <tr><td>Partiel</td><td>{{ count_partiel }}</td><td>{{ pct_partiel }}</td></tr>
      <tr><td><strong>Non conforme</strong></td><td><strong>{{ count_nc }}</strong></td><td><strong>{{ pct_nc }}</strong></td></tr>
      <tr><td>Non applicable</td><td>{{ count_na }}</td><td>{{ pct_na }}</td></tr>
      <tr><td>À confirmer</td><td>{{ count_a_confirmer }}</td><td>{{ pct_a_confirmer }}</td></tr>
    </tbody>
  </table>

  <div class="callout">
    {{ summary_interpretation }}
  </div>
</section>

<section id="s3">
  <div class="sec-title">
    <span class="num">03</span>
    <h2>{{ count_nc_cat_a }} non-conformités catégorie A — bloquantes</h2>
    <span class="meta">À régler avant submission Convergence</span>
  </div>

  <div class="grid-2">
    {{ nc_cat_a_blocks_html }}
  </div>
</section>

<section id="s4">
  <div class="sec-title">
    <span class="num">04</span>
    <h2>Forces du dossier</h2>
  </div>

  <ul>
    {{ strengths_list_html }}
  </ul>
</section>

<section id="s5">
  <div class="sec-title">
    <span class="num">05</span>
    <h2>Recommandation pathway et calendrier</h2>
  </div>

  <p class="lead"><strong>Pathway recommandé</strong> : {{ pathway_recommendation }}</p>

  <h3>Calendrier prévisionnel</h3>
  <ol>
    {{ pathway_timeline_html }}
  </ol>
</section>

<section id="s6">
  <div class="sec-title">
    <span class="num">06</span>
    <h2>Prochaines étapes pour {{ client_name }}</h2>
  </div>

  <ol>
    <li><strong>Sem 0-2</strong> — engager les démarches P0 (raccordement PSC, INSi, attestation HDS, AIPD)</li>
    <li><strong>Sem 2-8</strong> — implémenter les NC cat. A bloquantes (cf. roadmap P0)</li>
    <li><strong>Sem 8-16</strong> — produire les preuves UI manquantes (« Conforme à étayer »)</li>
    <li><strong>Sem 16+</strong> — submission Convergence — accompagnement Theodo possible en mission de suivi</li>
  </ol>
</section>

<section id="s7">
  <div class="sec-title">
    <span class="num">07</span>
    <h2>Livrables joints à ce pré-kit</h2>
  </div>

  <table class="tbl">
    <thead>
      <tr><th>#</th><th>Livrable</th><th>Statut</th></tr>
    </thead>
    <tbody>
      <tr><td>1</td><td>Gap analysis détaillée (XLSX, 103 scénarios)</td><td><span class="tag ok">Final</span></td></tr>
      <tr><td>2</td><td>Synthèse exécutive (ce document)</td><td><span class="tag ok">Final</span></td></tr>
      <tr><td>3</td><td>Roadmap P0/P1/P2</td><td><span class="tag ok">Final</span></td></tr>
      <tr><td>4</td><td>Note de positionnement INS — {{ voie_ins }}</td><td><span class="tag warn">À signer par RAQ + DPO</span></td></tr>
      <tr><td>5</td><td>Plan de gestion des identités (squelette)</td><td><span class="tag warn">À compléter</span></td></tr>
      <tr><td>6</td><td>Matrice RBAC × identité (squelette)</td><td><span class="tag warn">À compléter</span></td></tr>
      <tr><td>7</td><td>DPIA template (modèle CNIL)</td><td><span class="tag warn">À compléter par DPO</span></td></tr>
      <tr><td>8</td><td>Lettre demande raccordement PSC</td><td><span class="tag warn">À signer par RAQ</span></td></tr>
      <tr><td>9</td><td>Lettre demande raccordement INSi</td><td>{{ insi_letter_status }}</td></tr>
      <tr><td>10</td><td>Lettre demande raccordement MSSanté</td><td>{{ mssante_letter_status }}</td></tr>
    </tbody>
  </table>

  <h3>Contact Theodo</h3>
  <p><strong>{{ pm_name }}</strong>, PM mission — <span class="mono">{{ pm_email }}</span></p>
  <p><strong>{{ dp_name }}</strong>, DP — <span class="mono">{{ dp_email }}</span></p>

  <p class="note">Theodo reste disponible pour une mission de suivi (implémentation des recommandations + accompagnement Convergence) — devis sur demande.</p>
</section>

</main>

<footer>
  <span>Synthèse exécutive · {{ client_name }} · {{ date_delivery }}</span>
  <span><span class="y">theodo. HealthTech</span> · usage interne · ne pas diffuser sans accord</span>
</footer>

</body>
</html>
