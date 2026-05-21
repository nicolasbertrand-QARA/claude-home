/**
 * Probe : flux de login HCP — exigences IEPS 9.1, IEPS 12, PSC 1/2/6.
 *
 * Variables à substituer (placeholders {{ }}) :
 *  - {{ CLIENT_SLUG }} : identifiant client (ex: "sunrise")
 *  - {{ BASE_URL }} : URL de base de la plateforme HCP (ex: "https://testing.portal.client.com")
 *  - {{ LOGIN_PATH }} : chemin du login (ex: "/login")
 *  - {{ EMAIL_SELECTOR }} : sélecteur du champ email (découvert par discovery)
 *  - {{ PASSWORD_SELECTOR }} : sélecteur du champ password
 *  - {{ SUBMIT_SELECTOR }} : sélecteur du bouton de connexion (souvent dans <main>, scope strict)
 *  - {{ POST_LOGIN_URL_PATTERN }} : pattern URL après login réussi (ex: "/main", "/dashboard")
 *
 * Pré-requis :
 *  - Variables d'env {{ CLIENT_SLUG_UPPER }}_HCP_EMAIL et {{ CLIENT_SLUG_UPPER }}_HCP_PASSWORD
 *    chargées depuis 1Password vault Theodo-ANS/{{ CLIENT_SLUG }}-testing via probes/.env.local
 */

import { test, expect, Page } from '@playwright/test';
import * as fs from 'fs';

const HCP_EMAIL = process.env.{{ CLIENT_SLUG_UPPER }}_HCP_EMAIL!;
const HCP_PASSWORD = process.env.{{ CLIENT_SLUG_UPPER }}_HCP_PASSWORD!;

test.describe('Login HCP — {{ CLIENT_SLUG }}', () => {
  test('IEPS 9.1 / PSC 1 — page de login accessible et structure', async ({ page }) => {
    await page.goto('{{ LOGIN_PATH }}');
    await page.waitForLoadState('networkidle');
    await page.screenshot({
      path: 'reports/artifacts/probe-login-page.png',
      fullPage: true,
    });

    // PSC 1 — détection bouton Pro Santé Connect
    const pscButton = page
      .getByRole('button', { name: /pro santé connect|psc/i })
      .or(page.getByRole('link', { name: /pro santé connect|psc/i }))
      .or(page.locator('img[alt*="Pro Santé Connect" i]'));
    const pscCount = await pscButton.count();
    fs.writeFileSync(
      'reports/artifacts/probe-login-psc-detection.json',
      JSON.stringify({ pscButtonCount: pscCount, expected: 'PSC implementé = 1+, sinon 0' }, null, 2),
    );

    // Inputs présents (email + password)
    const emailInput = page.locator('{{ EMAIL_SELECTOR }}');
    const passwordInput = page.locator('{{ PASSWORD_SELECTOR }}');
    await expect(emailInput).toBeVisible();
    await expect(passwordInput).toBeVisible();

    // Lien "mot de passe oublié" — IEPS 5.1
    const forgotLink = page.getByRole('link', { name: /forgot|oublié/i }).or(
      page.getByText(/mot de passe.*oublié|oublié.*mot de passe/i),
    );
    const forgotCount = await forgotLink.count();
    expect(forgotCount, 'IEPS 5.1 — lien mot de passe oublié attendu').toBeGreaterThan(0);
  });

  test('IEPS 12 — login + logout avec un compte HCP valide', async ({ page }) => {
    test.skip(!HCP_EMAIL || !HCP_PASSWORD, 'Creds HCP absents — vérifier vault 1Password');

    // Login
    await page.goto('{{ LOGIN_PATH }}');
    await page.waitForLoadState('networkidle');
    await page.locator('{{ EMAIL_SELECTOR }}').fill(HCP_EMAIL);
    await page.locator('{{ PASSWORD_SELECTOR }}').fill(HCP_PASSWORD);
    await page.locator('{{ SUBMIT_SELECTOR }}').first().click();
    await page.waitForURL(new RegExp('{{ POST_LOGIN_URL_PATTERN }}'), { timeout: 15_000 });
    await page.waitForLoadState('networkidle');
    await page.screenshot({
      path: 'reports/artifacts/probe-login-success.png',
      fullPage: true,
    });

    // Logout — chercher dans menu / hamburger / page entière
    const logoutTrigger = page
      .getByRole('button', { name: /log ?out|déconnexion|sign ?out|se déconnecter/i })
      .or(page.getByRole('menuitem', { name: /log ?out|déconnexion/i }))
      .or(page.getByRole('link', { name: /log ?out|déconnexion/i }));

    // Si pas trouvé direct, ouvrir le hamburger menu en premier
    if ((await logoutTrigger.count()) === 0) {
      const hamburger = page.locator('header button, .navbar button, [class*="menu"] button, [class*="burger"]').first();
      if (await hamburger.count()) {
        await hamburger.click().catch(() => {});
        await page.waitForTimeout(800);
      }
    }

    const logoutBtn = page
      .getByRole('button', { name: /log ?out|déconnexion|sign ?out|se déconnecter/i })
      .or(page.getByRole('link', { name: /log ?out|déconnexion/i }))
      .or(page.getByText(/se déconnecter|déconnexion|log\s?out/i));
    const logoutCount = await logoutBtn.count();
    expect(logoutCount, 'IEPS 12 — fonction logout attendue').toBeGreaterThan(0);

    if (logoutCount > 0) {
      await logoutBtn.first().click();
      await page.waitForLoadState('networkidle');
      await page.screenshot({
        path: 'reports/artifacts/probe-login-after-logout.png',
        fullPage: true,
      });
      // Après logout, on attend une URL de login ou racine
      await expect(page).toHaveURL(/login|signin|\/$/);
    }
  });

  test('PSC 6 — paramètre acr_values=eidas1 dans le flux PSC (si PSC implémenté)', async ({ page, context }) => {
    await page.goto('{{ LOGIN_PATH }}');
    await page.waitForLoadState('networkidle');

    const pscButton = page.getByRole('button', { name: /pro santé connect|psc/i }).first();
    if ((await pscButton.count()) === 0) {
      test.skip(true, 'PSC non implémenté — PSC 1.1 Non conforme, PSC 6 sans objet');
      return;
    }

    // Capturer les requêtes pour vérifier acr_values=eidas1
    const requests: string[] = [];
    context.on('request', (req) => {
      if (req.url().includes('authorize') || req.url().includes('oidc')) {
        requests.push(req.url());
      }
    });

    await pscButton.click();
    await page.waitForTimeout(2000);

    fs.writeFileSync(
      'reports/artifacts/probe-login-psc-requests.json',
      JSON.stringify(requests, null, 2),
    );

    const hasEidas1 = requests.some((r) => r.includes('acr_values=eidas1'));
    expect(hasEidas1, 'PSC 6 — acr_values=eidas1 attendu dans la requête OIDC').toBe(true);
  });
});
