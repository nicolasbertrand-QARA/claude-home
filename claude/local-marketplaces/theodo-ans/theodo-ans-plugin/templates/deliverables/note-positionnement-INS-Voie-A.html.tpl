<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{ client_name }} — Note de positionnement INS Voie A</title>
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
    <h1>Note de positionnement <em>INS Voie A</em> — {{ client_product_name }}</h1>
    <p class="sub">Référentiel d'identités au sens INS · Guide d'implémentation INS V3.0 (ANS, déc. 2024)</p>
  </div>
  <div class="head-r">
    <span class="br">theodo<span class="dot"></span><span class="sub">HealthTech</span></span>
    {{ date_delivery }} · À signer par RAQ + DPO {{ client_name }}
  </div>
</header>

<nav class="toc">
  <a href="#s1"><span>01</span>Objet</a>
  <a href="#s2"><span>02</span>Référence opposable</a>
  <a href="#s3"><span>03</span>Définition</a>
  <a href="#s4"><span>04</span>Application</a>
  <a href="#s5"><span>05</span>Décision</a>
  <a href="#s6"><span>06</span>Validation</a>
</nav>

<main>

<section id="s1">
  <div class="sec-title">
    <span class="num">01</span>
    <h2>Objet</h2>
  </div>

  <p class="lead">
    Cette note formalise le <strong>positionnement de {{ client_product_name }}</strong> au regard du statut de logiciel <strong>« référentiel d'identités »</strong> tel que défini par le Guide d'implémentation de l'INS V3.0 (ANS, décembre 2024). Elle est annexée au dossier Convergence DMN V1.2.2.
  </p>
</section>

<section id="s2">
  <div class="sec-title">
    <span class="num">02</span>
    <h2>Référence opposable</h2>
  </div>

  <div class="block">
    <h4>Source primaire</h4>
    <p>Guide d'implémentation de l'INS V3.0 — décembre 2024 — ANS / Délégation au numérique en santé.</p>
    <p class="mono">https://esante.gouv.fr/sites/default/files/media/document/ANS_Guide-Implementation-INS_V3.0.pdf</p>
    <p class="note">Statut : Validé, classification publique, annexé au Référentiel INS v2.1 (arrêté du 13 décembre 2024) → opposable aux éditeurs.</p>
  </div>
</section>

<section id="s3">
  <div class="sec-title">
    <span class="num">03</span>
    <h2>Définition retenue</h2>
  </div>

  <p>Selon le Guide INS V3.0 §1.2 p.5, un référentiel d'identités est un logiciel qui permet <strong>la création / la modification / la fusion</strong> des identités.</p>

  <div class="callout">
    <strong>Note d'extension §1.2 p.5</strong> — « Les solutions d'amont de prise de rendez-vous / préconsultation / préadmission, mettant directement à contribution l'usager pour la gestion de son identité numérique, s'apparentent à un logiciel référentiel d'identités. »
  </div>
</section>

<section id="s4">
  <div class="sec-title">
    <span class="num">04</span>
    <h2>Application à {{ client_product_name }}</h2>
  </div>

  <h3>4.1 — Faits relevés en intake</h3>
  <p>{{ intake_facts_summary }}</p>

  <h3>4.2 — Analyse</h3>
  <p>{{ client_product_name }} :</p>
  <ol>
    <li><strong>Permet à l'usager (patient) de saisir lui-même ses traits d'identité</strong> via {{ self_register_path }}.</li>
    <li>{{ hcp_creation_text }}.</li>
    <li>{{ insi_text }}.</li>
  </ol>

  <p>Conformément à la note d'extension du Guide INS V3.0 §1.2 p.5, le fait que l'usager mette directement à contribution sa propre identité numérique <strong>suffit à qualifier {{ client_product_name }} de logiciel référentiel d'identités</strong>, indépendamment de l'appel ou non au téléservice INSi.</p>

  <h3>4.3 — Précision §1.6 p.9</h3>
  <div class="block warm">
    <p>« La création d'une identité au sein du logiciel peut se faire indépendamment de la récupération de l'INS. Il est toutefois recommandé de procéder à la qualification de l'INS le plus tôt possible. »</p>
  </div>
  <p>Le fait que {{ client_product_name }} ne fasse pas (encore) appel au téléservice INSi <strong>ne le sort pas du statut de référentiel d'identités</strong>. C'est un défaut de conformité (<span class="id">INS 37</span> <span class="id">INS 38</span> <span class="id">INS 40</span>), pas une qualification différente.</p>
</section>

