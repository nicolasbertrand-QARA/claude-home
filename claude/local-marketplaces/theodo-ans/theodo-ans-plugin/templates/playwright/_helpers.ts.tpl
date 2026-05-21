/**
 * Helpers partagés par tous les probe specs Playwright — V0.4 plugin.
 *
 * Les credentials de testing sont en cleartext dans
 *   ~/missions/{{ CLIENT_SLUG }}/access/credentials.json   (chmod 600, gitignored)
 * Le test runner les lit via process.env.* — exporter via wrapper bash :
 *   HCP_EMAIL=$(jq -r .hcp_email ../access/credentials.json) \
 *   HCP_PASSWORD=$(jq -r .hcp_password ../access/credentials.json) \
 *   PATIENT_EMAIL=$(jq -r .patient_email ../access/credentials.json) \
 *   PATIENT_PASSWORD=$(jq -r .patient_password ../access/credentials.json) \
 *   npx playwright test ...
 *
 * Variables à substituer (placeholders {{ }}) — l'agent les remplit après discovery :
 *  - {{ CLIENT_SLUG }}            : identifiant client (ex: "sunrise")
 *  - {{ BASE_URL }}               : URL de base de la plateforme (ex: "https://testing.portal.client.com")
 *  - {{ LOGIN_PATH }}             : chemin /login (ex: "/login")
 *  - {{ EMAIL_SELECTOR }}         : sélecteur du champ email (input[type="email"], etc.)
 *  - {{ PASSWORD_SELECTOR }}      : sélecteur du champ password
 *  - {{ SUBMIT_SELECTOR }}        : sélecteur du bouton sign-in
 *  - {{ POST_LOGIN_URL_PATTERN }} : regex URL post-login (ex: "/main", "/dashboard")
 */

import { Page } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

export const RUN_ID = process.env.RUN_ID || `run-${Date.now()}`;
export const ARTIFACTS = path.join(__dirname, 'reports', 'artifacts', RUN_ID);
fs.mkdirSync(ARTIFACTS, { recursive: true });

export const HCP_EMAIL = process.env.HCP_EMAIL || process.env.{{ CLIENT_SLUG_UPPER }}_HCP_EMAIL || '';
export const HCP_PASSWORD = process.env.HCP_PASSWORD || process.env.{{ CLIENT_SLUG_UPPER }}_HCP_PASSWORD || '';
export const PATIENT_EMAIL = process.env.PATIENT_EMAIL || process.env.{{ CLIENT_SLUG_UPPER }}_PATIENT_EMAIL || '';
export const PATIENT_PASSWORD = process.env.PATIENT_PASSWORD || process.env.{{ CLIENT_SLUG_UPPER }}_PATIENT_PASSWORD || '';

export function shot(page: Page, name: string) {
  return page.screenshot({ path: path.join(ARTIFACTS, `${name}.png`), fullPage: true });
}

export function dump(name: string, data: any) {
  fs.writeFileSync(path.join(ARTIFACTS, `${name}.json`), JSON.stringify(data, null, 2));
}

export function dumpHtml(name: string, html: string) {
  fs.writeFileSync(path.join(ARTIFACTS, `${name}.html`), html);
}

/**
 * Force la langue FR avant tout test — V0.5.
 *
 * L'ANS / DMN n'existe qu'en France. Tester un site multi-langue en EN rate
 * les libellés français de la grille (« nom de naissance », « matricule INS »,
 * « sexe », « lieu de naissance INSEE », « RNIV », « PSC », « Pro Santé
 * Connect », « 2FA imposée », etc.) — donc faux-négatifs systématiques sur
 * les détections par texte (probe-patient-create-rniv, probe-tou-privacy-ifu,
 * probe-mfa-and-recovery).
 *
 * Stratégie en 3 paliers :
 *   1. Si l'URL contient ?lang=en ou /en/, basculer via toggle FR (cherche
 *      des selectors typiques : `a:has-text("FR")`, `[hreflang="fr"]`,
 *      `[data-locale="fr"]`, drapeau).
 *   2. Sinon, vérifier le lang attribute du <html> et bouton FR visible.
 *   3. Capture le state pour audit (artefact `00-locale-state.json`).
 *
 * À appeler **avant tout autre interaction** (loginAsHcp le fait déjà).
 */
