# Qualifier un logiciel comme « référentiel d'identités » au sens de l'INS

Cette référence cadre la qualification du statut « référentiel d'identités » d'un DMN. Le statut est déterminant : il fait basculer **~30 exigences** du référentiel DMN V1.2.2 (INS 4, 6, 11–35, 37, 38, 40 + voies INSi) du périmètre `Tous logiciels` vers le périmètre `Référentiels d'identités uniquement`.

À charger en gap analysis, en revue de positionnement Convergence, ou dès qu'un client demande « est-ce que mon DMN est concerné par les exigences INS étendues ? ».

## 1. Source opposable

**Guide d'implémentation de l'INS dans les logiciels — version v3.0 — décembre 2024 — ANS / Délégation au numérique en santé.**

URL : https://esante.gouv.fr/sites/default/files/media/document/ANS_Guide-Implementation-INS_V3.0.pdf

Statut : **Validé**, classification publique. Annexé au Référentiel INS v2.1 (arrêté du 13 décembre 2024) → opposable aux éditeurs. Les anciennes « règles » du guide v2 sont devenues des `[EXI ID xx]` ou `[RECO xx xx]` ; les règles classées EXI doivent obligatoirement être implémentées.

Texte d'application transverse : RNIV (Référentiel National d'Identitovigilance, 3RIV / DGOS / DGS / HAS).

Code de la santé publique : art. **L.1111-8-1** + R. 1111-8-1 et suivants → obligation de référencement des données de santé avec l'INS pour tout acteur du cercle de confiance.

## 2. Définition stricte (Guide INS V3.0 §1.2 p.5 — citation)

> *« Le référentiel d'identités est un logiciel qui permet **la création / la modification / la fusion** des identités. Il s'agit souvent de la gestion administrative du patient/malade (GAP/GAM) dans les établissements de santé, du logiciel de gestion de cabinet (LGC) pour le professionnel libéral, du système de gestion de laboratoire d'analyse médicales (SGL) pour les laboratoires, du système d'information de radiologie (SIR) dans les cabinets d'imagerie, du dossier usager informatisé (DUI) dans les Établissements et Services Sociaux et Médico-sociaux (ESSMS), etc. »*

Liste **non exhaustive** (le « etc. » est explicite). Le test n'est pas la catégorie typique mais le verbe : créer / modifier / fusionner.

### Note d'extension (même paragraphe, p.5) — déterminante pour les SaaS BtoC

> *« Les solutions d'amont de prise de rendez-vous / préconsultation / préadmission, mettant **directement à contribution l'usager** pour la gestion de son identité numérique, **s'apparentent à un logiciel référentiel d'identités**. »*

Conséquence : tout DMN où l'usager s'auto-inscrit en saisissant ses traits d'identité (nom, prénom, date de naissance, etc.) tombe sous cette extension — y compris s'il n'est ni GAP/GAM ni LGC ni SGL ni SIR ni DUI.

### Précision §1.6 p.9

> *« La création d'une identité au sein du logiciel peut se faire **indépendamment de la récupération de l'INS**. Il est toutefois recommandé de procéder à la qualification de l'INS le plus tôt possible. »*

Conséquence : ne **pas** appeler le téléservice INSi ne fait **pas** sortir le logiciel du statut référentiel d'identités. C'est un manque de conformité, pas une qualification différente.

## 3. Catégorie alternative — « logiciel non référentiel d'identités »

Le Guide INS V3.0 §2.2.2 (p.29) reconnaît cette catégorie :

> *« Pour minimiser les impacts en matière d'interopérabilité, seuls les statuts techniques `Identité provisoire` ou `Identité validée` sont transmis dans les flux IHE PAM. Les statuts `Identité récupérée` et `Identité qualifiée` ne sont donc pas transmis. (…) Le statut `Identité qualifiée` est déduit, par les logiciels non référentiels d'identités, du remplissage du champ relatif au matricule INS et de son OID, associé à une identité au statut `Identité validée`. »*

Profil opérationnel d'un **logiciel non référentiel** :
- Reçoit l'identité par **flux entrant** (IHE PAM, HL7 ADT, FHIR Patient via API).
- Ne saisit pas les traits stricts.
- Ne qualifie pas — déduit le statut depuis le matricule INS + OID transmis.
- N'appelle **jamais** INSi de sa propre initiative.

## 4. Arbre de décision — qualifier un DMN

Appliquer dans cet ordre :

1. **Le DMN écrit-il dans son modèle de données un nom de naissance, prénom de naissance, date de naissance, sexe ou code INSEE de lieu de naissance saisi via son IHM ?**
   - Oui → candidat référentiel. Continuer.
   - Non → logiciel non référentiel. Stop ici.

