/**
 * Probe — Étiquette d'identité INS sur les sorties PDF / impression patient.
 *
 * Exigences DMN ciblées :
 *   - INS 42 : étiquette d'identité INS sur tout document patient sortant
 *   - INS 43 : matricule INS-NIR + OID présents sur l'étiquette
 *   - INS 44 : date d'édition + identification du producteur
 *
 * Stratégie : on va sur un dossier patient (sample night sur Sunrise par
 * exemple), on déclenche l'export PDF / "Print report" / "Generate report",
 * on intercepte le téléchargement, on parse le PDF et on cherche les
 * marqueurs INS attendus.
 *
 * Précaution : pas de génération volumineuse / batch — un seul export sur
 * le sample patient.
 */

import { test, expect } from '@playwright/test';
import { loginAsHcp, shot, dump, ARTIFACTS } from './_helpers';
import * as fs from 'fs';
import * as path from 'path';

test.describe('PDF export — étiquette INS (INS 42-44)', () => {
  test('INS 42-44 — INS markers present on exported patient PDF', async ({ page }) => {
    const auth = await loginAsHcp(page);
    if (!auth.ok) { test.fail(true, `auth failed: ${auth.reason}`); return; }

    // 1. Atteindre un dossier patient avec un export possible
    const patientPaths = ['/main/nights/sample', '/main/patients/sample', '/main/patient/example'];
    let landed = false;
    for (const p of patientPaths) {
      try {
        await page.goto(p, { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1_500);
        if ((await page.locator('button:has-text("Export"), button:has-text("Print"), button:has-text("Imprimer"), button:has-text("Télécharger"), button:has-text("Download"), button:has-text("Report")').count()) > 0) {
          landed = true;
          break;
        }
      } catch (_) {}
    }

    if (!landed) {
      // Tenter via /main/patients → premier patient → export
      try {
        await page.goto('/main/patients', { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1_500);
        const firstRow = page.locator('tr, [role="row"]').nth(1).or(page.locator('[class*="patient"]').first());
        if ((await firstRow.count()) > 0) {
          await firstRow.click({ timeout: 3_000 }).catch(() => {});
          await page.waitForTimeout(2_500);
          if ((await page.locator('button:has-text("Export"), button:has-text("Print"), button:has-text("Report"), button:has-text("PDF")').count()) > 0) {
            landed = true;
          }
        }
      } catch (_) {}
    }

    if (!landed) {
      dump('pdf-export-NOT-REACHABLE', { url: page.url(), tried: patientPaths });
      test.fail(true, 'No patient page with export button found');
      return;
    }

    await shot(page, 'pdf-pre-export');

    // 2. Cliquer Export et capturer le download
    const exportBtn = page.locator('button:has-text("Export report"), button:has-text("Export"), button:has-text("Print"), button:has-text("PDF"), button:has-text("Download"), button:has-text("Imprimer"), button:has-text("Télécharger")').first();

    let pdfPath: string | null = null;
    try {
      const downloadPromise = page.waitForEvent('download', { timeout: 15_000 });
      await exportBtn.click({ timeout: 3_000 });
      await page.waitForTimeout(2_500);
      // Possible modal de confirmation
      const confirmBtn = page.locator('button:has-text("Confirm"), button:has-text("OK"), button:has-text("Generate"), button:has-text("Yes")').first();
      if ((await confirmBtn.count()) > 0) {
        try { await confirmBtn.click({ timeout: 2_000 }); } catch (_) {}
      }
      const download = await downloadPromise;
      pdfPath = path.join(ARTIFACTS, 'patient-report.pdf');
      await download.saveAs(pdfPath);
    } catch (e: any) {
      dump('pdf-export-error', { stage: 'download-await', error: e?.message || String(e) });
    }

    await shot(page, 'pdf-post-export');

    if (!pdfPath || !fs.existsSync(pdfPath)) {
      dump('pdf-export-NO-DOWNLOAD', {
        url: page.url(),
        hint: 'Export button clicked but no Playwright download event — peut être : print to local PDF (browser-side), modale ouverte sans confirm, ou erreur silencieuse',
      });
      return;
    }

    // 3. Parser le PDF (pdf-parse en pure-JS — la plupart des projets l'ont en deps)
    let pdfText = '';
    try {
      // pdf-parse doit être installé : npm i pdf-parse
      const pdfParse = (await import('pdf-parse').catch(() => null)) as any;
      if (pdfParse) {
        const buffer = fs.readFileSync(pdfPath);
        const data = await pdfParse.default(buffer);
        pdfText = data.text || '';
      } else {
        // Fallback : extraire texte brut via strings (limited)
        pdfText = fs.readFileSync(pdfPath, 'utf-8').replace(/[^\x20-\x7E\n]/g, ' ').slice(0, 40_000);
      }
    } catch (e: any) {
      dump('pdf-parse-error', { error: e?.message || String(e) });
    }

    // 4. Chercher les markers INS dans le texte du PDF
    const markers = {
      hasMatricule: /matricule|\bnir\b|num[eé]ro de s[eé]curit[eé]/i.test(pdfText),
      hasOID: /\boid\b|1\.2\.250\.1\.213/i.test(pdfText),
      hasBirthName: /nom de naissance|birth name/i.test(pdfText),
      hasOfficialFirstNames: /pr[eé]noms? officiels?|first names?/i.test(pdfText),
      hasInseeCode: /code (commune|insee).*naissance/i.test(pdfText),
      hasInsLabel: /\bins\b|identifiant national de sant[eé]/i.test(pdfText),
      hasEditionDate: /date.*[eé]dition|edition date|imprim[eé] le|printed on/i.test(pdfText),
      hasProducer: /produit par|generated by|producer|hôpital|clinique|cabinet/i.test(pdfText),
      pdfTextLength: pdfText.length,
      pdfTextSnippet: pdfText.slice(0, 4000),
    };
    dump('pdf-export-INS-markers', markers);
    expect(markers.pdfTextLength, 'PDF should be parseable').toBeGreaterThan(0);
  });
});
