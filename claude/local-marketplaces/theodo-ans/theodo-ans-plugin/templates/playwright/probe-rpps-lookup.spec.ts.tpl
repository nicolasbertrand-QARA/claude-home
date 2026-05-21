/**
 * Probe — Inscription HCP avec lookup RPPS / Annuaire Santé.
 *
 * Exigences DMN ciblées :
 *   - IEPS 4.1 : inscription HCP collecte profession + RPPS / ADELI / FINESS
 *   - ANN 1-5  : Annuaire Santé interrogé pour qualification HCP (au lieu de
 *                self-declared)
 *
 * Stratégie : on va sur le signup HCP (/signup), on scanne les inputs et on
 * cherche un champ RPPS / ADELI / FINESS / "numéro professionnel" / "carte
 * CPS" — présence/absence + comportement (validation côté client ?
 * appel ANN ? auto-fill profession après lookup ?). On regarde aussi les
 * options "Profession" (médecin, infirmier, sage-femme, etc.).
 *
 * Pas d'inscription réelle — on remplit puis on abandonne.
 */

import { test } from '@playwright/test';
import { dump, shot, dumpHtml } from './_helpers';

test.describe('HCP signup — RPPS / Annuaire Santé (IEPS 4, ANN 1-5)', () => {
  test('IEPS 4.1 / ANN — RPPS lookup field on /signup', async ({ page }) => {
    // Pas besoin de login — la page signup est publique
    await page.goto('/signup', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1_500);
    await shot(page, 'hcp-signup-page');
    dumpHtml('hcp-signup-page', await page.content());

    // Scanner inputs + labels + options
    const formData = await page.evaluate(() => {
      const inputs = Array.from(document.querySelectorAll('input, select, textarea')).map((el: any) => {
        const labelFor = el.id ? document.querySelector(`label[for="${el.id}"]`) : null;
        const closestLabel = el.closest('label');
        const labelText = (labelFor as any)?.innerText || (closestLabel as any)?.innerText || '';
        return {
          tag: el.tagName.toLowerCase(),
          type: el.type || null,
          id: el.id || null,
          name: el.name || null,
          placeholder: el.placeholder || null,
          ariaLabel: el.getAttribute('aria-label'),
          labelText: labelText.trim().slice(0, 200),
          autocomplete: el.getAttribute('autocomplete'),
          options: el.tagName.toLowerCase() === 'select'
            ? Array.from(el.options).map((o: any) => o.value + '|' + o.text).slice(0, 100)
            : undefined,
        };
      });
      const checkboxes = Array.from(document.querySelectorAll('input[type="checkbox"], input[type="radio"]')).map((el: any) => {
        const closestLabel = el.closest('label');
        return {
          type: el.type, id: el.id, name: el.name,
          labelText: ((closestLabel as any)?.innerText || '').trim().slice(0, 200),
        };
      });
      const allText = ((document.body && document.body.innerText) || '').slice(0, 8000);
      return { inputs, checkboxes, allText };
    });
    dump('hcp-signup-fields', formData);

    // Détecter champ RPPS / ADELI / FINESS / CPS
    const RPPS_PATTERNS = [
      { id: 'rpps',     re: /\brpps\b|num[eé]ro rpps|rpps number/i },
      { id: 'adeli',    re: /\badeli\b/i },
      { id: 'finess',   re: /\bfiness\b/i },
      { id: 'cps_card', re: /\bcps\b|carte cps|carte professionnel/i },
      { id: 'pro_id',   re: /num[eé]ro professionnel|num[eé]ro identification|professional id/i },
    ];

    function findIn(patterns: RegExp[]) {
      for (const inp of formData.inputs) {
        const haystack = `${inp.id || ''} ${inp.name || ''} ${inp.placeholder || ''} ${inp.ariaLabel || ''} ${inp.labelText || ''}`;
        for (const p of patterns) {
          if (p.test(haystack)) return { found: true, where: haystack.trim().slice(0, 100) };
        }
      }
      return { found: false, where: null };
    }

    const rppsCoverage = RPPS_PATTERNS.map((p) => ({ id: p.id, ...findIn([p.re]) }));
    dump('hcp-signup-rpps-coverage', rppsCoverage);

    const anyProIdField = rppsCoverage.some((c) => c.found);
    dump('hcp-signup-IEPS-4-verdict-hint', {
      proIdFieldPresent: anyProIdField,
      verdict_hint: anyProIdField
        ? 'IEPS 4.1 — au moins un champ RPPS/ADELI/FINESS présent — Conforme à étayer (vérifier validation côté serveur via ANN)'
        : 'IEPS 4.1 — aucun champ identifiant pro détecté — Non conforme (auto-déclaration ou checkbox \"je certifie\")',
    });

    // Détecter les options de profession (sélecteur rôle / spécialité)
    const professionSelect = formData.inputs.find((i: any) =>
      /profession|specialty|sp[eé]cialit[eé]|role|m[eé]tier/i.test((i.labelText || '') + ' ' + (i.name || '') + ' ' + (i.id || '')),
    );
    dump('hcp-signup-profession-select', { found: !!professionSelect, options: (professionSelect as any)?.options || [] });

    // Tenter un lookup avec un faux RPPS pour observer la validation
    const rppsField = page.locator('input[name*="rpps" i], input[id*="rpps" i], input[placeholder*="rpps" i], input[aria-label*="rpps" i]').first();
    if ((await rppsField.count()) > 0) {
      try {
        await rppsField.fill('00000000000');  // 11 zéros — invalide
        await page.locator('body').click({ position: { x: 5, y: 5 } });
        await page.waitForTimeout(1_500);
        await shot(page, 'hcp-signup-rpps-invalid');
        const errors = await page.$$eval('.error-text, [class*="error"]', (els: any[]) =>
          els.map((e: any) => ({ class: e.className, text: (e.innerText || '').trim().slice(0, 200) })).filter((e: any) => e.text),
        );
        dump('hcp-signup-rpps-invalid-validation', { triggered: errors.length > 0, errors });
      } catch (_) {}
    }
  });
});
