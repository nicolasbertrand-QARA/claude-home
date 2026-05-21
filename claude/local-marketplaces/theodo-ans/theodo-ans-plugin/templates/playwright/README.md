# Playwright probe templates — V0.4

Bibliothèque de patterns Playwright pour `/ans-probe` couvrant **les
exigences UI-observables du référentiel DMN v1.2.2**. L'agent instancie
ces templates au runtime en remplissant les placeholders `{{ }}` après
discovery (login URL, sélecteurs email/password/submit, URL pattern
post-login).

## Couverture par profil DMN

| Template | Profil concerné | Exigences DMN ciblées |
|---|---|---|
| `_helpers.ts.tpl` | (transverse) | login retry 3× + capture surface DOM + emission `[PROBE-AUTH-FAILED]` |
| `probe-login.spec.ts.tpl` | Accès Pro / Usager | IEPS 9.1, 12 + détection PSC 1 |
| `probe-rpps-lookup.spec.ts.tpl` | Accès Pro | IEPS 4.1, ANN 1-5 |
| `probe-mfa-and-recovery.spec.ts.tpl` | Accès Pro / Usager | IEPS 9, IEU 5.1, 6.1, 9 |
| `probe-psc-detection.spec.ts.tpl` | Accès Pro | PSC 1.1, PSC 6 (acr_values=eidas1) |
| `probe-tou-privacy-ifu.spec.ts.tpl` | Général + RGPD | DOC 1, DOC 2, PSC 5.1 |
| `probe-data-export-rgpd.spec.ts.tpl` | RGPD / Accès Usager | PORT 1.1 (Art. 20) |
| `probe-patient-search.spec.ts.tpl` | Référentiel d'identités | INS 7.1-7.5, INS 8.1 |
| `probe-patient-search-diacritics.spec.ts.tpl` | Référentiel d'identités | INS 9.1-9.4, INS 10 |
| `probe-patient-create-rniv.spec.ts.tpl` | Référentiel d'identités | INS 1.1, 4.1, 6.1, 11 |
| `probe-pdf-ins-label.spec.ts.tpl` | Identitovigilance | INS 42, 43, 44 |

À écrire (V0.5 — exigences moins haute priorité) :
- `probe-patient-edit-strict.spec.ts.tpl` (INS 11 — distinction stricts/comp)
- `probe-share-hcp-to-hcp.spec.ts.tpl` (INS 41 — partage avec logs INS)
- `probe-idle-timeout.spec.ts.tpl` (IEPS 13 — long idle)
- `probe-lockout.spec.ts.tpl` (IEPS 9.4 + IEU 9.4 — déjà été fait à la volée par l'agent sur Sunrise)
- `probe-mssante-flow.spec.ts.tpl` (ANN 5.1 — si scope messagerie HCP→HCP)

## Convention d'usage

1. L'agent fait un discovery initial (capture de la page de login + DOM)
   pour identifier les sélecteurs réels du client.

2. L'agent **copie** le template `.tpl` vers `probes/01-login.spec.ts`
   etc., et **substitue** les placeholders `{{ EMAIL_SELECTOR }}` etc.
   par les sélecteurs réels.

3. Les credentials de testing sont lus depuis
   `~/missions/<client>/access/credentials.json` (V0.3.2 — chmod 600,
   gitignored, exclu du sync Drive). Le wrapper bash de lancement les
   exporte en variables d'environnement avant `npx playwright test`.

4. Chaque probe écrit ses artefacts dans `probes/reports/artifacts/<RUN_ID>/`.

## Mapping probe verdict → assessment statut

`/ans-build` lit `probes/exigences-coverage.md` (cf. `rules/probe-evidence.md`) :

| Probe verdict | Assessment statut |
|---|---|
| ✅ « Capturé conforme » | `Conforme à étayer` (QMS doc à valider) |
| ❌ « Capturé non-conforme » | `Non conforme` (Cat A si bloquant Convergence) |
| 🟡 « Capturé partiel » | `Partiel` |
| ⏳ « À capturer (mobile) » | `À confirmer` (légitime) |
| ❓ « Non observable UI » | Consulter doc QMS, sinon `À confirmer` |

## Discipline

- **Pas de modification de données** sur l'environnement testing client.
- **Pas d'inscription réelle** au signup HCP/Patient.
- **Préservation lockout** : tester IEPS 9.4 / IEU 9.4 utilise des emails
  factices (`lockout-probe-<ts>@theodo.test`).
- **Hard-stop sur auth-fail** : si le login HCP échoue après 3 tentatives,
  le helper émet `[PROBE-AUTH-FAILED] <raison>` en première ligne du test
  output. Le runner UI le détecte et halt la chaîne auto avec notification
  macOS.
