---
description: Lance les probes UI Playwright (Web auto) ou génère les capture protocols (mobile/native).
argument-hint: <client-slug>
applies_rules: []
requires_tier_at_least: T2
retry_policy: transient_with_3_login_retries
criticality: blocking
failure_blocks: [ans-build]
---

# /ans-probe {{ args }}

Tu lances les probes UI pour la mission **{{ args }}**. Stratégie hybride (Q11-E) : Playwright auto pour les apps Web, capture protocol manuel pour mobile/native.

## Charges immédiates

```
skills/ANS/references/playwright_probe_patterns.md  (V0.x : à enrichir)
skills/ANS/references/epistemic_discipline.md
skills/ANS/references/probe_catalog.yaml            (V0.4 Lot 5 / A2 — 25 scénarios standards)
intake/fiche-projet.md                              (stack technique du client)
intake/project-brief.json                           (intake.probe_scope[] — V0.4 Lot 5)
access/credentials.json                             (creds en clair, V0.4 / A11)
```

## V0.4 Lot 5 / A2 — Scope piloté par `intake.probe_scope[]`

Le PM/DP déclare en jalon-1 la liste des scénarios fonctionnels à tester
(au lieu de laisser /ans-probe deviner). Format dans le project-brief :

```json
{
  "intake": {
    "probe_scope": [
      {"catalog_id": "hcp-login", "enabled": true},
      {"catalog_id": "patient-search-ins", "enabled": true},
      {"catalog_id": "mobile-signup-patient", "enabled": true},
      {"custom": {
         "label": "Recherche par numéro de sécu",
         "page_url": "https://app.client.fr/search-securite-sociale",
         "expected_field": "input[name=secu]",
         "expected_behavior": "validation 15 chiffres + clé Luhn",
         "profiles": ["Référentiel_d_identités"]
      }}
    ]
  }
}
```

**Ordre de résolution** :
1. Charge `skills/ANS/references/probe_catalog.yaml` (25 scénarios standards, mappés à des exigences DMN).
2. Pour chaque entrée `catalog_id` : génère le spec Playwright correspondant.
3. Pour chaque entrée `custom` : LLM-mappe à la liste d'exigences DMN concernées (cf. dmn_exigences_full.md), génère le spec, et ÉCRIT le mapping dans `probes/strategy.md` pour validation DP en jalon-2.
4. Couverture orpheline : pour toute exigence `testable_via_ui:true` du référentiel non couverte par le scope déclaré, flag dans `probes/exigences-coverage.md` § « Exigences orphelines » → P1 PM action en jalon-2.

**Si `intake.probe_scope[]` est absent ou vide** : continue avec le scope par défaut (login + DOM dump) MAIS écrit en tête de `probes/strategy.md` un avertissement P0 « scope probe non déclaré — risque de couverture insuffisante, demander au PM ».

## Discipline langue — V0.5

**Le DMN ANS n'existe qu'en France.** Si le site client est multi-langue,
**TOUJOURS bascule en FR** avant tout probe. Les libellés ANS (« nom de
naissance », « matricule INS », « sexe », « code lieu de naissance INSEE »,
« RNIV », « PSC », « Pro Santé Connect », « 2FA imposée », « identité
patient ») doivent être détectés en FR — la détection texte sur la version
EN d'un site donnera des faux négatifs systématiques sur INS/DOC/PSC.

Le helper `_helpers.ts.tpl` exporte `ensureFrenchLocale(page)` qui tente :
1. Toggle FR via selectors communs (`a:has-text("FR")`, `[hreflang="fr"]`...)
2. URL rewriting (`?lang=fr`, `/fr/`)
3. Sinon flag warning dans `00-locale-state.json`

`loginAsHcp` l'appelle automatiquement avant chaque tentative login. Pour
les probes sans login (signup HCP public, /login DOM, PSC detection),
**appeler explicitement `ensureFrenchLocale(page)` après le `page.goto`**.

Si le site est mono-langue EN, **flagger** dans `coverage.md` :
> ⚠ Site testé en EN uniquement — détections texte FR-spécifiques ratées,
> compléter par audit doc (PRO/REP) pour libellés ANS-équivalents.

