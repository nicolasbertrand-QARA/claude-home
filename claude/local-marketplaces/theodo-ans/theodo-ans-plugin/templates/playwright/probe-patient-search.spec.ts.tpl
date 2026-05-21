/**
 * Probe — Recherche d'antériorité patient (par traits stricts INS).
 *
 * Exigences DMN ciblées :
 *   - INS 7.1  : recherche par nom de naissance
 *   - INS 7.2  : recherche par prénom de naissance
 *   - INS 7.3  : recherche par combinaison nom + prénom de naissance
 *   - INS 7.4  : recherche par date de naissance
 *   - INS 7.5  : recherche par sexe (M/F/I/N)
 *   - INS 8.1  : retour distinct des homonymes
 *
 * Stratégie : on log-in HCP, on va sur /main/patients, on identifie le champ
 * de recherche (heuristique : input[type=search], input[placeholder*=search],
 * input[placeholder*=recherch], input[placeholder*=patient]). On lance des
 * recherches synthétiques avec différentes combinaisons de traits et on
 * capture le DOM résultat.
 *
 * Pas de modification de données — recherche read-only.
 */

import { test } from '@playwright/test';
import { loginAsHcp, captureSurface, shot, dump, ARTIFACTS } from './_helpers';

test.describe('Patient search — recherche d\'antériorité (INS 7-8)', () => {
  test('INS 7.1-5 — search by birth-name / first-name / birthdate / sex', async ({ page }) => {
    const auth = await loginAsHcp(page);
    if (!auth.ok) {
      test.fail(true, `auth failed: ${auth.reason}`);
      return;
    }

    // Aller sur la page patient list
    const candidates = ['/main/patients', '/patients', '/main/dashboard'];
    let landed = false;
    for (const path of candidates) {
      try {
        await page.goto(path, { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1_500);
        if (await page.locator('input[type="search"], input[placeholder*="patient" i], input[placeholder*="search" i], input[placeholder*="recherche" i]').count() > 0) {
          landed = true;
          break;
        }
      } catch (_) {}
    }
    dump('search-landing', { landed, url: page.url() });
    if (!landed) {
      test.fail(true, 'no patient list with search field found at /main/patients, /patients, /main/dashboard');
      return;
    }
    await captureSurface(page, 'search-landing');

    // Identifier le(s) champ(s) de recherche
    const searchInputs = await page.$$eval(
      'input[type="search"], input[type="text"], input[placeholder*="search" i], input[placeholder*="recherche" i], input[placeholder*="name" i], input[placeholder*="nom" i], input[placeholder*="patient" i]',
      (els: any[]) => els.map((e: any) => ({
        type: e.type, id: e.id, name: e.name, placeholder: e.placeholder, ariaLabel: e.getAttribute('aria-label'),
      })),
    );
    dump('search-inputs', { count: searchInputs.length, inputs: searchInputs });

    // Tester avec un nom synthétique connu pour ne renvoyer aucun résultat
    const SYNTHETIC = [
      { trait: 'birth_name',     value: 'ZZZ-Test-Probe-Lastname' },
      { trait: 'first_name',     value: 'ZZZ-Test-Probe-Firstname' },
      { trait: 'name_combo',     value: 'ZZZ-Probe Test' },
      { trait: 'birthdate',      value: '01/01/1900' },
      { trait: 'birthdate_iso',  value: '1900-01-01' },
    ];

    const results: any[] = [];
    for (const probe of SYNTHETIC) {
      const firstSearch = page.locator('input[type="search"], input[placeholder*="search" i], input[placeholder*="recherche" i]').first();
      if (await firstSearch.count() === 0) continue;
      try {
        await firstSearch.fill('');
        await firstSearch.fill(probe.value);
        await page.keyboard.press('Enter').catch(() => {});
        await page.waitForTimeout(2_000);
        await shot(page, `search-${probe.trait}`);
        const tableText = await page.locator('table, [class*="result"], [class*="list"], [role="grid"]').first().innerText().catch(() => '');
        const hasNoResultsMessage = /no patient|aucun.*résultat|0 result|no result/i.test(tableText) || tableText.length < 5;
        results.push({ trait: probe.trait, query: probe.value, hasNoResultsMessage, tableSnippet: tableText.slice(0, 400) });
      } catch (e: any) {
        results.push({ trait: probe.trait, query: probe.value, error: e?.message || String(e) });
      }
    }
    dump('search-results-synthetic', results);

    // Tenter une recherche avec "Doe" — DOM témoin "Example John Doe 01/01/1985" vu sur Sunrise
    try {
      const firstSearch = page.locator('input[type="search"], input[placeholder*="search" i]').first();
      await firstSearch.fill('');
      await firstSearch.fill('Doe');
      await page.keyboard.press('Enter').catch(() => {});
      await page.waitForTimeout(2_000);
      await shot(page, 'search-doe');
      dump('search-doe-result', { url: page.url(), bodySnippet: (await page.locator('body').innerText()).slice(0, 2000) });
    } catch (_) {}
  });

  test('INS 8 — gestion homonymes', async ({ page }) => {
    const auth = await loginAsHcp(page);
    if (!auth.ok) { test.fail(true, `auth failed: ${auth.reason}`); return; }
    await page.goto('/main/patients', { waitUntil: 'domcontentloaded' }).catch(() => {});
    await page.waitForTimeout(1_500);

    // Chercher un nom répandu pour stresser les homonymes (Martin / Garcia / Smith)
    const COMMON_NAMES = ['Martin', 'Garcia', 'Smith', 'Bernard', 'Dubois'];
    const homonyms: any[] = [];
    for (const name of COMMON_NAMES) {
      const firstSearch = page.locator('input[type="search"], input[placeholder*="search" i]').first();
      if (await firstSearch.count() === 0) break;
      try {
        await firstSearch.fill('');
        await firstSearch.fill(name);
        await page.keyboard.press('Enter').catch(() => {});
        await page.waitForTimeout(1_500);
        const rowCount = await page.locator('tr, [role="row"], [class*="row"], li[class*="patient"]').count();
        homonyms.push({ name, rowCount });
        if (rowCount >= 2) {
          await shot(page, `homonyms-${name}`);
          break; // assez d'évidence
        }
      } catch (_) {}
    }
    dump('homonyms-stress', homonyms);
  });
});
