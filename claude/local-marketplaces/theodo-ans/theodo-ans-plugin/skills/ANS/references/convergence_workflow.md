# Convergence platform — operational submission guide

URL: https://convergence.esante.gouv.fr

Convergence is the ANS portal where digital health companies submit certification dossiers (DMN, future Mon espace santé, Ségur, etc.). Authentication is via **Industriels Santé Connect (iSC)**.

## Phase 0 — Compte et organisation (≈1–2 semaines)

1. Le représentant légal crée un compte iSC (https://industriels.esante.gouv.fr → "Espace pro"). Pièces : extrait Kbis, pièce d'identité, mandat si délégué.
2. Une fois iSC validé, se connecter à Convergence et créer **l'Organisation** (SIREN, raison sociale, contacts DPO, RSSI, référent technique).
3. Inviter les utilisateurs internes (chef de projet, dev tech, QARA, juridique). Modop droits dans le Notion interne : "Plateforme Convergence : Modop pour donner les droits/permissions sur un produit".
4. Créer le **Produit** : nom commercial, version, description, classe DM, certificat CE (numéro NB, date), UDI/IFA si disponible, hébergement HDS.

## Phase 1 — Choix du parcours

Convergence propose les parcours suivants pour les DMN :

| Parcours | Cible | Évaluation HAS | Délai cible |
|---|---|---|---|
| Ligne générique | Télésurveillance dans 5 pathologies | Référentiel pathologie HAS (pas d'éval produit) | 2–4 mois |
| Nom de marque | Télésurveillance hors générique ou DTx | CNEDiMTS (SA/ASA) | 6–12 mois |
| PECAN | Présumé innovant, DMN/télésurveillance | CNEDiMTS (présomption d'innovation) | 60+30 jours |
| PECT | DM présumé innovant (fonctions au-delà du numérique) | CNEDiMTS | Variable |

## Phase 2 — Préparation des preuves (parallèle des raccordements)

Pour chaque exigence applicable du **Référentiel d'Interopérabilité et de Sécurité DMN v1.2.2**, fournir :

- **Énoncé de l'exigence** (auto-rempli depuis Convergence)
- **Scénario de conformité** sélectionné (la plupart des exigences en ont 1–4)
- **Preuves** (1 à 3) : selon les colonnes "N° preuve 1/2/3" du référentiel. Types courants :
  - Capture d'écran annotée
  - Vidéo screencast (≤3 min) montrant le scénario joué
  - Extrait code source / config
  - Extrait journaux applicatifs (logs) avec horodatage
  - Capture trafic réseau (Wireshark) sur appel INSi/PSC
  - Convention contractuelle (avec opérateur PSC, GIE Sesam-Vitale)
  - Document : politique d'identitovigilance, plan de gestion des identités, CGU

**Format recommandé** : 1 PDF par exigence regroupant titre, énoncé, scénario, captures annotées, signature responsable. Nommage : `{ID_EXIG}_{NomProduit}_{Version}.pdf`.

## Phase 3 — Raccordements (à kicker en T0)

| Service socle | Action | Délai | Pré-requis |
|---|---|---|---|
| **Pro Santé Connect (PSC)** | Demande raccordement bac à sable, puis prod | 1 semaine sandbox; prod après recettage | CGU, modèle d'authentification choisi (web / native+browser / CIBA), volumétrie, RSSI/DPO contact |
| **Téléservice INSi** | Contractualisation GIE Sesam-Vitale (SEL-MP-043) | 2–6 semaines | CPx organisation OU certificat IGC-Santé organisation; cas d'usage; pas de login/password |
| **MSSanté** | Adhésion opérateur DNS ou demande adresse domaine MSSanté | 2–8 semaines | Conformité protocole MSSanté |
| **Annuaire Santé** | API consommation référentiel RPPS | Self-service | Compte API ANS |
| **DMP / MES** | Conventionnement alimentation/consultation, conformité CI-SIS volet documents médicaux | Variable | FHIR R4, OAuth2, patientes APIs |
| **HDS** | Hébergement chez prestataire HDS-certifié OU certification propre | Long si certification propre (6–12 mois) | Certificat HDS valide |
| **e-CPS** (test) | Cartes CPx de test (F414) | 2–4 semaines | Demande à l'ANS, justification |

## Phase 4 — Soumission et instruction

1. Marquer le dossier "complet" dans Convergence → bascule en **instruction**.
2. ANS répond avec demandes de complétude (clarification, preuves additionnelles). Délais réponse : 30 jours typiques.
3. Pour PECAN : ANS et HAS ont **60 jours** depuis réception du dossier complet ; ministres santé+sécu ont **30 jours** après les 2 avis pour décider par arrêté.
4. Décision : certificat délivré (avec scope, version logicielle, date validité), ou refus motivé (possibilité de re-soumission après corrections).
5. Le certificat est **versionné** : toute évolution majeure du produit (version, périmètre, architecture sécurité) déclenche une re-certification.

## Causes fréquentes de rejet (à anticiper)

| # | Motif | Fix |
|---|---|---|
| 1 | INS 39 : authentification INSi par login/password | Migrer vers CPx ou IGC-Santé organisation; envisager Tiers de Confiance |
| 2 | PSC 6 : `acr_values≠eidas1` | Reconfigurer le client OIDC |
| 3 | PSC 5 : pas de processus documenté de mise à jour CGU | Rédiger procédure CGU + évidence d'application |
| 4 | INS 1.2 : interface accepte minuscules/accents/diacritiques en saisie nom de naissance | Bloquer côté UI, normaliser en BDD majuscules |
| 5 | IEU 9 : 2FA non implémenté pour usagers | Ajouter TOTP, OTP SMS, ou redirection MES |
| 6 | INS 11–35 : produit se déclare "non référentiel d'identités" pour éviter le bloc, mais en pratique en crée | Re-qualifier le scope ; assumer le profil |
| 7 | PORT 1 : portabilité non documentée ou format non lisible | Spécifier format export (FHIR Bundle JSON ou CSV documenté) |
| 8 | RGPD 1 : DPIA absente ou incomplète | Produire AIPD CNIL, conventions sous-traitance Art. 28 |
| 9 | ADM 1 : gestion fines des habilitations absente | RBAC / ABAC, écran d'admin, traçabilité |
| 10 | INS 41 : aucune trace des partenaires destinataires de données identifiantes | Journal des échanges (qui, quand, quel partenaire, quel patient) |

## Bonnes pratiques

- **Démarrer Convergence en parallèle du dev**, pas après. Les raccordements (PSC, INSi) sont sur le chemin critique.
- **Filmer les scénarios** plutôt que captures statiques : preuves plus robustes.
- **Versionner les preuves** avec hash SHA-256 dans un index, pour cohérence avec la version logicielle certifiée.
- **Désigner un Responsable Conformité ANS** côté client (souvent le QARA / RSSI).
- **Prévoir un canal direct** avec le chargé d'instruction ANS via la messagerie Convergence — répondre en <72h aux demandes.

## Liens utiles

- Connexion Convergence : https://convergence.esante.gouv.fr
- Espace industriels (docs, FAQ) : https://industriels.esante.gouv.fr
- Guichet d'aide gnius : https://gnius.esante.gouv.fr
- Référentiel DMN PDF v1.2.2 : https://industriels.esante.gouv.fr/sites/default/files/media/document/REF_IS_DMN_FR_V1.2.2_0.pdf
- Guide implémentation INS v2.0 : https://esante.gouv.fr/sites/default/files/media_entity/documents/INS_Guide%20implementation_V2_0.pdf
- Référentiel PSC : https://esante.gouv.fr/sites/default/files/media_entity/documents/Re%CC%81fe%CC%81rentiel%20Pro%20Sante%CC%81%20Connect%20-%20v1.0.0.pdf
- PGSSI-S Référentiel d'identification électronique des acteurs : https://esante.gouv.fr/produits-services/pgssi-s