## Étapes

### 0. Priorités demandées par DP via /a-confirmer (V0.4)

**Lire `intake/project-brief.json`** → `dp_decisions.jalon_2.a_confirmer_actions[]`.
Filtrer les entrées avec `action == "lancer_probe"` — ce sont les exigences
que le DP a explicitement demandé de re-prober après une première gap analysis.

```bash
TARGETED=$(jq -r '.dp_decisions.jalon_2.a_confirmer_actions[]? | select(.action == "lancer_probe") | .exigence_id' \
  ~/missions/{{ args }}/intake/project-brief.json 2>/dev/null)
echo "Exigences ciblées par DP : $TARGETED"
```

**Si TARGETED non vide** :

1. Pour chaque exigence ciblée, sélectionne le template V0.4 le plus approprié
   en consultant `templates/playwright/README.md` mapping :

   | Exigence | Template recommandé |
   |---|---|
   | INS 1.x, 4.1, 6.1, 11.x | `probe-patient-create-rniv.spec.ts.tpl` |
   | INS 7.x, 8.1            | `probe-patient-search.spec.ts.tpl` |
   | INS 9.x, INS 10.x       | `probe-patient-search-diacritics.spec.ts.tpl` |
   | INS 42, 43, 44          | `probe-pdf-ins-label.spec.ts.tpl` |
   | IEPS 4.1, ANN 1-5       | `probe-rpps-lookup.spec.ts.tpl` |
   | IEPS 9, IEU 5/6/9       | `probe-mfa-and-recovery.spec.ts.tpl` |
   | PSC 1, 5, 6             | `probe-psc-detection.spec.ts.tpl` |
   | PORT 1.1                | `probe-data-export-rgpd.spec.ts.tpl` |
   | DOC 1, 2 (libellé général) | `probe-tou-privacy-ifu.spec.ts.tpl` |

2. Écris `probes/strategy.md` avec une **section dédiée « Probes ciblés DP »** en tête,
   listant pour chaque exigence : id, profil, template choisi, contexte fourni
   (cf. `tech.probe_context_notes` du brief si rempli).

3. **Priorise ces probes en premier** dans l'ordre d'exécution. Le reste du
   workflow auto (probe-discovery + login + autres patterns) suit ensuite.

**Si TARGETED vide** : workflow standard de l'étape 1 (cf. ci-dessous), pas de
priorisation spéciale.

### 1. Identifier les stacks UI

Lis `intake/fiche-projet.md` Section 2.1 (topologie technique). Pour chaque composant UI :
- **Web (Angular, React, Vue, Svelte)** → Playwright auto
- **iOS native** → capture protocol manuel iOS
- **Android native** → capture protocol manuel Android
- **React Native / Flutter mobile** → capture protocol manuel + tentative Playwright si Flutter Web
- **Desktop (Electron, native)** → capture protocol manuel desktop

Génère un fichier `probes/strategy.md` listant pour chaque composant : stack, mode (auto / manuel), creds requis, exigences DMN couvertes.

### 2. Récupération des creds testing — V0.3.2

Les creds sont stockés en clair dans `~/missions/{{ args }}/access/credentials.json` (chmod 600, gitignored, exclu du sync Drive par publish-target rule). Ce sont des creds de **testing** uniquement — jamais prod.

```bash
# 1. Lecture des creds locaux
CREDS_FILE=~/missions/{{ args }}/access/credentials.json
test -f "$CREDS_FILE" || { echo "ÉCHEC : pas de credentials testing — remplir Jalon 1 §1.5 d'abord"; exit 1; }

HCP_EMAIL=$(jq -r '.hcp_email // empty' "$CREDS_FILE")
HCP_PASSWORD=$(jq -r '.hcp_password // empty' "$CREDS_FILE")
PATIENT_EMAIL=$(jq -r '.patient_email // empty' "$CREDS_FILE")
PATIENT_PASSWORD=$(jq -r '.patient_password // empty' "$CREDS_FILE")

test -n "$HCP_EMAIL" -a -n "$HCP_PASSWORD" || { echo "ÉCHEC : hcp_email + hcp_password requis"; exit 1; }
```

