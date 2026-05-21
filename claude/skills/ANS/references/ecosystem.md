# ANS / French digital health ecosystem — quick map

## Institutions

| Sigle | Nom complet | Rôle |
|---|---|---|
| ANS | Agence du Numérique en Santé | Opérateur national; publie référentiels CI-SIS, PGSSI-S, INS, PSC, DMN; certifie DMN; gère Convergence, MSSanté, INSi, RPPS/Annuaire Santé |
| DNS | Délégation ministérielle au Numérique en Santé | Cabinet ministériel; publie la Doctrine du Numérique en Santé, pilote Ségur |
| HAS | Haute Autorité de Santé | Évalue le bénéfice clinique/organisationnel; CNEDiMTS pour DM/DMN; publie référentiels par pathologie |
| CNEDiMTS | Commission Nationale d'Évaluation des Dispositifs Médicaux et Technologies de Santé | Sous-commission HAS; donne ASA/SA et avis PECAN |
| Assurance Maladie / CNAM | Caisse Nationale d'Assurance Maladie | Décide de l'inscription LPPR/LATM, fixe forfaits |
| ANSM | Agence Nationale Sécurité du Médicament | Autorité compétente MDR/IVDR en France (vigilance, déclarations) |
| GIE Sesam-Vitale | Groupement d'intérêt économique | Opère INSi, ApCV, cartes Vitale et CPx |
| CNIL | Commission Nationale Informatique et Libertés | Autorité de contrôle RGPD |
| LNE / G-MED | Notified bodies | Évaluation conformité MDR pour CE marking |
| Cyberveille / CERT Santé | ANS | Surveille incidents cyber santé |

## Programmes nationaux

- **Ma Santé 2022 / Ségur de la Santé** — plan d'accélération numérique 2019+
- **Ségur du Numérique en Santé**
  - Vague 1 (2021–2023): financement éditeurs pour rendre logiciels compatibles services socles (DMP, MSSanté, INS, e-CPS), couloirs Ville/Hôpital/MS/Officine/Bio/Radio
  - Vague 2 (2023+): élargissement (sage-femme, dentiste, paramédicaux), DUI médico-social, MEDecin v2, hôpital v2, focus alimentation DMP + INS qualifiée
- **Mon espace santé (MES)** — espace numérique de santé citoyen (DMP intégré + messagerie + agenda + catalogue d'apps référencées)
- **Doctrine du Numérique en Santé** — document cadre publié par la DNS (services socles, référentiels)

## Services socles et référentiels

| Acronyme | Description | Quand pertinent |
|---|---|---|
| INS | Identifiant National de Santé (matricule INS = NIR + OID) | Toute identification patient |
| RNIV | Référentiel National d'Identitovigilance | Règles 1–37 du Guide d'implémentation INS |
| INSi | Téléservice de récupération de l'INS via Sesam-Vitale | Tout DMN qui veut récupérer/qualifier l'INS d'un patient |
| ApCV | Application carte Vitale | Authentification patient sans carte physique |
| PSC | Pro Santé Connect (federated SSO OIDC pour PS, basé sur e-CPS / CPx) | Tout DMN avec accès professionnel |
| e-CPS | Application mobile carte CPS | MIE PS niveau eIDAS substantiel |
| CPx | Carte de Professionnel de santé / structure (CPS, CPF, CPE, CPA) | Authentification forte PS, signature INSi |
| Annuaire Santé | Répertoire RPPS+ADELI consolidé | Toute identification PS |
| MSSanté | Messagerie Sécurisée de Santé (protocole + opérateurs DNS) | Échanges PS↔PS, PS↔patient via MES |
| DMP | Dossier Médical Partagé (intégré dans MES depuis 2022) | Alimentation/consultation documents santé patient |
| CI-SIS | Cadre d'Interopérabilité des Systèmes d'Information de Santé | Volets techniques (échange documents, traçabilité, identifiants) |
| PGSSI-S | Politique Générale de Sécurité des SI de Santé | Référentiels sécurité (IE PS, IE Usager, hébergement, traçabilité) |
| HDS | Hébergeur de Données de Santé | Certification ASIP/HDS, prérequis dur |
| FHIR | Standard HL7 pour API santé | Format APIs CI-SIS modernes |
| IHE PAM | Patient Administration Management profile | Flux d'identités hospitaliers |
| HL7 ADT | Admit/Discharge/Transfer | Flux d'identités legacy |
| LPPR | Liste des Produits et Prestations Remboursables | Inscription DM/DMN remboursés |
| LATM | Liste des Activités de Télésurveillance Médicale | Inscription télésurveillance remboursée |

## Voies de prise en charge (reimbursement)

| Voie | Pour qui | Durée | Évaluateur clinique |
|---|---|---|---|
| **Droit commun nom de marque** (LPPR ou LATM) | DMN avec preuve clinique mature, positionnement spécifique | Inscription jusqu'à 5 ans, renouvelable | CNEDiMTS (SA / ASA) |
| **Droit commun ligne générique** | DMN télésurveillance dans 5 pathologies HAS publiées (diabète, IRC, IRespC, IC, prothèses cardiaques implantables) | Inscription via auto-déclaration de conformité aux specs génériques | Pas d'évaluation produit-par-produit (la ligne générique est évaluée) |
| **PECAN** (prise en charge anticipée numérique) | DMN présumé innovant en attente d'inscription LPPR/LATM | 1 an non renouvelable | CNEDiMTS (présomption innovation) |
| **PECT** (prise en charge transitoire) | DM présumé innovant dépassant uniquement les fonctions numériques | Transitoire | CNEDiMTS |
| **Référencement Mon espace santé** | App patient catalogue MES (gratuit ou non-remboursé) | Référencement (pas de remboursement) | ANS via REM/DSR dédié |

## Couloirs Ségur

- **Couloir Ville** — médecins, sage-femmes, dentistes, kinés, infirmiers libéraux, biologistes, radiologues, officines, auxiliaires médicaux
- **Couloir Hôpital** — DPI hospitaliers, PFI (plateformes), MEDecin (gestion lits), etc.
- **Couloir Médico-social** — DUI (dossier usager informatisé)

## Acronymes utiles

- **REM** — Référentiel d'Exigences Minimales (Mon espace santé / Ségur)
- **DSR** — Dossier Spécifique de Référencement
- **MIE** — Moyen d'Identification Électronique (mot de passe, e-CPS, certificat, etc.)
- **ASPP** — Acteurs des Secteurs sanitaires, médico-social et social Professionnels
- **CIBA** — Client-Initiated Backchannel Authentication (mode PSC pour mobile)
- **OID** — Object Identifier (caractérise l'autorité d'attribution de l'identité, ex. NIR=1.2.250.1.213.1.4.8)
- **IGC-Santé** — Infrastructure de Gestion de Clés santé (PKI)
- **RPPS** — Répertoire Partagé des Professionnels intervenant dans le système de Santé
- **ADELI** — Automatisation DEs LIstes (ancien répertoire, en migration vers RPPS)
- **DPI** — Dossier Patient Informatisé
- **DPO** — Délégué à la Protection des Données
- **DPIA / AIPD** — Data Protection Impact Assessment / Analyse d'Impact Protection des Données
- **CaRE** — Cybersurveillance et Réponse aux Évènements (programme cyber santé)
- **iSC** — Industriels Santé Connect (IdP industriels pour Convergence)
