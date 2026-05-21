/**
 * Probe — Export des données personnelles (Article 20 RGPD — portabilité).
 *
 * Exigences DMN ciblées :
 *   - PORT 1.1 : utilisateur peut télécharger un export de ses données
 *                personnelles dans un format structuré + machine-readable
 *                (JSON / CSV / XML), depuis son espace compte
 *   - RGPD 1.x : politique de protection des données accessible
 *
 * Stratégie : on log-in, on va sur /main/account, on cherche un bouton
 * "Export my data" / "Télécharger mes données" / "Data export" / "Export
 * RGPD". Si présent, on capture l'action (déclenche-t-elle un download
 * direct ou un email avec un lien ?). Si absent, NC.
 *
 * Note : sur Sunrise, ce probe peut sortir NC — il s'agit d'un client B2C
 * où la portabilité Art. 20 est souvent implémentée par ticket DPO et non
 * en self-service. À documenter dans coverage.md.
 */

import { test } from '@playwright/test';
import { loginAsHcp, dump, shot } from './_helpers';

test.describe('RGPD Art. 20 — export portabilité données (PORT 1.1)', () => {
  test('PORT 1.1 — bouton ou lien d\'export des données depuis /main/account', async ({ page }) => {
    const auth = await loginAsHcp(page);
    if (!auth.ok) { test.fail(true, `auth failed: ${auth.reason}`); return; }

    // Visiter /main/account et toutes les sous-pages "settings" / "privacy"
    const candidatePaths = [
      '/main/account',
      '/main/account/privacy',
      '/main/account/data',
      '/main/account/settings',
      '/main/settings',
      '/main/profile',
      '/account',
      '/profile',
      '/settings',
    ];

    const findings: any[] = [];

    for (const path of candidatePaths) {
      try {
        await page.goto(path, { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1_500);
        const url = page.url();
        if (url.includes('/login')) continue;  // redirected — path doesn't exist or not authenticated

        const exportFound = await page.evaluate(() => {
          const candidates = Array.from(document.querySelectorAll('button, a, [role="button"]'));
          const matches: any[] = [];
          for (const el of candidates) {
            const text = ((el as any).innerText || '').trim();
            const aria = el.getAttribute('aria-label') || '';
            const haystack = (text + ' ' + aria).toLowerCase();
            if (/export.{0,20}(my )?data|download.{0,10}(my )?data|t[eé]l[eé]charger.{0,20}donn[eé]es|export.{0,20}rgpd|gdpr.{0,20}export|portabilit[eé]/i.test(haystack)) {
              matches.push({ text: text.slice(0, 200), aria });
            }
          }
          return matches;
        });

        await shot(page, `rgpd-account-${path.replace(/\//g, '_').slice(0, 30)}`);
        findings.push({ path, url, exportButtonsFound: exportFound });
        if (exportFound.length > 0) {
          // Tester un clic — on attend un download OU une modale
          try {
            const downloadPromise = page.waitForEvent('download', { timeout: 10_000 }).catch(() => null);
            const exportBtn = page.locator(`text=/export.{0,20}(my )?data|download.{0,10}(my )?data|portabilit[eé]/i`).first();
            await exportBtn.click({ timeout: 3_000 });
            await page.waitForTimeout(3_000);
            const dl = await downloadPromise;
            if (dl) {
              findings[findings.length - 1].downloadTriggered = true;
              findings[findings.length - 1].downloadFilename = dl.suggestedFilename();
            } else {
              const modalText = await page.locator('body').innerText();
              findings[findings.length - 1].modalText = modalText.slice(0, 1500);
            }
            await shot(page, `rgpd-account-${path.replace(/\//g, '_').slice(0, 30)}-after-click`);
          } catch (_) {}
        }
      } catch (_) {}
    }

    dump('rgpd-export-search', findings);

    const anyExportFound = findings.some((f: any) => f.exportButtonsFound && f.exportButtonsFound.length > 0);
    dump('PORT-1-verdict-hint', {
      anyExportFound,
      verdict_hint: anyExportFound
        ? 'PORT 1.1 — bouton d\'export trouvé — Conforme à étayer'
        : 'PORT 1.1 — aucun bouton d\'export self-service — Non conforme ou Partiel selon SOP DPO existante',
    });
  });
});