**Sécurité** :
- `access/credentials.json` est chmod 600 + gitignoré + jamais syncé sur Drive (cf. `rules/publish-target.md`).
- Les creds passent au sous-process Playwright via env vars (`process.env.HCP_EMAIL`), jamais via argv.
- Le prompt qui contient les creds est transporté via stdin par le runner UI — `ps aux` ne révèle rien.

### 3. Génération des Playwright specs (Web auto)

Pour chaque composant Web identifié, copie les templates depuis `templates/playwright/` et adapte :
- URL de base (depuis fiche projet)
- Sélecteurs (à découvrir dynamiquement via probe-discovery initial — voir step 4)

Templates à instancier (ordre de priorité) :
1. `probe-login.spec.ts.tpl` → `probes/01-login.spec.ts`
2. `probe-signup.spec.ts.tpl` → `probes/02-signup.spec.ts`
3. `probe-patient-form.spec.ts.tpl` → `probes/03-patient-form.spec.ts`
4. `probe-pdf-export.spec.ts.tpl` → `probes/04-pdf-export.spec.ts`
5. `probe-password-policy.spec.ts.tpl` → `probes/05-password-policy.spec.ts`
6. `probe-lockout.spec.ts.tpl` → `probes/06-lockout.spec.ts`
7. `probe-logout.spec.ts.tpl` → `probes/07-logout.spec.ts`
8. `probe-idle-timeout.spec.ts.tpl` → `probes/08-idle-timeout.spec.ts`

Note : en V0.1, ces templates n'existent qu'en partie. Si un template n'existe pas, le marquer comme « probe à coder en V0.x+1 » dans `probes/strategy.md`.

### 4. Probe-discovery initial (subagent ans-probe-runner)

Avant les probes complets, lance un probe-discovery rapide pour découvrir les sélecteurs et la topologie de l'app.

Spawn le subagent `ans-probe-runner` avec ce prompt :

```
Tu es ans-probe-runner. Discovery initial pour {{ args }}.
- Login URL : <BASE_URL>/login
- Creds : depuis .env.local

Tâche : capture la page de login + signup + structure du DOM (inputs, labels, boutons).
Output dans probes/reports/artifacts/discovery-* :
- screenshots
- inputs.json (liste tag, type, name, id, placeholder, aria-label)
- labels.txt (texte des <label>)
- DOM tree resumé

Rapporte au main thread les sélecteurs identifiés pour les flux critiques (login button, password field, submit, etc.).
```

Avec les résultats de discovery, instancie les templates avec les bons sélecteurs.

### 5. Lancement des probes Web — retry login 3× (V0.3)

Spawn le subagent `ans-probe-runner` avec ce prompt :

```
Tu es ans-probe-runner. Run les Playwright specs sous probes/<N>.spec.ts.
Mode : headed (default V0.x), viewport 1440x900.
Capture : on (chaque test), full page.

Login retry policy V0.3 :
- Si premier login échoue (timeout, mauvais selector, page d'erreur) : 1ère retry (sleep 2s puis re-login)
- Si 2nd échec : 2nde retry (sleep 5s + capture du DOM courant en debug + re-login)
- Si 3e échec : abandon, émettre `[PROBE-AUTH-FAILED] <raison>` en première ligne (le runner UI affichera notif macOS)

Output dans probes/reports/artifacts/<run-id>/ (folder dédié par run, immutable post-run) :
- Si pass → screenshot full page + DOM snapshot JSON
- Si fail (autre que login) → screenshot + trace.zip
- MANIFEST.md à la racine de probes/reports/ append-only avec sha256+timestamp+run_id par fichier

À la fin : chmod 444 sur tous les artefacts du run pour préserver l'intégrité.
```

### 6. Capture protocols (mobile / native / desktop)

Pour chaque stack hors-Web identifiée à l'étape 1, copie les capture protocols depuis `templates/capture-protocols/` :
- `mobile-ios.md` → `probes/capture-protocol-ios.md`
- `mobile-android.md` → `probes/capture-protocol-android.md`
- etc.