export async function ensureFrenchLocale(page: Page): Promise<{ switched: boolean; lang: string; method: string | null }> {
  const initial = await page.evaluate(() => ({
    htmlLang: document.documentElement.lang,
    bodyText: ((document.body && document.body.innerText) || '').slice(0, 800),
    url: location.href,
  }));

  // Heuristique : déjà en FR ?
  const looksFrench = (text: string) =>
    /\b(connexion|s.identifier|inscription|mot de passe|adresse e-?mail|patient|m[eé]decin|d[eé]connexion|conditions g[eé]n[eé]rales)/i.test(text);
  if (initial.htmlLang?.toLowerCase().startsWith('fr') || looksFrench(initial.bodyText)) {
    dump('00-locale-state', { switched: false, lang: 'fr', method: 'already-fr', initial });
    return { switched: false, lang: 'fr', method: 'already-fr' };
  }

  // Tentative 1 : toggle FR via les selectors les plus communs
  const frToggleSelectors = [
    'a:has-text("FR")',
    'button:has-text("FR")',
    '[hreflang="fr"]',
    '[hreflang="fr-FR"]',
    '[data-locale="fr"]',
    'a:has-text("Français")',
    'button:has-text("Français")',
    'img[alt*="Français" i]',
    'img[alt*="French" i]',
  ];
  for (const sel of frToggleSelectors) {
    const loc = page.locator(sel).first();
    if ((await loc.count()) > 0) {
      try {
        await loc.click({ timeout: 3000 });
        await page.waitForLoadState('networkidle').catch(() => {});
        await page.waitForTimeout(800);
        const after = await page.evaluate(() => ({
          htmlLang: document.documentElement.lang,
          bodyText: ((document.body && document.body.innerText) || '').slice(0, 800),
          url: location.href,
        }));
        if (after.htmlLang?.toLowerCase().startsWith('fr') || looksFrench(after.bodyText)) {
          dump('00-locale-state', { switched: true, lang: 'fr', method: `toggle:${sel}`, initial, after });
          return { switched: true, lang: 'fr', method: `toggle:${sel}` };
        }
      } catch (_) {}
    }
  }

  // Tentative 2 : URL rewriting — beaucoup de SPA respectent ?lang=fr ou /fr/
  const urlVariants = [
    initial.url.replace(/\?lang=en/i, '?lang=fr').replace(/&lang=en/i, '&lang=fr'),
    initial.url.includes('?') ? `${initial.url}&lang=fr` : `${initial.url}?lang=fr`,
    initial.url.replace(/\/en(\/|$)/, '/fr$1'),
  ];
  for (const u of urlVariants) {
    if (u === initial.url) continue;
    try {
      await page.goto(u, { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(1000);
      const after = await page.evaluate(() => ({
        htmlLang: document.documentElement.lang,
        bodyText: ((document.body && document.body.innerText) || '').slice(0, 800),
        url: location.href,
      }));
      if (after.htmlLang?.toLowerCase().startsWith('fr') || looksFrench(after.bodyText)) {
        dump('00-locale-state', { switched: true, lang: 'fr', method: `url-rewrite:${u}`, initial, after });
        return { switched: true, lang: 'fr', method: `url-rewrite:${u}` };
      }
    } catch (_) {}
  }

  // Échec : on garde la version actuelle mais on flag dans les artifacts.
  // L'agent doit le voir et noter dans coverage.md → certaines exigences DOC/PSC/INS
  // pourront échapper à la détection texte FR.
  dump('00-locale-state', {
    switched: false,
    lang: initial.htmlLang || 'unknown',
    method: 'no-fr-toggle-found',
    warning: 'Site testé en langue non-FR — détections texte FR ratées probable. Considérer audit doc à la place.',
    initial,
  });
  return { switched: false, lang: initial.htmlLang || 'unknown', method: null };
}

/**
 * Login HCP avec retry 3× sur échec d'authentification (V0.3 — finding #6).
 * Émet `[PROBE-AUTH-FAILED]` en première ligne du test output sur fail final
 * pour permettre au runner UI de hard-stop la chain.
 *
 * V0.5 : force le passage en FR avant le login (les libellés ANS sont en FR).
 */
export async function loginAsHcp(page: Page): Promise<{ ok: boolean; reason?: string }> {
  if (!HCP_EMAIL || !HCP_PASSWORD) {
    console.log('[PROBE-AUTH-FAILED] HCP credentials missing in env (HCP_EMAIL + HCP_PASSWORD)');
    return { ok: false, reason: 'HCP credentials missing' };
  }
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      if (attempt > 1) {
        await page.waitForTimeout(attempt === 2 ? 2_000 : 5_000);
        await page.goto('{{ LOGIN_PATH }}', { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1_000);
      } else {
        await page.goto('{{ LOGIN_PATH }}', { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1_500);
      }
      // V0.5 — force la langue FR avant les interactions login
      // (sélecteurs et textes FR pour la détection ANS-spécifique)
      await ensureFrenchLocale(page);
      await page.locator('{{ EMAIL_SELECTOR }}').first().fill(HCP_EMAIL);
      await page.locator('{{ PASSWORD_SELECTOR }}').first().fill(HCP_PASSWORD);
      await page.locator('{{ SUBMIT_SELECTOR }}').last().click();
      await page.waitForURL((url) => !/\/login(\b|\/|$)/.test(url.toString()), { timeout: 15_000 }).catch(() => {});
      await page.waitForLoadState('networkidle').catch(() => {});
      const onLoginStill = /\/login(\b|\/|$)/.test(page.url());
      if (!onLoginStill) {
        return { ok: true };
      }
    } catch (e: any) {
      // continue to next attempt
    }
  }
  console.log(`[PROBE-AUTH-FAILED] Login refused after 3 attempts at ${page.url()}`);
  return { ok: false, reason: `still on /login after 3 attempts (${page.url()})` };
}

/**
 * Captures DOM-level evidence relevant to several DMN exigences :
 * inputs, labels, buttons, nav links, INS markers (presence in body text).
 */
export async function captureSurface(page: Page, slug: string) {
  await shot(page, `${slug}-screenshot`);
  dumpHtml(`${slug}-page`, await page.content());

  const surface = await page.evaluate(() => {
    const inputs = Array.from(document.querySelectorAll('input, select, textarea')).map((el: any) => ({
      tag: el.tagName.toLowerCase(),
      type: el.type || null,
      id: el.id || null,
      name: el.name || null,
      placeholder: el.placeholder || null,
      ariaLabel: el.getAttribute('aria-label'),
      autocomplete: el.getAttribute('autocomplete'),
      required: el.required ?? null,
      pattern: el.pattern ?? null,
    }));
    const buttons = Array.from(document.querySelectorAll('button, a[role="button"]'))
      .slice(0, 200)
      .map((el: any) => ({
        text: (el.innerText || '').trim().slice(0, 120),
        ariaLabel: el.getAttribute('aria-label'),
        disabled: !!el.disabled,
      }))
      .filter((b: any) => b.text || b.ariaLabel);
    const labels = Array.from(document.querySelectorAll('label, .label'))
      .map((el: any) => (el.innerText || '').trim().slice(0, 200))
      .filter(Boolean);
    const navLinks = Array.from(document.querySelectorAll('nav a, [class*="navbar"] a, .menu a'))
      .map((a: any) => ({ text: (a.innerText || '').trim().slice(0, 80), href: a.getAttribute('href') }))
      .filter((n: any) => n.text);
    const bodyText = ((document.body && document.body.innerText) || '').slice(0, 8000);
    const lowerBody = bodyText.toLowerCase();
    const insMarkers = {
      hasMatricule: /matricule/i.test(lowerBody),
      hasINS: /\bins\b|identifiant national de santé/i.test(lowerBody),
      hasNIR: /\bnir\b/i.test(lowerBody),
      hasOID: /\boid\b|1\.2\.250\.1\.213/i.test(lowerBody),
      hasBirthName: /nom de naissance|birth name/i.test(lowerBody),
      hasOfficialFirstNames: /pr[eé]noms? officiels?|first names?|liste des pr[eé]noms/i.test(lowerBody),
      hasInseeCode: /code insee|code commune (de )?naissance/i.test(lowerBody),
      hasSexLetter: /\bsexe\b.*[mfMF]/i.test(lowerBody),
      hasNationalId: /carte vitale|carte d.identité|titre d.identité/i.test(lowerBody),
    };
    return { inputs, buttons, labels, navLinks, insMarkers, bodyText };
  });

  dump(`${slug}-surface`, {
    url: page.url(),
    title: await page.title(),
    ...surface,
  });
  return surface;
}

/**
 * Try to navigate to the patient list / dashboard post-login.
 * Many apps land on /main or /dashboard or have a top-nav link "Patients".
 */
export async function gotoPatients(page: Page): Promise<boolean> {
  const candidates = ['/main/patients', '/patients', '/main', '/dashboard', '/'];
  for (const path of candidates) {
    try {
      await page.goto(path, { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(1_500);
      const text = (await page.locator('body').innerText()).toLowerCase();
      if (/patient/i.test(text)) {
        return true;
      }
    } catch (_) {}
  }
  return false;
}
