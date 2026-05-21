/**
 * Probe — Création / saisie identité patient avec traits RNIV (Référentiel
 * National d'Identitovigilance).
 *
 * Exigences DMN ciblées :
 *   - INS 1.1  : 10 traits RNIV stricts présents au formulaire de création
 *                (nom de naissance, liste prénoms, prénom usuel, date naissance,
 *                code lieu naissance INSEE, sexe, NIR / matricule, OID, INS-NIR)
 *   - INS 4.1  : appel téléservice INSi pour qualification (Voie A) — détection
 *                d'un bouton/action "Vérifier l'INS" / "Récupérer l'INS"
 *   - INS 6.1  : statut INS visible (provisoire / récupérée / validée / qualifiée)
 *   - INS 11   : distinction traits stricts (5 obligatoires) vs complémentaires
 *
 * Stratégie : on va sur le formulaire de création de patient (généralement
 * /main/patients/new ou bouton "+ Nouveau patient" / "Add patient"). On
 * scanne tous les inputs/labels et on matche contre les 10 traits RNIV
 * attendus. On dump aussi les statuts INS visibles + boutons INSi.
 *
 * Pas de soumission réelle — on remplit les champs synthétiquement puis on
 * abandon le formulaire (Cancel ou navigation away).
 */

import { test } from '@playwright/test';
import { loginAsHcp, shot, dump, dumpHtml } from './_helpers';

const RNIV_TRAITS_STRICT = [
  // 5 traits stricts obligatoires per Guide INS V3.0 §3.2
  { id: 'nom_naissance',  patterns: [/nom de naissance/i, /birth ?name/i, /family ?name/i, /surname/i] },
  { id: 'prenoms_acte',   patterns: [/pr[eé]noms? officiels?/i, /first ?names?/i, /given ?names?/i] },
  { id: 'date_naissance', patterns: [/date de naissance/i, /birth ?date/i, /date of birth/i] },
  { id: 'sexe',           patterns: [/^sexe$/i, /^sex$/i, /\bgender\b/i] },
  { id: 'lieu_naissance', patterns: [/lieu de naissance|code (commune|insee).*naissance|naissance.*insee/i, /place of birth/i] },
];

const RNIV_TRAITS_COMP = [
  { id: 'prenom_usuel',         patterns: [/pr[eé]nom usuel/i, /^pr[eé]nom$/i, /first ?name(?! list)/i] },
  { id: 'nom_utilise',          patterns: [/nom d.usage|nom utilis[eé]/i, /usual ?name/i] },
  { id: 'matricule_ins_oid',    patterns: [/matricule|\bnir\b|ins ?nir|num[eé]ro de s[eé]curit[eé]/i] },
  { id: 'oid',                  patterns: [/oid|1\.2\.250\.1\.213/i] },
  { id: 'statut_ins',           patterns: [/statut ins|ins[- ]status|qualifi[eé]e?|provisoire|r[eé]cup[eé]r[eé]e?|valid[eé]e?/i] },
];

test.describe('Patient creation — traits RNIV (INS 1, 4, 6, 11)', () => {
  test('INS 1.1 / 11 — 10 traits RNIV présents au formulaire de création', async ({ page }) => {
    const auth = await loginAsHcp(page);
    if (!auth.ok) { test.fail(true, `auth failed: ${auth.reason}`); return; }

    // 1. Naviguer vers /main/patients
    await page.goto('/main/patients', { waitUntil: 'domcontentloaded' }).catch(() => {});
    await page.waitForTimeout(1_500);
    await shot(page, 'patients-list');

    // 2. Cliquer sur "+ Nouveau patient" / "Add patient" / "Create patient"
    const addPatientBtn = page
      .locator('button:has-text("New patient"), button:has-text("Nouveau patient"), button:has-text("Add patient"), button:has-text("Add a patient"), a:has-text("New patient"), a:has-text("Nouveau patient"), button:has-text("+ Patient"), button[aria-label*="add patient" i]')
      .first();

    let formOpened = false;
    if ((await addPatientBtn.count()) > 0) {
      try {
        await addPatientBtn.click({ timeout: 3_000 });
        await page.waitForTimeout(2_000);
        formOpened = true;
      } catch (_) {}
    }

    if (!formOpened) {
      // Tenter une URL directe
      for (const url of ['/main/patients/new', '/main/patients/create', '/patients/new']) {
        try {
          await page.goto(url, { waitUntil: 'domcontentloaded' });
          await page.waitForTimeout(1_500);
          if ((await page.locator('input, select').count()) > 3) {
            formOpened = true;
            break;
          }
        } catch (_) {}
      }
    }

    if (!formOpened) {
      dump('patient-create-form-NOT-FOUND', {
        attempted: ['button new patient', '/main/patients/new', '/main/patients/create'],
        landingUrl: page.url(),
      });
      test.fail(true, 'Patient creation form not reachable from /main/patients');
      return;
    }

    await shot(page, 'patient-create-empty');
    dumpHtml('patient-create-form', await page.content());

    // 3. Scanner tous les inputs + labels
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
          required: el.required ?? null,
          maxLength: el.maxLength ?? null,
          pattern: el.pattern ?? null,
        };
      });
      const buttons = Array.from(document.querySelectorAll('button, a[role="button"]')).map((el: any) => ({
        text: (el.innerText || '').trim().slice(0, 200),
        ariaLabel: el.getAttribute('aria-label'),
      })).filter((b: any) => b.text);
      const allText = ((document.body && document.body.innerText) || '').slice(0, 12000);
      return { inputs, buttons, allText };
    });
    dump('patient-create-form-fields', formData);

    // 4. Matcher les inputs contre les traits RNIV attendus
    function findTrait(patterns: RegExp[]): { matched: boolean; how: string | null } {
      for (const p of patterns) {
        const found = formData.inputs.find((inp: any) => {
          const tags = `${inp.id || ''} ${inp.name || ''} ${inp.placeholder || ''} ${inp.ariaLabel || ''} ${inp.labelText || ''}`;
          return p.test(tags);
        });
        if (found) return { matched: true, how: `${found.id || found.name || found.labelText}` };
      }
      return { matched: false, how: null };
    }

    const traitsCoverage = {
      strict: RNIV_TRAITS_STRICT.map((t) => ({ trait: t.id, ...findTrait(t.patterns) })),
      complementary: RNIV_TRAITS_COMP.map((t) => ({ trait: t.id, ...findTrait(t.patterns) })),
    };
    dump('patient-create-rniv-coverage', traitsCoverage);

    // 5. Détecter le bouton INSi (INS 4.1 — appel téléservice)
    const insiButton = page
      .locator('button:has-text("INSi"), button:has-text("Vérifier l\'INS"), button:has-text("Récupérer"), button:has-text("Verify INS"), button:has-text("Retrieve INS"), button:has-text("INS")')
      .or(page.locator('[aria-label*="INSi" i], [aria-label*="récupérer ins" i]'));
    const insiButtonCount = await insiButton.count();
    dump('patient-create-INSi-button', { count: insiButtonCount, text: 'INS 4.1 — bouton appel INSi attendu si Voie A' });

    // 6. Statut INS visible (INS 6.1)
    const insStatusVisible = /statut ins|ins[- ]status|qualifi[eé]e?|provisoire|r[eé]cup[eé]r[eé]e?|valid[eé]e?/i.test(formData.allText);
    dump('patient-create-INS-status-visible', { visible: insStatusVisible, hint: 'INS 6.1 — visualisation statut qualification' });

    // 7. Capture finale
    await shot(page, 'patient-create-analysis-done');
  });
});
