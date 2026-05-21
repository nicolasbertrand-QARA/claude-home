<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{ client_name }} — Fiche projet intake</title>
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
    <h1>Fiche projet — {{ client_name }} <em>intake</em></h1>
    <p class="sub">Visio jalon 1 du {{ date_intake }} · validation DP signée en fin de séance</p>
  </div>
  <div class="head-r">
    <span class="br">theodo<span class="dot"></span><span class="sub">HealthTech</span></span>
    Mission ANS · {{ pm_name }} (PM) + {{ dp_name }} (DP)
  </div>
</header>

<nav class="toc">
  <a href="#s0"><span>00</span>Cadrage</a>
  <a href="#s1"><span>01</span>Qualification produit</a>
  <a href="#s2"><span>02</span>Architecture</a>
  <a href="#s3"><span>03</span>Profils DMN</a>
  <a href="#s4"><span>04</span>Décisions</a>
  <a href="#s5"><span>05</span>Notes libres</a>
</nav>

<main>

<section id="s0">
  <div class="sec-title">
    <span class="num">00</span>
    <h2>Cadrage</h2>
  </div>

  <table class="tbl">
    <tbody>
      <tr><td>Client (raison sociale)</td><td>{{ client_name }}</td></tr>
      <tr><td>Domaine</td><td>{{ client_domain }}</td></tr>
      <tr><td>RAQ client</td><td>{{ raq_name }} · <span class="mono">{{ raq_email }}</span></td></tr>
      <tr><td>DPO client</td><td>{{ dpo_name }} · <span class="mono">{{ dpo_email }}</span></td></tr>
      <tr><td>PM Theodo</td><td>{{ pm_name }}</td></tr>
      <tr><td>DP Theodo</td><td>{{ dp_name }}</td></tr>
      <tr><td>Date kickoff</td><td>{{ date_kickoff }}</td></tr>
      <tr><td>Cible Convergence</td><td>{{ target_convergence }}</td></tr>
      <tr><td>Pathway visé</td><td>{{ pathway }}</td></tr>
    </tbody>
  </table>
</section>

<section id="s1">
  <div class="sec-title">
    <span class="num">01</span>
    <h2>Qualification produit</h2>
    <span class="meta">DP-CRITICAL</span>
  </div>

  <table class="tbl">
    <tbody>
      <tr><td>1.1 CE-marqué MDR/IVDR</td><td>{{ ce_marked }} · certificat fourni : {{ ce_cert_provided }}</td></tr>
      <tr><td>1.2 Classe</td><td>{{ ce_class }}</td></tr>
      <tr><td>1.3 Règle de classification</td><td>{{ ce_rule }}</td></tr>
      <tr><td>1.4 SaMD / hybride</td><td>{{ samd_type }}</td></tr>
      <tr><td>1.5 Finalité médicale</td><td>{{ medical_purpose }}</td></tr>
      <tr><td>1.6 Modèle ML / IA</td><td>{{ uses_ml }} · détails : {{ ml_details }}</td></tr>
      <tr><td>1.7 Vendu en France</td><td>{{ sold_in_france }} · modalité : {{ sale_modality }}</td></tr>
    </tbody>
  </table>

  <div class="callout">
    <strong>Décision DP qualification produit</strong> : {{ dp_decision_qualification }}
  </div>
</section>

<section id="s2">
  <div class="sec-title">
    <span class="num">02</span>
    <h2>Architecture et flux</h2>
  </div>

  <h3>2.1 — Topologie technique</h3>
  <table class="tbl">
    <tbody>
      <tr><td>Composants</td><td>{{ tech_components }}</td></tr>
      <tr><td>Stack Web</td><td>{{ web_stack }}</td></tr>
      <tr><td>Stack mobile</td><td>{{ mobile_stack }}</td></tr>
      <tr><td>Hébergement</td><td>{{ hosting }}</td></tr>
      <tr><td>HDS attestation</td><td>{{ hds_attestation }}</td></tr>
      <tr><td>HCP portail Web</td><td>{{ hcp_web_portal }}</td></tr>
      <tr><td>Patient interface</td><td>{{ patient_interface }}</td></tr>
    </tbody>
  </table>

  <h3>2.2 — Profils utilisateurs</h3>
  <table class="tbl">
    <thead>
      <tr><th>Profil</th><th>Existe</th><th>Cas d'usage</th></tr>
    </thead>
    <tbody>
      <tr><td>Patient (Usager)</td><td>{{ profile_patient }}</td><td>{{ profile_patient_usecase }}</td></tr>
      <tr><td>Médecin (HCP)</td><td>{{ profile_hcp }}</td><td>{{ profile_hcp_usecase }}</td></tr>
      <tr><td>Admin / éditeur</td><td>{{ profile_admin }}</td><td>{{ profile_admin_usecase }}</td></tr>
      <tr><td>Autres</td><td>{{ profile_others }}</td><td>{{ profile_others_usecase }}</td></tr>
    </tbody>
  </table>

  <h3>2.3 — Flux d'identification patient — DP-CRITICAL</h3>
  <table class="tbl">
    <tbody>
      <tr><td>2.3.1 Auto-inscription patient</td><td>{{ patient_self_register }}</td></tr>
      <tr><td>2.3.2 Création par HCP / opérateur</td><td>{{ creation_by_hcp }}</td></tr>
      <tr><td>2.3.3 Réception flux entrant (IHE PAM, ADT)</td><td>{{ flux_entrant }}</td></tr>
      <tr><td>2.3.4 Appel téléservice INSi</td><td>{{ insi_call }}</td></tr>
      <tr><td>2.3.5 Sortie papier/PDF avec identité</td><td>{{ paper_output }}</td></tr>
    </tbody>
  </table>

  <div class="callout">
    <strong>Décision DP — Voie INS</strong> : {{ dp_decision_voie_ins }}
  </div>

  <h3>2.4 — Flux d'identification HCP</h3>
  <table class="tbl">
    <tbody>
      <tr><td>Inscription HCP</td><td>{{ hcp_registration }}</td></tr>
      <tr><td>Vérification RPPS</td><td>{{ rpps_verification }}</td></tr>
      <tr><td>Authentification</td><td>{{ hcp_authentication }}</td></tr>
      <tr><td>Idle timeout / lockout</td><td>{{ hcp_session_policy }}</td></tr>
    </tbody>
  </table>

  <h3>2.5 — Échanges et partages</h3>
  <table class="tbl">
    <tbody>
      <tr><td>Partage HCP→HCP</td><td>{{ hcp_sharing }}</td></tr>
      <tr><td>Alimentation DMP / MES</td><td>{{ dmp_feed }}</td></tr>
      <tr><td>Intégration Ségur</td><td>{{ segur_integration }}</td></tr>
      <tr><td>Déploiement intra-ES</td><td>{{ intra_es_deployment }}</td></tr>
    </tbody>
  </table>

  <h3>2.6 — Sécurité, RGPD, identitovigilance</h3>
  <table class="tbl">
    <tbody>
      <tr><td>DPIA / AIPD</td><td>{{ dpia_status }}</td></tr>
      <tr><td>Politique mot de passe</td><td>{{ password_policy }}</td></tr>
      <tr><td>2FA</td><td>{{ tfa_status }}</td></tr>
      <tr><td>Pentest / SBOM</td><td>{{ pentest_status }}</td></tr>
      <tr><td>RAQ identitovigilance désigné</td><td>{{ raq_iv_named }}</td></tr>
    </tbody>
  </table>
