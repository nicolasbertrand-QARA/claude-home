---
name: Engagement DP ≠ conformité Convergence
description: Pour une gap analysis ANS Convergence, un override DP signé "Conforme avec engagement de livraison" n'est PAS une preuve de conformité. Si aucune capture ne démontre le comportement aujourd'hui, le verdict est NC (avec l'engagement en audit_note). L'évaluateur ANS lit l'état au jour de la soumission, pas les promesses de livraison.
type: feedback
originSessionId: 778e6c28-c0af-40ff-8349-6a7c9b76798b
---
# Engagement DP ≠ conformité

## Règle (non négociable pour les missions ANS)

Quand un DP signe en jalon 2 ou 3 un override de verdict en `Conforme` ou `Conforme à étayer` avec une justification de type « engagement contractuel et calendrier produit confirmés » — sans capture observable du comportement aujourd'hui — l'override ne doit PAS être appliqué en l'état.

Le bon verdict à ce moment est :
- **Non conforme** si la fonctionnalité n'existe pas dans le produit (code de sévérité 5).
- **À confirmer** uniquement si elle existe mais n'a pas pu être probée (compte testing manquant, app mobile non capturée, etc.) — avec `confirm_reason` codée.

L'engagement DP, lui, vit dans `audit_note` ou en remarque dans le brief revue jalon 2 — pas dans le verdict.

## Pourquoi

L'évaluateur ANS lit la gap analysis au jour de la soumission Convergence. Une ligne « Conforme avec engagement de livraison Q3 » n'a aucune valeur opposable : Convergence demande des preuves de conformité au moment du dépôt, pas des promesses. Présenter une fonctionnalité non livrée comme conforme expose le dossier au rejet et entache la crédibilité Theodo.

## Comment appliquer

1. **Au moment de l'override DP** (rédaction du jalon 2 ou 3) : si le DP veut signer Conforme, exiger systématiquement la mention de la preuve déjà disponible. Si la justification se résume à « engagement à livrer », c'est NC, pas Conforme.
2. **Au moment du build plugin (R8 application)** : si l'override DP est de type « Conforme avec engagement », l'agent doit interpeller le PM/DP avant application. À défaut, appliquer Non conforme avec l'engagement en `audit_note`, et lever un warning dans le brief revue.
3. **Au moment du rendu Phase B** : `obs_fr` doit décrire l'état observable au jour de la rédaction (« n'est pas observable à date »). Pas de tournure type « cette exigence est traitée comme conforme sous réserve de production de capture avant soumission ».

## Origine de la règle

Mission Sunrise 2026-05-12 — 5 lignes du brief jalon 2 (PSC 5.1, IEU 4.1, IEU 9.1, IEU 11.1, IEU 12.1) avaient été signées « override → Conforme » avec rationale « engagement contractuel et calendrier produit confirmés en réunion de cadrage jalon 2 ». L'audit verdict initial avait recommandé d'appliquer ces overrides ; le plugin R8 l'a fait. Le QARA Theodo a corrigé : « Les engagements en réunion ne valent rien. C'est conforme aujourd'hui ou pas ? » — les 5 lignes ont été reverties en Non conforme.

## Anti-pattern à reconnaître

Toute prose `obs_fr` ou `reco_client` contenant des tournures comme :
- « cette exigence est traitée comme conforme sous réserve de »
- « engagement contractuel et calendrier confirmés en réunion »
- « conforme contingent à la livraison »
- « capture de conformité à produire avant soumission »

→ verdict à challenger. Le bon verdict est NC (avec engagement en audit_note) ou ÀC.