2. **Le DMN permet-il à l'usager (patient ou parent) de saisir ces traits lui-même via son IHM ?**
   - Oui → **référentiel d'identités** (note d'extension §1.2). Stop.
   - Non → continuer.

3. **Le DMN permet-il à un utilisateur (PS, opérateur back-office) de créer, modifier ou fusionner une identité directement dans le logiciel ?**
   - Oui → **référentiel d'identités**. Stop.
   - Non → continuer.

4. **Le DMN consomme-t-il l'identité depuis un autre SI (SIH, LGC, RIS, etc.) via flux interopérables (IHE PAM, HL7 ADT, FHIR Patient pull) sans permettre la création/modification locale ?**
   - Oui → **logiciel non référentiel**. Le SI amont est référentiel.
   - Non → revoir l'architecture.

## 5. Trois voies de positionnement pour un client en SaaS BtoC

> **V0.4 — terminologie** : « Voie A / Voie B » ne porte aucune sémantique
> métier. La doctrine ANS distingue le **rôle** vis-à-vis de l'identité :
> *Référentiel d'identité* (le système est source de vérité) vs *Esclave
> d'identité* (le système consomme un flux d'identité produit ailleurs).
> Le code interne `voie_a` / `voie_b` reste utilisé en clé de stockage
> (project-brief.json, sub_decision_impact, etc.) pour ne pas casser les
> missions existantes ; mais tout texte généré (UI, livrables, prompts)
> doit utiliser les libellés Référentiel / Esclave d'identité.

Quand un DMN gère des comptes patient en self-service (cas typique des DTx, télésurveillance grand public, applications de santé connectée), trois positionnements sont possibles. Présenter au client le coût/bénéfice de chacun.

### Référentiel d'identité (`voie_a`) — le système EST la source de vérité

- **Périmètre** : ~30 exigences INS étendues s'appliquent.
- **À implémenter** :
  - Traits stricts : nom de naissance, liste prénoms de naissance, premier prénom de naissance, sexe au sens RNIV (M/F sans X), date de naissance + dates incomplètes, code INSEE lieu de naissance + référentiel INSEE COG (EXI ID 14, 15).
  - Statuts d'identité (provisoire / récupérée / validée / qualifiée) + machine à états (EXI ID 23, 26, 27, 28).
  - Attributs identité homonyme / douteuse / fictive (EXI ID 24).
  - Recherche d'antériorité multicritères avec champs distincts date+nom+prénom (pas de barre unique) (EXI ID 17).
  - Téléservice INSi (récupération + vérification) — contrat GIE Sesam-Vitale + auth par CPx ou IGC-Santé organisation.
  - Affichage matricule INS + OID + statut sur les écrans et exports PDF (EXI DIF 02, règle 32 du guide).
  - Procédures de qualification, propagation, rétrogradation, fusion.
- **Coût** : élevé (effort de R&D produit + raccordement INSi + procédure d'identitovigilance + SOP 3RIV).
- **Avantage** : conforme à la doctrine ANS sans manœuvre — défendable face à un assesseur.

### Esclave d'identité (`voie_b`) — le système consomme un flux d'identité externe

- **Périmètre** : retire les ~30 exigences INS étendues. Reste : INS 1, 2, 3, 5, 7, 8, 9, 10 (tous logiciels) + INS 41 (traçabilité partages) + INS 42-44 (sortie papier) + INS 45 (intégration flux) + IEU 7-8.
- **À implémenter** :
  - Refonte du parcours d'inscription : le patient ne s'auto-déclare plus. Le patient est créé dans le SI du PS prescripteur (LGC / SIH) qui qualifie l'INS et la pousse vers le DMN par flux IHE PAM ou équivalent.
  - Le DMN ne propose plus de saisie patient des traits stricts. Il reçoit, affiche, et range.
  - Le DMN doit prouver la traçabilité du flux entrant (INS 45.2 et 45.3).
- **Coût** : refonte UX + intégrations B2B avec les SI prescripteurs. Casse souvent le modèle BtoC self-service.
- **Avantage** : scope INS divisé par 2 et architecture plus alignée avec la doctrine ANS « une identité, plusieurs usages ».

### Hors cercle de confiance (`voie_c`) — argumenter qu'on n'est pas dans le scope INS ❌ À éviter

- Position : « Mon DMN est un service technique avec comptes utilisateurs, pas une identité sanitaire ; donc l'INS ne s'applique pas. »
- **Pourquoi c'est rejetable** :
  - Le DMN édite un rapport ou des données de santé partageables avec un PS → tombe sous l'art. L.1111-8-1 CSP (référencement INS obligatoire dès qu'un référencement de données de santé a lieu).
  - Le Guide INS §1.1 p.4 vise l'« utilisation par l'ensemble des acteurs d'une même identité ». Un DMN qui héberge des données de santé n'échappe pas.
