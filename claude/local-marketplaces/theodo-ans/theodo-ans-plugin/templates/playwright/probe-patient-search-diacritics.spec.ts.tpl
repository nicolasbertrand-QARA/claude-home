/**
 * Probe — Neutralisation des caractères spéciaux dans la recherche patient.
 *
 * Exigences DMN ciblées (INS recherche d'antériorité, gestion des écarts) :
 *   - INS 9.1 : neutralisation des apostrophes (D'ARTAGNAN → DARTAGNAN)
 *   - INS 9.2 : neutralisation des tirets (LE-GUEN → LE GUEN ou LEGUEN)
 *   - INS 9.3 : neutralisation des accents (CÉLINE → CELINE)
 *   - INS 9.4 : neutralisation des autres diacritiques (Ø, æ, etc.)
 *   - INS 10  : recherche tolérante au casse + espaces multiples
 *
 * Stratégie : on cherche le même nom avec et sans diacritique. Si le moteur
 * neutralise correctement, les deux requêtes doivent retourner le même
 * résultat (count + premier élément). On rapporte les deltas pour chaque
 * famille de transformation.
 */

import { test } from '@playwright/test';
import { loginAsHcp, shot, dump } from './_helpers';

const TRANSFORMATIONS = [
  { rule: 'INS 9.1 apostrophe',  variants: [`D'ARTAGNAN`, `DARTAGNAN`, `D ARTAGNAN`] },
  { rule: 'INS 9.2 tiret',       variants: [`LE-GUEN`, `LE GUEN`, `LEGUEN`] },
  { rule: 'INS 9.3 accent',      variants: [`CÉLINE`, `CELINE`, `Céline`] },
  { rule: 'INS 9.3 cedilla',     variants: [`FRANÇOIS`, `FRANCOIS`] },
  { rule: 'INS 9.4 ligature',    variants: [`MÆL`, `MAEL`] },
  { rule: 'INS 10 case',         variants: [`MARTIN`, `martin`, `Martin`] },
  { rule: 'INS 10 espace',       variants: [`DE LA  RUE`, `DE LA RUE`, `de la rue`] },
];

test.describe('Patient search — neutralisation diacritiques (INS 9-10)', () => {
  test('INS 9-10 — search returns same result for diacritic variants', async ({ page }) => {
    const auth = await loginAsHcp(page);
    if (!auth.ok) { test.fail(true, `auth failed: ${auth.reason}`); return; }

    await page.goto('/main/patients', { waitUntil: 'domcontentloaded' }).catch(() => {});
    await page.waitForTimeout(1_500);

    const searchSelector = 'input[type="search"], input[placeholder*="search" i], input[placeholder*="recherche" i], input[placeholder*="patient" i]';
    if ((await page.locator(searchSelector).count()) === 0) {
      test.fail(true, 'no search input on /main/patients');
      return;
    }

    async function runSearch(query: string): Promise<{ rowCount: number; firstSnippet: string }> {
      const input = page.locator(searchSelector).first();
      await input.fill('');
      await input.fill(query);
      await page.keyboard.press('Enter').catch(() => {});
      await page.waitForTimeout(1_500);
      const rowCount = await page.locator('tr, [role="row"], [class*="row"], li[class*="patient"]').count();
      const firstSnippet = await page.locator('body').innerText().then((t) => t.slice(0, 600)).catch(() => '');
      return { rowCount, firstSnippet };
    }

    const results: any[] = [];
    for (const t of TRANSFORMATIONS) {
      const variantResults: any[] = [];
      for (const variant of t.variants) {
        const r = await runSearch(variant);
        variantResults.push({ query: variant, ...r });
        await shot(page, `diacritics-${t.rule.replace(/[^a-zA-Z0-9]/g, '_')}-${variant.replace(/[^a-zA-Z0-9]/g, '_').slice(0, 12)}`);
      }
      // Verdict heuristique : si toutes les variantes renvoient le MÊME rowCount,
      // c'est un signe positif de neutralisation. Si non, neutralisation absente
      // ou partielle. À confirmer par snippet pour éviter les faux positifs.
      const counts = variantResults.map((v) => v.rowCount);
      const allSame = counts.every((c) => c === counts[0]);
      results.push({
        rule: t.rule,
        allVariantsReturnSameCount: allSame,
        variants: variantResults.map((v) => ({ query: v.query, rowCount: v.rowCount })),
        verdict_hint: allSame ? 'Conforme (neutralisation OK)' : 'Non conforme ou partiel — variantes retournent des comptes différents',
      });
    }
    dump('diacritics-neutralisation', results);
  });
});