<section id="s5">
  <div class="sec-title">
    <span class="num">05</span>
    <h2>Décision</h2>
  </div>

  <h3>5.1 — Voie retenue</h3>
  <div class="callout">
    {{ client_name }} <strong>assume le statut de logiciel référentiel d'identités</strong> (Voie A), conformément à l'analyse ci-dessus.
  </div>

  <h3>5.2 — Conséquences pour le dossier Convergence</h3>
  <p>Application des <strong>~30 exigences INS étendues</strong> :</p>

  <table class="tbl">
    <thead>
      <tr><th>Exigence</th><th>Sujet</th><th>Statut actuel</th></tr>
    </thead>
    <tbody>
      <tr><td><span class="id">INS 1, 2, 3, 5, 7, 8, 9, 10</span></td><td>Champs RNIV + recherche d'antériorité</td><td>{{ ins_general_status }}</td></tr>
      <tr><td><span class="id">INS 4, 6, 11-35</span></td><td>Statuts d'identité, traits stricts/complémentaires, vigilance, fusion</td><td>{{ ins_extended_status }}</td></tr>
      <tr><td><span class="id">INS 37, 38, 40</span></td><td>Téléservice INSi (récupération + recherche)</td><td>{{ insi_status }}</td></tr>
      <tr><td><span class="id t">INS 39</span></td><td>Authentification CPx ou IGC-Santé organisation</td><td>{{ ins_39_status }}</td></tr>
      <tr><td><span class="id">INS 41</span></td><td>Traçabilité des partages INS</td><td>{{ ins_41_status }}</td></tr>
      <tr><td><span class="id">INS 42, 43, 44</span></td><td>Affichage INS sur sortie papier / PDF</td><td>{{ ins_42_44_status }}</td></tr>
      <tr><td><span class="id">INS 45</span></td><td>Intégration de flux (IHE PAM / HL7 ADT)</td><td>{{ ins_45_status }}</td></tr>
      <tr><td><span class="id t">IEU 7</span> <span class="id">IEU 8</span></td><td>INS comme identifiant Usager</td><td>{{ ieu_7_8_status }}</td></tr>
    </tbody>
  </table>

  <h3>5.3 — Plan d'action</h3>
  <p>{{ client_name }} s'engage à :</p>

  <h4>Court terme (P0)</h4>
  <ul>
    <li>Signer le contrat GIE Sesam-Vitale pour le téléservice INSi</li>
    <li>Choisir le mode d'authentification : CPx individuelles ou certificat IGC-Santé organisation</li>
    <li>Étendre le modèle Patient avec les champs RNIV (matricule INS, OID, nom de naissance, premier prénom, sexe RNIV, code INSEE lieu de naissance, etc.)</li>
  </ul>

  <h4>Moyen terme (P1)</h4>
  <ul>
    <li>Implémenter la machine à états d'identité (provisoire → récupérée → validée → qualifiée)</li>
    <li>Désigner un RAQ identitovigilance et adopter une procédure conforme à la doctrine 3RIV</li>
    <li>Intégrer l'INS qualifiée sur les sorties papier / PDF (règle 32 du Guide)</li>
    <li>Mettre en place la traçabilité des partages INS (<span class="id">INS 41</span>)</li>
  </ul>

  <h4>Long terme (P2)</h4>
  <ul>
    <li>Préparer l'intégration de flux IHE PAM en réception (<span class="id">INS 45</span>) pour les déploiements en ES futurs</li>
  </ul>

  <p class="note">Le calendrier détaillé figure dans le livrable <em>roadmap-P0-P1-P2</em> du pré-kit Convergence.</p>

  <h3>5.4 — Refus argumenté de la Voie B</h3>
  <p>Voie B (logiciel non-référentiel d'identités) impliquerait que {{ client_product_name }} :</p>
  <ul>
    <li>Ne permette plus à l'usager de s'auto-inscrire</li>
    <li>Reçoive l'identité par flux IHE PAM depuis un SI prescripteur (LGC, SIH)</li>
  </ul>
  <p>Cette refonte casserait le modèle de service de {{ client_product_name }} ({{ business_model_argument }}). Voie A est donc préférable malgré son coût d'implémentation supérieur.</p>

  <h3>5.5 — Refus argumenté de la Voie C</h3>
  <p>Voie C (« hors cercle de confiance ») n'est pas applicable car {{ client_product_name }} :</p>
  <ul>
    <li>Édite des données de santé partagées avec un professionnel de santé prescripteur (article L.1111-8-1 du Code de la santé publique)</li>
    <li>Participe au cercle de confiance par construction de son cas d'usage médical</li>
  </ul>
</section>

<section id="s6">
  <div class="sec-title">
    <span class="num">06</span>
    <h2>Validation</h2>
  </div>

  <h3>6.1 — Signataires {{ client_name }}</h3>
  <table class="tbl">
    <thead>
      <tr><th>Rôle</th><th>Nom</th><th>Date</th><th>Signature</th></tr>
    </thead>
    <tbody>
      <tr><td>RAQ {{ client_name }}</td><td>{{ raq_name }}</td><td></td><td></td></tr>
      <tr><td>DPO {{ client_name }}</td><td>{{ dpo_name }}</td><td></td><td></td></tr>
      <tr><td>Direction {{ client_name }} (optionnel)</td><td>{{ director_name }}</td><td></td><td></td></tr>
    </tbody>
  </table>

  <h3>6.2 — Validation Theodo QARA</h3>
  <p class="note">Cette note a été préparée par Theodo QARA sur la base de l'intake du <strong>{{ date_intake }}</strong> et des documents fournis par {{ client_name }}. Theodo n'engage sa responsabilité que sur la qualité de l'analyse documentaire ; la décision et la signature relèvent de {{ client_name }}.</p>

  <table class="tbl">
    <thead>
      <tr><th>Rôle</th><th>Nom</th><th>Date</th></tr>
    </thead>
    <tbody>
      <tr><td>PM Theodo</td><td>{{ pm_name }}</td><td>{{ date_delivery }}</td></tr>
      <tr><td>DP Theodo</td><td>{{ dp_name }}</td><td>{{ date_delivery }}</td></tr>
    </tbody>
  </table>

  <h3>Annexes</h3>
  <ul>
    <li><strong>Annexe A</strong> — Extrait de l'intake validé en jalon 1 (<span class="mono">intake/decisions</span>)</li>
    <li><strong>Annexe B</strong> — Gap analysis détaillée des exigences INS impactées (<span class="mono">gap-analysis.xlsx</span>)</li>
    <li><strong>Annexe C</strong> — Roadmap de mise en conformité (<span class="mono">roadmap-P0-P1-P2</span>)</li>
  </ul>
</section>

</main>

<footer>
  <span>Note de positionnement INS Voie A · {{ client_product_name }} · {{ date_delivery }}</span>
  <span><span class="y">theodo. HealthTech</span> · réf. opposable Guide INS V3.0</span>
</footer>

</body>
</html>
