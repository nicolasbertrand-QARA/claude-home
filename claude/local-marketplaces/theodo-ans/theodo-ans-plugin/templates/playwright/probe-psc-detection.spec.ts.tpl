/**
 * Probe — Détection raccordement Pro Santé Connect (PSC).
 *
 * Exigences DMN ciblées :
 *   - PSC 1.1 : bouton ProSantéConnect sur la page de login HCP
 *   - PSC 6   : paramètre acr_values=eidas1 dans le flux OIDC déclenché par PSC
 *   - PSC 2   : déconnexion PSC déclenchée à la déconnexion HCP (logout single-sign-out)
 *
 * Stratégie : on va sur /login (publique), on cherche le bouton PSC. Si
 * présent, on intercepte les requêtes réseau quand on clique dessus pour
 * vérifier l'OIDC (acr_values=eidas1). Pas de retour vers PSC sandbox —
 * on s'arrête à la première redirection sortante.
 */

import { test } from '@playwright/test';
import { dump, shot } from './_helpers';

test.describe('Pro Santé Connect — détection (PSC 1, 6)', () => {
  test('PSC 1.1 — bouton PSC sur /login', async ({ page }) => {
    await page.goto('/login', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1_500);
    await shot(page, 'login-page-psc-detection');

    const pscSelectors = [
      'button:has-text("Pro Santé")',
      'a:has-text("Pro Santé")',
      'button:has-text("PSC")',
      'a:has-text("PSC")',
      'button:has-text("ProSanté")',
      'img[alt*="Pro Santé" i]',
      'img[alt*="ProSanté" i]',
      'img[alt*="PSC" i]',
      '[class*="psc" i]',
      '[id*="psc" i]',
      '[data-testid*="psc" i]',
    ];

    const counts: any[] = [];
    for (const sel of pscSelectors) {
      try {
        const c = await page.locator(sel).count();
        counts.push({ selector: sel, count: c });
      } catch (_) {}
    }
    const totalFound = counts.reduce((s, c) => s + c.count, 0);
    dump('psc-detection', {
      verdict_hint: totalFound > 0
        ? 'PSC 1.1 — bouton PSC détecté — Conforme à étayer (vérifier flux OIDC)'
        : 'PSC 1.1 — aucun bouton PSC détecté sur /login — Non conforme (Cat A bloquante Convergence)',
      totalSelectorsHit: totalFound,
      details: counts,
    });

    if (totalFound === 0) {
      // Vérifier également la page d'accueil — certains UX la mettent là
      await page.goto('/', { waitUntil: 'domcontentloaded' }).catch(() => {});
      await page.waitForTimeout(1_500);
      await shot(page, 'home-page-psc-detection');
      const homeCounts: any[] = [];
      for (const sel of pscSelectors) {
        try {
          const c = await page.locator(sel).count();
          if (c > 0) homeCounts.push({ selector: sel, count: c });
        } catch (_) {}
      }
      dump('psc-detection-on-home', { homePageHits: homeCounts });
    }
  });

  test('PSC 6 — flux OIDC contient acr_values=eidas1 (si PSC implémenté)', async ({ page, context }) => {
    await page.goto('/login', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1_500);

    const pscBtn = page
      .locator('button:has-text("Pro Santé"), a:has-text("Pro Santé"), button:has-text("PSC"), a:has-text("PSC"), [class*="psc" i], [data-testid*="psc" i]')
      .first();

    if ((await pscBtn.count()) === 0) {
      test.skip(true, 'PSC button absent — PSC 1.1 NC, PSC 6 sans objet');
      return;
    }

    // Capturer toutes les requêtes pour repérer authorize / oidc
    const requests: { url: string; method: string }[] = [];
    page.on('request', (req) => {
      const u = req.url();
      if (/authorize|oidc|openid|saml/i.test(u)) {
        requests.push({ url: u, method: req.method() });
      }
    });

    try {
      await pscBtn.click({ timeout: 3_000 });
    } catch (_) {}
    await page.waitForTimeout(3_000);
    await shot(page, 'psc-after-click');

    const hasAcrEidas1 = requests.some((r) => /acr_values=eidas1/i.test(r.url));
    dump('psc-oidc-flow', {
      requests,
      hasAcrEidas1,
      verdict_hint: hasAcrEidas1
        ? 'PSC 6 — acr_values=eidas1 présent — Conforme à étayer'
        : 'PSC 6 — acr_values=eidas1 absent ou pas dans cette redirection — À confirmer (peut être server-side)',
    });
  });
});
