# Catalogue des documents et accès à demander au client

Liste exhaustive des artefacts à demander au client pour mener une gap analysis ANS sereinement. Découpée en **3 vagues** par criticité. La lettre de demande envoyée au client (post-intake, sem 1) est dérivée de cette liste, **filtrée par les profils applicables** déterminés en visio intake.

---

## Vague 1 — P0 bloquants (à demander dans la journée de l'intake, deadline J+5)

Sans ces éléments, la mission ne peut pas avancer correctement. Si manquants > J+5 (= fin de sem 1) → escalade DP pour décider entre prolongation, mode dégradé ou suspension.

### Hébergement HDS (toujours applicable si données de santé en cloud)

1. **Attestation HDS** de l'hébergeur (Google Cloud France SAS / OVHcloud / Outscale / Scaleway / AWS / Azure) — version 2018 ou nouvelle, indiquer le périmètre attesté
2. **Contrat HDS signé** avec l'hébergeur (addendum santé / DPA spécifique HDS)
3. **Liste exhaustive des services hébergeurs utilisés** dans le périmètre (App Engine, Cloud Run, Cloud SQL, Cloud Storage, BigQuery, Pub/Sub, Cloud Functions, Cloud Build, Secret Manager, KMS…). Chaque service doit être dans le scope HDS.
4. **Région d'hébergement exacte** : europe-west9 (Paris) ? europe-west1 (Belgique) ? autre ?
5. **Chaîne de sous-traitance complète** (hébergeur principal → sous-hébergeurs éventuels)

### Note de positionnement INS

6. **Note signée** RAQ + DPO justifiant le statut « référentiel d'identités » (Voie A / Voie B / Voie C) avec citation explicite du Guide INS V3.0 §1.2 et §2.2.2
7. **Décision Voie A vs Voie B** documentée : le client a-t-il évalué la refonte du parcours d'inscription patient (Voie B = patient créé en amont par SI prescripteur, push IHE PAM) ?

### Démarches ANS en cours

8. **Récépissé iSC** (Industriels Santé Connect) sur Convergence
9. **Statut demande de raccordement Pro Santé Connect** (date, environnement sandbox/prod, certificat fourni)
10. **Statut contrat GIE Sesam-Vitale** pour téléservice INSi + choix d'authentification (CPx ou IGC-Santé organisation)

### RGPD / DPIA

11. **AIPD / DPIA** (modèle CNIL) sur le traitement de données de santé du produit
12. **Registre des traitements** (art. 30 RGPD)
13. **Identité du DPO** + contact CNIL si désigné
14. **DPA hébergeur** signé avec clauses art. 28 spécifiques santé

---

## Vague 2 — P1 documentation produit (deadline début sem 2, J+8)

### SRS et REP

15. **REP-271** ou équivalent (template du PDF / rapport produit par le système avec données patient)
16. **REP-588** (référencé pour la mise à jour du template)
17. **SOP-148 V05** ou équivalent (Personal Data Protection Policy)
18. **PRO-833** ou équivalent (Cybersecurity Management Plan)
19. **SOP-054** ou équivalent (procédure de déploiement)
20. **Annexes du REP cybersécurité** : pentest report complet + SBOMs détaillés

### Procédures opérationnelles

21. **Procédure d'attribution d'identité patient** (post-INS, ou squelette si pas encore en place)
22. **Plan de gestion des identités (PGI)** alignement RNIV / 3RIV
23. **Procédure d'identitovigilance** (gestion doublons, fusions, identités douteuses, fictives)
24. **Procédure de réaction aux incidents cyber** (signalement CERT Santé / ANSSI)
25. **Plan de gestion des accès** + matrice rôles × droits × actions

### Architecture

26. **Diagramme d'architecture détaillé** avec toutes les régions cloud + flux entre composants
27. **Liste des sous-traitants** (art. 28 RGPD) avec finalités et localisations

---

## Vague 3 — P2 clarifications et stratégie (deadline mi-sem 2, J+10)

### Clarifications sur la cohérence interne

28. **Politique mot de passe** : SRS référençant la politique vs UI réelle vs design doc (rapport cybersécurité). Quelle version est opposable ?
29. **Création de patient par HCP** : à quel endroit dans l'UI ? Quels rôles ont accès ? (mode admin, account handler, etc.)
30. **Roles** : qui a quel rôle ? Comment sont-ils assignés ? Process de désignation
31. **Idle timeout** : existe-t-il quelque part un timer d'inactivité qui ne serait pas dans la doc lue ?