Personnalise chaque protocol avec :
- Nom du client
- URL ou nom de l'app
- Comptes testing à utiliser
- Liste numérotée des captures attendues, par exigence DMN couverte

Output au PM :
```
{{ N }} capture protocols générés pour les stacks non-Web.
À transmettre au client (RAQ) pour qu'il prenne les captures et les uploade dans probes/manual/.
Délai conseillé : 1 sem.
```

### 7. Lien probe ↔ exigence — V0.5 : double output (markdown + JSON structuré)

**Génère DEUX fichiers en parallèle** pour la traçabilité :

#### a) `probes/exigences-coverage.md` (humain, lu par PM/DP)

Table markdown listant pour chaque exigence DMN UI-observable :
- Probe (auto ou manuel) qui la couvre
- Statut probe : ✅ Capturé conforme / ❌ Capturé non-conforme / 🟡 Capturé partiel / ⏳ À capturer mobile / ❓ Non observable UI
- Fichier de capture (path)

#### b) `probes/exigences-coverage.json` (machine-readable, lu déterministiquement par `/ans-build`)

Schéma :

```json
{
  "schema_version": "v1",
  "run_id": "run-2026MMDD-XXXX",
  "generated_at": "<ISO8601>",
  "items": [
    {
      "exigence_id": "IEPS 4.1",
      "probe_verdict": "fail",
      "suggested_statut": "Non conforme",
      "evidence_files": ["06-rpps-04-rpps-coverage.json", "06-rpps-01-signup-page.png"],
      "verdict_hint": "Aucun champ RPPS/ADELI/FINESS détecté ; 5 patterns testés sans hit ; auto-déclaration checkbox uniquement",
      "cat_A": true
    },
    {
      "exigence_id": "INS 9.1",
      "probe_verdict": "non_observable",
      "suggested_statut": "À confirmer",
      "evidence_files": ["07-diacritics-04-diacritics-neutralisation.json"],
      "verdict_hint": "Search rowCount constant pour toutes variantes — probablement client-side sur liste statique ; non testable côté HCP web",
      "cat_A": false
    }
  ]
}
```

Mapping `probe_verdict` → `suggested_statut` (autoritaire, à respecter par `/ans-build`) :

| `probe_verdict` | `suggested_statut` |
|---|---|
| `pass` (✅ Capturé conforme) | `Conforme à étayer` |
| `fail` (❌ Capturé non-conforme) | `Non conforme` |
| `partial` (🟡 Capturé partiel) | `Partiel` |
| `mobile_pending` (⏳ À capturer mobile) | `À confirmer` |
| `non_observable` (❓ Non observable UI) | `À confirmer` |

Ce fichier est consommé par `/ans-build` étape 4.5 (pré-merge déterministe).

### 8. Output au PM

```
Probes UI {{ args }} — résumé :
- Web auto : X probes lancés, Y OK, Z failed
- Mobile/native : N protocols à compléter par le client (cf. probes/manual/)
- Couverture exigences UI-observables : X/Y exigences couvertes

Prochaines étapes :
1. Si tests Web ont failed, debug avec les traces .zip
2. Envoie les capture protocols au client (cf. probes/strategy.md)
3. Une fois toutes les captures reçues, lance /ans-build {{ args }}
```

## Sécurité

- JAMAIS écrire les creds en clair dans un fichier committé (`probes/.env.local` est gitignoré, mais Drive aussi à éviter)
- Utiliser `op read` à chaque probe-runner spawn, ne pas cacher
- À la fin de la mission, le `/ans-archive {{ args }}` révoque l'accès au vault

## Discipline

- Captures sans creds → ne couvrent que les pages publiques (/login, /signup) — utile mais limité
- Captures avec creds → preuves authentifiées valides pour Convergence
- Nommage strict des fichiers : `<probe-name>-<test-name>-OK.png` ou `capture-NNN-<description>.png` pour qu'`/ans-build` puisse les associer aux exigences

## Templates V0.1 disponibles

À ce stade (V0.1), seul `probe-login.spec.ts.tpl` et `probe-signup.spec.ts.tpl` sont matures. Les autres sont des squelettes à itérer.
Voir `templates/playwright/README.md` pour le statut détaillé.
