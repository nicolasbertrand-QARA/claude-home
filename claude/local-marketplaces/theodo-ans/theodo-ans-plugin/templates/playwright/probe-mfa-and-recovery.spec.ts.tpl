/**
 * Probe — Présence de 2FA / MFA + flux de récupération (mot de passe + identifiant).
 *
 * Exigences DMN ciblées :
 *   - IEPS 9.x : MFA disponible / imposée pour HCP (Conforme = imposée, Partiel = optionnelle)
 *   - IEU 9    : MFA imposée pour Usager (strict — clause télésurveillance possible)
 *   - IEU 5.1  : récupération mot de passe utilisateur
 *   - IEU 6.1  : récupération identifiant utilisateur (rare — souvent Partiel)
 *
 * Stratégie : on log-in HCP, on visite /main/account/security (et variantes),
 * on cherche les paramètres MFA. On va aussi sur /login et on clique
 * "Forgot password" / "Mot de passe oublié" pour capturer le flux email.
 */

import { test } from '@playwright/test';
import { loginAsHcp, dump, shot } from './_helpers';

test.describe('MFA + recovery flows (IEPS 9, IEU 5/6/9)', () => {
  test('IEPS 9 — MFA presence in HCP account settings', async ({ page }) => {
    const auth = await loginAsHcp(page);
    if (!auth.ok) { test.fail(true, `auth failed: ${auth.reason}`); return; }

    const candidates = ['/main/account/security', '/main/account', '/main/settings/security', '/main/profile'];
    const findings: any[] = [];
    for (const p of candidates) {
      try {
        await page.goto(p, { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1_500);
        if (page.url().includes('/login')) continue;
        await shot(page, `mfa-account-${p.replace(/\//g, '_').slice(0, 30)}`);
        const text = (await page.locator('body').innerText()).toLowerCase();
        const mfaSignals = {
          has_2fa: /\b2fa\b|two-factor|authentification.{0,10}deux|deux facteurs/i.test(text),
          has_mfa: /\bmfa\b|multi-factor/i.test(text),
          has_totp: /totp|authentificator|authentication app|google authenticator/i.test(text),
          has_sms: /sms.{0,10}auth|authentication.{0,10}sms/i.test(text),
          has_email_2fa: /email.{0,10}auth|verification.{0,10}email/i.test(text),
          has_imposed: /required|imposé|obligatoire|mandatory/i.test(text),
          has_optional: /optional|optionnel|recommended|recommandé/i.test(text),
        };
        findings.push({ path: p, url: page.url(), mfaSignals });
      } catch (_) {}
    }
    dump('mfa-hcp-account-search', findings);
  });

  test('IEU 5.1 — flux "mot de passe oublié" depuis /login', async ({ page }) => {
    await page.goto('/login', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1_500);

    const forgotLink = page.locator('a:has-text("Forgot"), a:has-text("Oublié"), a:has-text("Mot de passe oublié"), a:has-text("Réinitialiser"), button:has-text("Forgot")').first();
    if ((await forgotLink.count()) === 0) {
      dump('forgot-password-NOT-FOUND', { url: page.url(), verdict_hint: 'IEU 5.1 — pas de lien "mot de passe oublié" — Non conforme' });
      return;
    }

    try {
      await forgotLink.click({ timeout: 3_000 });
      await page.waitForTimeout(2_000);
      await shot(page, 'forgot-password-page');
      const formData = await page.evaluate(() => {
        const inputs = Array.from(document.querySelectorAll('input')).map((el: any) => ({
          type: el.type, name: el.name, placeholder: el.placeholder, ariaLabel: el.getAttribute('aria-label'),
        }));
        const text = ((document.body && document.body.innerText) || '').slice(0, 4000);
        return { inputs, text };
      });
      dump('forgot-password-form', { url: page.url(), ...formData });

      // Tester avec un email factice (sans submit réel pour ne pas spammer)
      const emailInput = page.locator('input[type="email"]').first();
      if ((await emailInput.count()) > 0) {
        await emailInput.fill('forgot-probe-test@theodo.test');
        await shot(page, 'forgot-password-filled');
      }
    } catch (_) {}
  });

  test('IEU 6.1 — flux "identifiant oublié" (souvent NC)', async ({ page }) => {
    await page.goto('/login', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1_500);

    const forgotIdentifierLink = page
      .locator('a:has-text("Forgot identifier"), a:has-text("Identifiant oublié"), a:has-text("Forgot username"), a:has-text("Forgot login")')
      .first();
    const found = (await forgotIdentifierLink.count()) > 0;
    dump('forgot-identifier-link', {
      found,
      verdict_hint: found
        ? 'IEU 6.1 — lien "identifiant oublié" présent — Conforme à étayer'
        : 'IEU 6.1 — pas de lien "identifiant oublié" — Non conforme (rare en pratique, souvent SOP support)',
    });
  });
});