### Stratégie business et roadmap

32. **Pathway DMN visé** : nom de marque (LATM/LPP) / PECAN / Mon espace santé / Ségur / autre ?
33. **Roadmap intra-Établissement de Santé** : déploiements en clinique / hôpital ? (impact INS 39.1 + profil « en ES »)
34. **Roadmap Mon espace santé** : référencement prévu ? Calendrier ?
35. **Roadmap MSSanté / messagerie HCP→HCP** : cas d'usage prévu ? Sinon justification N/A pour ANN 5.1
36. **Stratégie 2FA Usager** : option A (2FA mandatory propriétaire) ou option B (FranceConnect+) ?
37. **Roadmap Annuaire Santé** : intégration prévue ? Calendrier ?

### Format d'export interopérable (PORT 1)

38. **Format exact** de l'export interopérable (FHIR R4 ? Quels profils — Mio.org DiGA, FR Core CI-SIS, autres ?)
39. **SOP de génération** de l'export interopérable
40. **Mapping** données produit → FHIR R4 resources → CI-SIS profile (s'il existe)
41. **Exhaustivité** : raw sensor data inclus dans l'export ou justification de l'exclusion ?
42. **Documentation publique** du format export à destination des récepteurs

### EU AI Act / MDCG 2025-6 (si modèle ML dans le produit)

43. **Confirmation usage modèle ML** : l'algorithm utilise-t-il un modèle ML/IA ? Lequel ?
44. **Conformité Art. 9 (risk mgmt), Art. 10 (data governance), Arts. 13-14 (transparency/human oversight), Art. 17 (AI QMS)** de l'EU AI Act 2024/1689
45. **PCCP / Algorithm Change Protocol** ou équivalent EU pour les évolutions du modèle
46. **Données d'entraînement** : provenance, anonymisation, biais évalués

### Captures UI authentifiées (à produire par le client)

47. **Capture du flux logout** complet (HCP + patient)
48. **Capture du flux reset password** complet (HCP + patient)
49. **Capture du flux création compte avec email doublon refusé**
50. **Capture du flux lockout** après 5 tentatives échouées
51. **Captures du mode admin** / Account Handler (création de comptes pré-remplis si applicable)
52. **Captures de l'UI de gestion des rôles** si elle existe
53. **Capture du mode patient app** (signup + email verification + login + 2FA optionnelle)

---

## Filtrage par profil applicable

Liste personnalisée selon les profils cochés en intake (cf. `intake_questionnaire.md` Section 3) :

### Si profil « Référentiel d'identités » coché → ajouter :
- Procédure de qualification d'identité (règle 19 RNIV)
- Spécification de la machine à états d'identité (provisoire / récupérée / validée / qualifiée)
- Plan de gestion des homonymes et des fusions

### Si profil « En Établissement de Santé » coché → ajouter :
- Convention CNDA / GIE Sesam-Vitale pour appel INSi avec CPx
- Pourcentage de PS authentifiés par CPx vs autre

### Si profil « Stockage copies titres d'identités » coché → ajouter :
- Procédure de chiffrement des fichiers stockés
- Procédure de suppression auto à 5 ans
- Audit log des accès aux pièces

### Si profil « Accès Usager - ApCV » coché → ajouter :
- Agrément CNDA addendum 8 (ou Dispositif Intégré v4.00 / addendum 7)

---

## Format de la lettre de demande

Le slash command `/ans-init <client>` génère un fichier `intake/document-request-letter.md` à partir de cette liste, filtrée par profils applicables. Le PM la personnalise (ajout du nom du client, dates) puis l'envoie au client RAQ par email.

Format type de la lettre (extrait) :

```markdown
Bonjour <RAQ client>,

À l'issue de notre visio d'intake du <date>, voici la liste des documents et accès dont nous avons besoin pour mener votre gap analysis ANS sereinement, organisée en 3 vagues par criticité.

## Vague 1 (P0 — sous 1 sem)
[liste filtrée]

## Vague 2 (P1 — sous 2 sem)
[liste filtrée]

## Vague 3 (P2 — sous 3 sem)
[liste filtrée]

Vous pouvez transmettre les documents par email à <PM email>. Je m'occuperai de les uploader sur notre folder Drive Theodo dédié à votre mission.

Pour les creds testing, merci de partager via le vault 1Password "Theodo-ANS/<client>-testing" — instructions ci-dessous.

[...]
```

---

*Dernière mise à jour : 2026-05-06.*
