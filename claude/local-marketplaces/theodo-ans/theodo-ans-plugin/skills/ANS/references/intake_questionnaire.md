# Questionnaire d'intake — visio unique 1h (PM + DP + RAQ + DPO client)

À utiliser pour la **réunion d'intake** de toute nouvelle mission ANS Theodo. Cette réunion fait office de **jalon 1 (Q4)** : le DP valide la qualification du produit + le pathway visé + les profils applicables, en direct.

**Output attendu** : `intake/fiche-projet.md` rempli pendant la visio (PM prend les notes), validation DP en fin de visio, signature dans `intake/decisions.md`.

**Durée** : 1h. Déroulé recommandé : 5 min cadrage + 10 min qualification produit + 30 min recensement + 10 min profils applicables + 5 min décisions.

---

## Section 0 — Cadrage de la mission (5 min)

| Question | Pourquoi | Réponse |
|---|---|---|
| Quel est le calendrier visé pour la submission Convergence ? | Calibre la cadence | |
| Quel est le pathway commercial visé : LATM / LPP / PECAN / PECT / MES / Ségur ? | Détermine le périmètre des exigences | |
| Y a-t-il un dossier ANS antérieur (CE, audit ISO 13485, AIPD) que vous pouvez fournir ? | Réutilise l'existant | |
| Qui sera l'interlocuteur Theodo côté client (RAQ, DPO, CTO, autres) ? | Adresse les bonnes personnes | |

---

## Section 1 — Qualification produit (10 min) — DP-CRITICAL

**Décision DP en fin de section** : Theodo accepte-t-il la mission dans ce périmètre ?

| Question | Réponse acceptable | Réponse hors-périmètre Theodo |
|---|---|---|
| 1.1 Le produit est-il **CE-marqué** sous MDR (2017/745) ou IVDR (2017/746) ? | Oui — fournir le certificat CE | Non → **bloquant** : pas de DMN possible avant CE |
| 1.2 Quelle est la **classe** ? (I, IIa, IIb, III) | I à IIb : OK pour Theodo | III : escalade — généralement hors périmètre Theodo SaMD |
| 1.3 La classification a-t-elle suivi la règle 11 MDR ? | Oui, règle 11 confirmée | Si autre règle, vérifier la cohérence |
| 1.4 Le produit est-il **SaMD** (logiciel seul) ou inclut-il un **dispositif physique** (capteur, montre, etc.) ? | SaMD ou hybride : OK | DM hardware sans logiciel : hors périmètre ANS DMN |
| 1.5 Quelle est la **finalité médicale** ? (diagnostic / thérapeutique / monitoring / aide à la décision) | Toutes acceptables | Aucune (= wellness) → Mon espace santé referencement uniquement, pas DMN cert |
| 1.6 Y a-t-il un **modèle ML / IA** dans le produit ? | Oui ou non, à clarifier | Si oui : MDCG 2025-6 + EU AI Act art. 9-10-13-14-17 (à mentionner explicitement dans la fiche projet) |
| 1.7 Le produit est-il déjà **vendu en France** ? Si oui, quelle modalité (autofinancement / mutuelle / prescription) ? | Toute réponse | Détermine si c'est un nouveau remboursement ou une migration |

### Décision DP — Qualification produit

```
[ ] Mission acceptée — pathway initial proposé : ___________________
[ ] Mission acceptée sous condition — condition : __________________
[ ] Mission refusée — raison : ____________________________________
```

---

## Section 2 — Recensement architecture et flux (30 min)

### 2.1 Topologie technique

| Question | Réponse |
|---|---|
| Quels composants applicatifs ? (App mobile patient, app HCP web, app HCP mobile, capteur, backend) | |
| Stack technique : Web (Angular/React/Vue) ? Mobile (iOS native, Android native, React Native, Flutter) ? Desktop ? | |
| Hébergement : cloud (GCP, AWS, Azure) avec quelle région ? On-prem ? | |
| Hébergeur de Données de Santé (HDS) : attestation en place ? Date ? Périmètre ? | |
| HCP a-t-il accès à un **portail web** ou uniquement une app mobile ? | |
| Patient : interagit via **app mobile** ou **portail web** ou les deux ? | |

### 2.2 Profils utilisateurs

| Profil | Existe ? | Cas d'usage |
|---|---|---|
| Patient (Usager) | | Auto-inscription ? Identification après prescription HCP ? |
| Médecin / professionnel de santé (HCP) | | Type d'exercice (libéral, salarié, mixte) ? Spécialité ? |
| Administrateur Theodo / éditeur | | Rôles distincts ? |
| Autres (paramédicaux, secrétariat médical, aidant familial) | | À expliciter |

### 2.3 Flux d'identification patient — DP-CRITICAL pour Voie A vs B

**Cf. `referentiel_identites_qualification.md` pour l'arbre de décision détaillé.**

| Question | Pourquoi |
|---|---|
| 2.3.1 L'usager **s'auto-inscrit** dans le produit (saisie de ses traits via l'IHM) ? | Si oui → Voie A par défaut (note d'extension Guide INS V3.0 §1.2) |
| 2.3.2 Un HCP / opérateur **crée** l'identité patient via l'IHM (saisie des traits) ? | Si oui → Voie A confirmée |
| 2.3.3 Le produit reçoit l'identité par **flux entrant** (IHE PAM, HL7 ADT, FHIR Patient pull) sans création locale ? | Si oui ET pas de saisie locale → Voie B possible |
| 2.3.4 Le produit appelle déjà le **téléservice INSi** ? | Si oui → décrire l'authentification (CPx ? IGC-Santé organisation ?) |
| 2.3.5 Le produit produit-il des **sorties papier ou PDF** avec identité patient (ordonnance, compte-rendu) ? | Si oui → INS 42-44 applicables |

