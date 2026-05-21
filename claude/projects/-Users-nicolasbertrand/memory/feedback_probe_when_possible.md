---
name: Si une probe est techniquement faisable, l'exiger
description: Pour les missions ANS où le compte gws est disponible et où le portail / l'app est probable, la prose obs_fr ne doit PAS écrire "n'a pas pu être démontré" comme une fatalité. La reco_client et theodo_ops doivent spécifier la probe à lancer, pas se contenter de "capture vidéo à fournir".
type: feedback
originSessionId: 778e6c28-c0af-40ff-8349-6a7c9b76798b
---
# Règle — la probe est l'action, pas la fatalité

## Principe

Quand une mission ANS dispose :
- d'un compte de testing accessible (portail web médecin OU app patient avec credentials valides),
- d'une infrastructure Playwright opérationnelle dans `probes/`,

alors la prose `obs_fr` ne doit PAS dire « le parcours complet n'a pas pu être démontré » comme une excuse passive. Il faut :

1. Dans `obs_fr` : décrire l'état observé minimal aujourd'hui (le bouton existe, le filtre est présent, etc.) ET le complément factuel à mesurer (longueur max, comportement après N tentatives, etc.).
2. Dans `reco_client` : spécifier la capture vidéo bout-en-bout précise que le client doit produire (étapes 1, 2, 3 du parcours).
3. Dans `theodo_ops` : ajouter explicitement « Lancer une probe Playwright X sur l'URL Y » avec mention des prérequis (compte testing dédié, base peuplée, etc.) — ne pas se contenter de « demander la capture au client ».

## Pourquoi

Une obs_fr type « n'a pas pu être démontré » :
- présente Theodo comme attendant la livraison client alors que Theodo a les moyens de probe,
- laisse le verdict en ÀC alors qu'une probe pourrait trancher,
- transforme la mission gap analysis en chasse aux preuves côté client au lieu d'un audit actif.

Le bon ton est consultant proactif : « voilà ce qu'on observe aujourd'hui, voilà la probe Playwright qu'on lance pour mesurer / vérifier le complément ».

## Exemples (mission Sunrise 2026-05-12)

### Cas où la probe est faisable

- **INS 1.2** (longueur max nom de naissance) : `theodo_ops` doit dire « Lancer probe Playwright saisie 54 vs 200 caractères sur le formulaire médecin pour mesurer la limite ». PAS « capture à fournir par le client ».
- **IEPS 5.1** (parcours mot de passe oublié) : `theodo_ops` doit dire « Lancer probe Playwright du parcours bout-en-bout avec compte testing + e-mail jetable ».
- **IEPS 8.1** (alerte doublon médecin) : `theodo_ops` doit dire « Probe création d'un second compte médecin avec même e-mail, capturer le message d'erreur ».
- **IEPS 9.1** (verrouillage compte après N tentatives) : `theodo_ops` doit dire « Probe tentatives erronées répétées jusqu'au lockout, compte testing dédié à brûler ».

### Cas où la probe n'est PAS faisable (laisser ÀC légitimement)

- App mobile non capturée et capture protocol mobile non fourni (capture par le client uniquement).
- Console admin non accessible (compte testing manquant ce niveau de droit).
- Fonctionnalité hors-scope déclarée par le client (cf. `requirement_out_of_scope`).

## Origine

Mission Sunrise 2026-05-12 — Nicolas a relu 4 lignes (INS 1.2, IEPS 5.1, IEPS 8.1, IEPS 9.1) où la prose disait « n'a pas pu être démontré » et a corrigé : « tu as mon gws, une probe est possible ». La prose a été reformulée pour cibler explicitement les probes Playwright à lancer, l'URL `https://testing.portal.hellosunrise.com/` étant accessible.
