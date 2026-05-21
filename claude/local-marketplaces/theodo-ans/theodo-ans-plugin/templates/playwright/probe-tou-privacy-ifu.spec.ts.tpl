/**
 * Probe — Présence des liens Conditions Générales d'Utilisation (CGU/ToU),
 * Politique de Confidentialité (Privacy / Privacy Policy) et Notice
 * d'Utilisation (IFU / Manuel utilisateur).
 *
 * Exigences DMN ciblées :
 *   - DOC 1   : CGU + privacy + IFU accessibles depuis l'app
 *   - DOC 2   : version + date d'effet visible sur la CGU
 *   - PSC 5.1 : CGU spécifique au flux PSC (si PSC implémenté)
 *
 * Stratégie : on visite /, /login, /main (post-login), et on capture tous
 * les liens du footer + header qui matchent les patterns CGU / privacy /
 * IFU. On suit le lien IFU s'il est présent et on capture la cible
 * (PDF download direct ? page interne ? lien externe ?).
 */

import { test } from '@playwright/test';
import { loginAsHcp, dump, shot } from './_helpers';

test.describe('Documents légaux — CGU, Privacy, IFU (DOC 1-2, PSC 5)', () => {
  test('DOC 1 — liens CGU/Privacy/IFU sur /login (public)', async ({ page }) => {
    await page.goto('/login', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1_500);
    await shot(page, 'doc-links-login');

    const links = await page.evaluate(() => {
      const allLinks = Array.from(document.querySelectorAll('a'));
      return allLinks.map((a: any) => ({
        text: (a.innerText || '').trim().slice(0, 120),
        href: a.getAttribute('href') || '',
        ariaLabel: a.getAttribute('aria-label') || '',
      })).filter((l: any) => l.text || l.href);
    });

    function findLinks(re: RegExp) {
      return links.filter((l: any) => re.test(l.text + ' ' + l.href + ' ' + l.ariaLabel));
    }

    const docPresence = {
      tou:           findLinks(/\bterms\b|conditions g[eé]n[eé]rales|\bcgu\b|\btou\b|terms.{0,10}use|terms.{0,10}service/i),
      privacy:       findLinks(/privacy|confidentialit[eé]|\brgpd\b|\bgdpr\b|donn[eé]es personnelles/i),
      cookies:       findLinks(/cookies?/i),
      ifu:           findLinks(/instructions for use|notice|manuel|user manual|ifu/i),
      legal_notice:  findLinks(/legal|mentions l[eé]gales|impressum/i),
    };
    dump('doc-links-login', { docPresence, allLinks: links.slice(0, 50) });
  });

  test('DOC 1 — liens accessibles post-login', async ({ page }) => {
    const auth = await loginAsHcp(page);
    if (!auth.ok) { test.fail(true, `auth failed: ${auth.reason}`); return; }
    await page.waitForTimeout(1_500);
    await shot(page, 'doc-links-post-login');

    const links = await page.evaluate(() => {
      const allLinks = Array.from(document.querySelectorAll('a, footer a, [class*="footer"] a'));
      return allLinks.map((a: any) => ({
        text: (a.innerText || '').trim().slice(0, 120),
        href: a.getAttribute('href') || '',
        inFooter: !!(a.closest('footer') || (a.closest('[class*="footer"]'))),
      })).filter((l: any) => l.text || l.href);
    });

    function findLinks(re: RegExp) {
      return links.filter((l: any) => re.test(l.text + ' ' + l.href));
    }

    const docPresence = {
      tou:      findLinks(/\bterms\b|conditions g[eé]n[eé]rales|\bcgu\b|\btou\b/i),
      privacy:  findLinks(/privacy|confidentialit[eé]|\brgpd\b|\bgdpr\b/i),
      cookies:  findLinks(/cookies?/i),
      ifu:      findLinks(/instructions for use|notice d.utilisation|manuel|user manual|\bifu\b/i),
      legal:    findLinks(/legal|mentions l[eé]gales|impressum/i),
    };
    dump('doc-links-post-login', { docPresence, allLinksCount: links.length, footerLinksCount: links.filter((l: any) => l.inFooter).length });

    // Tester l'accès à l'IFU si trouvée
    if (docPresence.ifu.length > 0) {
      try {
        const ifuLink = page.locator(`a:has-text("${docPresence.ifu[0].text}")`).first();
        await ifuLink.click({ timeout: 3_000 });
        await page.waitForTimeout(3_000);
        await shot(page, 'doc-ifu-target');
        dump('doc-ifu-target-state', {
          url: page.url(),
          title: await page.title(),
          isPdf: page.url().endsWith('.pdf') || (await page.locator('embed[type="application/pdf"], iframe[src*=".pdf"]').count()) > 0,
        });
      } catch (_) {}
    }

    // Vérifier la présence d'une version + date d'effet dans le contenu CGU
    if (docPresence.tou.length > 0) {
      try {
        await page.goto(docPresence.tou[0].href, { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1_500);
        const text = (await page.locator('body').innerText()).slice(0, 6000);
        const version_marker = /version\s+[\d\.]+|v\d+\.\d+|edition.+\d{4}|date d.effet|effective date|last updated/i.test(text);
        dump('doc-tou-version-marker', { url: page.url(), version_marker, snippet: text.slice(0, 1500) });
      } catch (_) {}
    }
  });
});