### Décision DP — Voie INS

```
[ ] Référentiel d'identité (Référentiel d'identités) — applique ~30 exigences INS étendues
[ ] Esclave d'identité (logiciel non-référentiel) — réception flux uniquement
[ ] À approfondir avec le client (ambiguïté) → demande de doc complémentaire
```

### 2.4 Flux d'identification HCP

| Question | Réponse |
|---|---|
| Comment les HCP s'inscrivent ? Self-service ? Création par admin ? | |
| Y a-t-il vérification du RPPS / ADELI ? Comment ? (Annuaire Santé / déclaration / autre) | |
| Authentification : email/mdp ? PSC implémenté ? 2FA ? | |
| Idle timeout, lockout, session policy ? | |

### 2.5 Échanges et partages

| Question | Réponse |
|---|---|
| Les HCP partagent-ils des dossiers patient ? Avec qui ? Comment (email, MSSanté, autre) ? | |
| Le produit alimente-t-il le DMP / Mon espace santé ? | |
| Le produit est-il intégré à un éditeur Ségur (DSR / DUI / PFI / MED) ? | |
| Le produit est-il déployé en Établissement de Santé (CHU, clinique) ? | Si oui → INS 39.1 applicable |

### 2.6 Sécurité, RGPD, identitovigilance

| Question | Réponse |
|---|---|
| RGPD : DPIA / AIPD réalisée ? Date ? Sous-traitants identifiés (DPA art. 28) ? | |
| Politique de mot de passe (longueur, complexité, rotation) ? | |
| Authentification 2FA : optionnelle / obligatoire ? Mécanisme ? | |
| Cybersécurité : pentest réalisé ? SBOM maintenu ? Monitoring vulnérabilités ? | |
| Identitovigilance : RAQ identifié ? Procédure d'attribution INS ? Plan de gestion des identités ? | |

---

## Section 3 — Profils DMN applicables (10 min) — DP-CRITICAL

Cocher les profils applicables d'après les sections 2.x. Cette ligne **détermine le scope de la gap analysis**.

| Profil DMN | Applicable ? | Source dans l'intake | Verdict DP |
|---|---|---|---|
| Général | Toujours | — | ✓ par défaut |
| Référentiel d'identités | (depuis 2.3) | 2.3.1 ou 2.3.2 = Oui | |
| Référentiel d'identités hors Établissement de Santé | (depuis 2.5) | 2.5 ES = Non | |
| Référentiel d'identités en Établissement de Santé | (depuis 2.5) | 2.5 ES = Oui | |
| Stockage de copies de titres d'identités | (rare, à demander) | Upload pièce d'identité ? | |
| Accès Professionnel | (depuis 2.4) | HCP a un accès ? | |
| Accès Usager | (depuis 2.2) | Patient a un accès ? | |
| Accès Usager - ApCV | (depuis 2.2) | Lecture carte Vitale ? | |

### Décision DP — Profils applicables

```
Profils retenus pour la gap analysis :
[ ] Général
[ ] Référentiel d'identités (Voie A)
[ ] Référentiel d'identités hors ES
[ ] Référentiel d'identités en ES
[ ] Stockage copies titres
[ ] Accès Professionnel
[ ] Accès Usager
[ ] Accès Usager - ApCV
```

---

## Section 4 — Décisions et signatures (5 min)

### Décisions prises pendant la visio

À reporter dans `intake/decisions.md` à la fin de la séance :

```markdown
# Decisions intake — <client> — <date>

## Présents
- PM : <nom>
- DP : <nom>
- Client RAQ : <nom>
- Client DPO : <nom>
- Autres : <noms>

## Qualification produit (Section 1)
- Pathway visé : <LATM / LPP / PECAN / PECT / MES / Ségur>
- Mission acceptée : Oui / Non / Sous condition
- Conditions : <texte>
- Décision DP : <signature DP, date, heure>

## Voie INS (Section 2.3)
- Décision : Voie A / Voie B / À approfondir
- Justification : <référence Guide INS V3.0 §1.2 + faits du client>
- Décision DP : <signature DP, date, heure>

## Profils applicables (Section 3)
- Profils retenus : <liste>
- Décision DP : <signature DP, date, heure>

## Actions immédiates
- [ ] PM : envoie au client la lettre de demande de docs (cf. document_request_catalog.md)
- [ ] PM : crée le folder Drive standard via /ans-init
- [ ] DP : valide la fiche projet sous 48h
- [ ] Client : transmet les docs P0 sous 1 sem
```

---

## Section 5 — Documents demandés au client à l'issue (à transmettre dans la foulée)

Le PM enverra dans la journée suivant la visio :

1. La lettre de demande de docs (cf. `document_request_catalog.md`) personnalisée selon les profils applicables
2. L'invitation au folder Drive Theodo (en lecture)
3. La demande d'invitation au vault 1Password partagé pour les creds testing (cf. Q7-B2)
4. Le calendrier des 3 jalons DP (cf. `mission_workflow.md`)

---

*Dernière mise à jour : 2026-05-06.*