</section>

<section id="s3">
  <div class="sec-title">
    <span class="num">03</span>
    <h2>Profils DMN applicables</h2>
    <span class="meta">DP-CRITICAL</span>
  </div>

  <table class="tbl">
    <thead>
      <tr><th>Profil DMN</th><th>Applicable</th><th>Source</th></tr>
    </thead>
    <tbody>
      <tr><td>Général</td><td><span class="tag ok">Toujours</span></td><td>—</td></tr>
      <tr><td>Référentiel d'identités</td><td>{{ profil_referentiel_identites }}</td><td>Section 2.3</td></tr>
      <tr><td>Référentiel d'identités hors ES</td><td>{{ profil_hors_es }}</td><td>Section 2.5</td></tr>
      <tr><td>Référentiel d'identités en ES</td><td>{{ profil_en_es }}</td><td>Section 2.5</td></tr>
      <tr><td>Stockage de copies de titres d'identités</td><td>{{ profil_stockage_pieces }}</td><td>À demander</td></tr>
      <tr><td>Accès Professionnel</td><td>{{ profil_acces_pro }}</td><td>Section 2.4</td></tr>
      <tr><td>Accès Usager</td><td>{{ profil_acces_usager }}</td><td>Section 2.2</td></tr>
      <tr><td>Accès Usager - ApCV</td><td>{{ profil_apcv }}</td><td>Section 2.2</td></tr>
    </tbody>
  </table>

  <div class="callout">
    <strong>Décision DP — Profils retenus</strong> : {{ dp_decision_profils }}
  </div>
</section>

<section id="s4">
  <div class="sec-title">
    <span class="num">04</span>
    <h2>Décisions et signatures</h2>
  </div>

  <h3>Présents</h3>
  <ul>
    <li><strong>PM Theodo</strong> : {{ pm_name }}</li>
    <li><strong>DP Theodo</strong> : {{ dp_name }}</li>
    <li><strong>Client RAQ</strong> : {{ raq_name }}</li>
    <li><strong>Client DPO</strong> : {{ dpo_name }}</li>
    <li><strong>Autres</strong> : {{ other_attendees }}</li>
  </ul>

  <h3>Décisions DP signées en visio</h3>
  <table class="tbl">
    <thead>
      <tr><th>Décision</th><th>Verdict</th><th>Signé par</th><th>Date · Heure</th></tr>
    </thead>
    <tbody>
      <tr><td>Qualification produit</td><td>{{ dp_decision_qualification }}</td><td>{{ dp_name }}</td><td>{{ date_intake }}</td></tr>
      <tr><td>Voie INS</td><td>{{ dp_decision_voie_ins }}</td><td>{{ dp_name }}</td><td>{{ date_intake }}</td></tr>
      <tr><td>Pathway</td><td>{{ pathway }}</td><td>{{ dp_name }}</td><td>{{ date_intake }}</td></tr>
      <tr><td>Profils applicables</td><td>{{ dp_decision_profils }}</td><td>{{ dp_name }}</td><td>{{ date_intake }}</td></tr>
    </tbody>
  </table>

  <h3>Actions immédiates (≤ 24h)</h3>
  <ol>
    <li>PM envoie au RAQ client la lettre de demande de docs <span class="mono">document-request-letter</span></li>
    <li>PM invite RAQ comme reader sur folder Drive Theodo</li>
    <li>DP crée le vault 1Password partagé <span class="mono">Theodo-ANS/{{ client_slug }}-testing</span></li>
    <li>PM envoie au client le calendrier des 2 jalons restants (jalon 2 fin sem 2, jalon 3 mi-sem 3)</li>
  </ol>
</section>

<section id="s5">
  <div class="sec-title">
    <span class="num">05</span>
    <h2>Notes libres</h2>
  </div>

  <p>{{ notes }}</p>
</section>

</main>

<footer>
  <span>Fiche intake · {{ client_name }} · visio {{ date_intake }}</span>
  <span><span class="y">theodo. HealthTech</span> · usage interne</span>
</footer>

</body>
</html>