- **Recommandation** : ne pas proposer cette voie au client, sauf cas étroit (logiciel de pure mesure non médicale, sans aucun partage de donnée de santé identifiée — auquel cas le qualifier comme DM est lui-même discutable).

## 6. Exemples concrets

| DMN type | Auto-inscription patient ? | Saisie traits stricts dans IHM ? | Verdict |
|---|---|---|---|
| App de télésurveillance avec onboarding patient self-service | Oui | Oui (nom/prénom/date naissance) | Référentiel d'identités (Voie A ou B selon stratégie) |
| Plateforme web HCP de consultation de rapports, patient créé par PS uniquement | Non | Oui (PS saisit) | Référentiel d'identités (saisie utilisateur ≠ usager mais reste création) |
| App patient connectée à une appli LGC du médecin (push d'identité INSi qualifiée) | Non | Non (lecture seule) | Logiciel non référentiel d'identités |
| Module radiologie consommant l'identité du SIH par flux ADT | Non | Non | Logiciel non référentiel d'identités |
| Compagnon d'observance pure (rappel pilules, sans données de santé partagées) | Self-service | Pas de traits sanitaires | Hors INS (mais probablement hors champ DMN aussi — à requalifier) |

## 7. Mode d'emploi : quoi faire en gap analysis

1. **Étape qualification** : remplir l'arbre de décision §4. Documenter le verdict + le passage du Guide qui le justifie.
2. **Étape positionnement** : si Voie A possible mais coûteuse → présenter Voie B comme alternative produit. Le choix relève du client (impact business sur le parcours d'inscription).
3. **Étape périmétrage du gap** : marquer les ~30 exigences INS étendues comme **applicables (Voie A)** ou **non applicables — déclaration de profil non-référentiel (Voie B)**. Le tableur de sortie doit avoir une colonne « périmètre conditionnel » pour ce filtre.
4. **Étape déclaration Convergence** : la déclaration de profil dans Convergence doit être cohérente avec la qualification. Joindre une **note de positionnement** signée par le RAQ ou DPO du client expliquant le verdict + les références au Guide INS.
5. **Étape NB / assesseur ANS** : anticiper que l'assesseur peut contester Voie B si l'IHM patient permet en réalité de créer/modifier des traits stricts. Avoir des captures d'écran montrant l'absence de ces fonctions sous Voie B.

## 8. Pièges fréquents

- **Croire que ne pas appeler INSi suffit pour ne pas être référentiel.** Faux. Cf. §1.6 p.9. C'est un manquement INS 37/38/40, pas une qualification différente.
- **Croire que les comptes utilisateurs « techniques » échappent à l'INS.** Faux. Dès qu'un PDF / rapport / export est partagé avec un PS, l'art. L.1111-8-1 CSP s'active.
- **Confondre la liste indicative (GAP/GAM, LGC, SGL, SIR, DUI) avec une liste exhaustive.** Faux. Le « etc. » est opposable.
- **Compter sur une exception « DMN diagnostique » ou « SaMD ».** Aucune exception de cet ordre n'est prévue par le Guide INS V3.0 ni le Référentiel INS v2.1.
- **Oublier que l'INS s'applique aux dates de naissance incomplètes.** Pour les usagers nés à l'étranger, le champ date peut être partiellement renseigné — le logiciel doit l'accepter selon §2.1 (à condition d'être en référentiel ou de recevoir le flux). Le code INSEE n'est pas obligatoire pour l'appel INSi mais l'est pour la création.

## 9. Référence rapide — exigences qui basculent selon le verdict

| ID DMN V1.2.2 | Périmètre |
|---|---|
| INS 1, 2, 3, 5, 7, 8, 9, 10 | Tous logiciels |
| INS 4, 6, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35 | **Référentiel d'identités uniquement** (Voie A) |
| INS 37, 38, 40 | **Référentiel d'identités uniquement** (Voie A) |
| INS 39 | Référentiel d'identités **en Établissement de Santé** |
| INS 41 | Tous logiciels (traçabilité partages) |
| INS 42, 43, 44 | Tous logiciels qui éditent du papier / PDF avec traits patient |
| INS 45 | Tous logiciels intégrant un flux entrant d'identité |
| INS 46 | Tous logiciels stockant copie de pièce d'identité |
