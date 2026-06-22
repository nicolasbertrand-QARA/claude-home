import base64, json, subprocess
import email.mime.text, email.mime.multipart

DATE_LABEL = "19 June 2026"
PERIOD = "12 - 19 June 2026"

# ---------- Brand tokens ----------
NAVY = "#1c2837"
NAVY2 = "#213045"
ORANGE = "#ff512c"
ORANGE2 = "#e8850c"
RED = "#d83a2c"
GREY_L = "#e9ebee"
GREY_LL = "#f3f3f3"
FONT = "'Poppins', Arial, Helvetica, sans-serif"

def tag(text, bg, fg="#ffffff"):
    return (f'<span style="display:inline-block;background:{bg};color:{fg};'
            f'font-size:10px;font-weight:700;letter-spacing:.5px;text-transform:uppercase;'
            f'padding:3px 8px;border-radius:6px;margin-right:6px;white-space:nowrap;">{text}</span>')

def src(label, url):
    return (f'<a href="{url}" style="color:#6b7785;font-size:11px;text-decoration:underline;">'
            f'{label}</a>')

def section_badge(num, title):
    return (f'<table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 18px 0;"><tr>'
            f'<td style="background:{NAVY};color:#ffffff;font-family:{FONT};font-size:13px;font-weight:700;'
            f'padding:8px 16px;border-radius:10px;letter-spacing:.5px;">'
            f'<span style="color:{ORANGE};">SECTION {num}</span>&nbsp;&nbsp;{title}</td></tr></table>')

def opinion(text):
    return (f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
            f'style="background:{GREY_LL};border-radius:14px;border-left:4px solid {ORANGE};margin:14px 0 26px 0;">'
            f'<tr><td style="padding:16px 18px;">'
            f'<div style="font-family:{FONT};font-size:10px;font-weight:700;color:{ORANGE};letter-spacing:1px;'
            f'text-transform:uppercase;margin-bottom:6px;">Opinion &mdash; what it means for MDSW manufacturers</div>'
            f'<div style="font-family:{FONT};font-size:13px;color:#33414f;line-height:1.55;">{text}</div>'
            f'</td></tr></table>').replace("&mdash;", ":")

def highlight_card(title, body, srclabel=None, srcurl=None):
    s = f'<div style="margin-top:8px;">{src(srclabel, srcurl)}</div>' if srcurl else ""
    return (f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
            f'style="background:linear-gradient(135deg,{NAVY} 0%,{NAVY2} 100%);border-radius:16px;'
            f'margin:0 0 14px 0;box-shadow:0 4px 14px rgba(28,40,55,.18);">'
            f'<tr><td style="padding:18px 20px;">'
            f'<div style="font-family:{FONT};font-size:15px;font-weight:700;color:#ffffff;margin-bottom:6px;">'
            f'<span style="color:{ORANGE};">&#9656;</span> {title}</div>'
            f'<div style="font-family:{FONT};font-size:13px;color:#c9d2dc;line-height:1.55;">{body}</div>'
            f'{s}</td></tr></table>')

def item(tags_html, title, body, srclabel=None, srcurl=None):
    s = f'<div style="margin-top:4px;">{src(srclabel, srcurl)}</div>' if srcurl else ""
    return (f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
            f'style="border:1px solid {GREY_L};border-radius:12px;margin:0 0 10px 0;background:#ffffff;">'
            f'<tr><td style="padding:14px 16px;">'
            f'<div style="margin-bottom:6px;">{tags_html}</div>'
            f'<div style="font-family:{FONT};font-size:14px;font-weight:600;color:{NAVY};margin-bottom:4px;">{title}</div>'
            f'<div style="font-family:{FONT};font-size:13px;color:#465563;line-height:1.55;">{body}</div>'
            f'{s}</td></tr></table>')

# status tag shortcuts
T_NEW = tag("New", ORANGE)
T_INFORCE = tag("In Force", "#1f7a4d")
T_PROGRESS = tag("In Progress", ORANGE2)
T_DRAFT = tag("Draft", "#5a6b7a")
T_PROPOSED = tag("Proposed", "#5a6b7a")
T_FINAL = tag("Final", "#1f7a4d")
T_OVERDUE = tag("Overdue", RED)

# ---------- Build sections ----------

# Priority banner items
priority_rows = ""
for prio, pbg, txt, deadline in [
    ("Critical", ORANGE, "EUDAMED: first four modules now mandatory (Actor Reg., UDI/Device, NB & Certificates, Market Surveillance). Backfill existing devices.", "Compliance deadline 27 Nov 2026"),
    ("High", ORANGE2, "EU REP symbol transition: EN ISO 15223-1:2021/A1:2025 + MDCG 2021-5 Rev.1 Appendix cited in OJEU (17 Jun). Log in labelling change control.", "Transition to 15 Jun 2031 (MDR)"),
    ("High", ORANGE2, "SS(C)P management in EUDAMED position paper (18 Jun): Class III / implantable / IVD C-D re-check upload workflow.", "Action now"),
    ("High", ORANGE2, "HDS v2.0 mandatory since 16 May 2026: audit cloud sub-processors and contracts for ISO 27001:2022 + EEA storage clauses.", "Deadline passed, verify now"),
    ("Medium", "#5a6b7a", "MHRA pre-market reg consultation closed 19 Jun; UK DUAA 2025 mandatory complaints process in force from 19 Jun.", "Now in force"),
]:
    priority_rows += (
        f'<tr><td style="padding:9px 0;border-bottom:1px solid #2c3c4d;vertical-align:top;width:84px;">'
        f'{tag(prio, pbg)}</td>'
        f'<td style="padding:9px 8px;border-bottom:1px solid #2c3c4d;font-family:{FONT};font-size:12.5px;'
        f'color:#dfe6ee;line-height:1.5;">{txt}'
        f'<div style="color:{ORANGE};font-size:11px;font-weight:600;margin-top:3px;">{deadline}</div></td></tr>')

priority_banner = (
    f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
    f'style="background:{NAVY};border-radius:16px;border-left:6px solid {ORANGE};margin:0 0 30px 0;">'
    f'<tr><td style="padding:18px 22px;">'
    f'<div style="font-family:{FONT};font-size:14px;font-weight:700;color:#ffffff;letter-spacing:.5px;margin-bottom:8px;">'
    f'&#9888;&nbsp; PRIORITY ACTIONS THIS WEEK</div>'
    f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0">{priority_rows}</table>'
    f'</td></tr></table>')

# ----- SECTION 1: EU & International -----
s1 = section_badge(1, "EU &amp; International")

s1 += highlight_card(
    "EUDAMED milestone: mandatory use of first four modules underway",
    "Commission Decision (EU) 2025/2371 made Actor Registration, UDI/Device Registration, Notified Bodies &amp; Certificates and Market Surveillance mandatory from 28 May 2026. Final compliance deadline for existing devices is 27 November 2026. This is the driver behind this week&apos;s SS(C)P position paper.",
    "MedTech Europe", "https://www.medtecheurope.org/2026/06/04/eudamed-reaches-a-major-milestone-mandatory-use-of-the-first-four-modules-begins/")

s1 += highlight_card(
    "IEC 62304 Edition 2 still on track for August 2026",
    "No new ballot this week, but the roadmap item stands: Ed.2 replaces safety Classes A/B/C with two rigour levels, broadens scope to all health software and adds an AI/ML development lifecycle. Begin gap-mapping your software lifecycle SOP now; do not wait for publication.",
    "MedDeviceGuide", "https://meddeviceguide.com/blog/iec-62304-edition-2-2026-software-lifecycle-standard-update-guide")

s1 += '<div style="font-family:'+FONT+';font-size:12px;font-weight:700;color:'+NAVY+';margin:18px 0 8px;text-transform:uppercase;letter-spacing:.5px;">Newly issued / in force</div>'

s1 += item(T_INFORCE,
    "Commission Implementing Decision (EU) 2026/1231 &mdash; harmonised standards".replace("&mdash;",":"),
    "New / updated harmonised standards added under MDR conferring presumption of conformity (announced on EC page 17 Jun). Read the OJEU list and refresh your GSPR-to-standard conformity mapping.",
    "EC New Regulations", "https://health.ec.europa.eu/medical-devices-sector/new-regulations_en")

s1 += item(T_INFORCE + tag("Labelling", "#5a6b7a"),
    "EC REP &rarr; EU REP symbol transition (EN ISO 15223-1:2021/A1:2025)",
    "OJEU reference to the amendment plus MDCG 2021-5 Rev.1 Appendix formalise the editorial change of the authorised-representative symbol. Purely editorial (no change to AR role). Transition deadlines 15 Jun 2031 (MDR) and 17 Jun 2031 (IVDR).",
    "MedEnvoy / EC", "https://medenvoyglobal.com/blog/mdcg-issues-guidance-on-transition-from-ec-rep-to-eu-rep-symbol-on-medical-device-labeling/")

s1 += item(T_NEW,
    "Position Paper: management of SS(C)P in EUDAMED after mandatory use (18 Jun)",
    "EC paper on handling the Summary of Safety and (Clinical) Performance now the first modules are mandatory. Relevant to Class III / implantable and IVD Class C/D. Note: the aggregator label &quot;MDCG 2026-4&quot; is unconfirmed on the EC page; do not cite the number until verified.",
    "EC New Regulations", "https://health.ec.europa.eu/medical-devices-sector/new-regulations_en")

s1 += item(T_NEW,
    "MIR 7.3.1 PMSV reporting form update (11 Jun)",
    "Manufacturer Incident Report form 7.3.1 received XSD/XSL updates for field 4.3.3.d. Operationally relevant for vigilance reporting pipelines.",
    "EC New Regulations", "https://health.ec.europa.eu/medical-devices-sector/new-regulations_en")

s1 += '<div style="font-family:'+FONT+';font-size:12px;font-weight:700;color:'+NAVY+';margin:18px 0 8px;text-transform:uppercase;letter-spacing:.5px;">AI Act &amp; standards</div>'

s1 += item(T_PROGRESS,
    "Digital Omnibus on AI &mdash; provisional agreement moving to adoption".replace("&mdash;",":"),
    "Trilogue provisional agreement (7 May 2026) defers high-risk obligations: Annex I product-regulated HRAIS (incl. medical devices) from 2 Aug 2027 to 2 Aug 2028; Annex III use-based from 2 Aug 2026 to 2 Dec 2027. Final approval anticipated June, publication expected July 2026. Re-check next week.",
    "Gibson Dunn", "https://www.gibsondunn.com/eu-ai-act-omnibus-agreement-postponed-high-risk-deadlines-and-other-key-changes/")

s1 += item(T_OVERDUE,
    "AI Act Article 6 high-risk classification guidelines still missing",
    "The Commission missed its 2 Feb 2026 deadline; no final classification guidance published this week. Keeps AI-SaMD classification under MDR Rule 11 the operative reference for now.",
    "RAPS", "https://www.raps.org/resource/eu-commission-drafts-guidelines-on-classifying-high-risk-systems-under-the-ai-act.html")

s1 += item(T_INFORCE,
    "ISO 14155:2026 (Edition 4) &mdash; in force, no transition".replace("&mdash;",":"),
    "Published 23 Mar 2026, applies immediately to new clinical investigations. Adds mandatory risk-management integration, formal Clinical Events / Data Monitoring Committees and an estimand framework. Relevant where MDSW requires a clinical investigation.",
    "ISO", "https://www.iso.org/standard/83968.html")

s1 += item(T_DRAFT,
    "prEN 18286 (AI Act QMS harmonised standard) &mdash; still in the pipeline".replace("&mdash;",":"),
    "CEN/CENELEC JTC 21 public enquiry ran 30 Oct 2025 to 22 Jan 2026; AI Act harmonised standards delivery slipped to end-2026 at the earliest. Treat as draft, not yet in the OJEU. (No discrete &quot;failed vote&quot; could be substantiated from primary sources.)",
    "CMS Law-Now", "https://cms-lawnow.com/en/ealerts/2025/12/the-first-draft-ai-act-standard-for-public-consultation-what-pren-18286")

s1 += '<div style="font-family:'+FONT+';font-size:12px;font-weight:700;color:'+NAVY+';margin:18px 0 8px;text-transform:uppercase;letter-spacing:.5px;">IMDRF &amp; cybersecurity</div>'

s1 += item(T_NEW,
    "IMDRF adverse-event terminology 2026 update (~5 Jun)",
    "IMDRF published its 2026 update to adverse-event / incident coding terminology. Affects vigilance coding. Just outside the strict window but the freshest IMDRF item.",
    "DM-Experts", "https://www.dm-experts.fr/flash-reglementaire-normatif/")

s1 += item(T_NEW,
    "Cyber Resilience Act &mdash; conformity-assessment-body designation procedures (11 Jun)".replace("&mdash;",":"),
    "Procedures for designation/notification of CABs under the CRA published. MDR/IVDR devices are exempt from CRA product requirements, but indirect effects apply (SBOMs, coordinated vulnerability disclosure from 11 Sep 2026, NIS2 essential-entity duties on healthcare). Main CRA obligations from 11 Dec 2027.",
    "Forescout", "https://www.forescout.com/blog/what-nis2-and-the-cyber-resilience-act-mean-for-cps-ot-asset-owners/")

s1 += '<div style="font-family:'+FONT+';font-size:12px;font-weight:700;color:'+NAVY+';margin:18px 0 8px;text-transform:uppercase;letter-spacing:.5px;">France-specific</div>'

s1 += item(T_INFORCE,
    "HDS v2.0 mandatory since 16 May 2026",
    "Only hosts certified to HDS referential v2.0 (aligned to ISO/IEC 27001:2022) may legally host third-party health data; no derogation. Underpinned by Decret 2026-209 of 24 Mar 2026 (EEA storage limitation, transfer transparency, electronic archiving). The live task is verifying your cloud sub-processors&apos; certification and contracts.",
    "economie.gouv.fr", "https://presse.economie.gouv.fr/nouvelle-version-du-referentiel-de-certification-hds/")

s1 += item(T_INFORCE,
    "CNIL MR-001 / MR-003 updated reference methodologies",
    "CNIL updated and widened the scope of reference methodologies MR-001 and MR-003 for health research; requirements apply to research initiated from 23 May 2026. A consolidated DPI guidance is planned for 2026.",
    "CNIL", "https://www.cnil.fr/fr/recherche-en-sante-la-cnil-met-jour-et-elargit-le-champ-des-methodologies-de-reference-001-et-003")

s1 += opinion(
    "The centre of gravity this week is EUDAMED operationalisation, not new text. With the first four modules mandatory and a 27 Nov 2026 backfill deadline, every Class IIa+ manufacturer should confirm Actor and UDI/Device registrations are complete and, for Class III / implantable / IVD C-D, that the SS(C)P upload route works. On standards, two roadmap items dominate planning: IEC 62304 Ed.2 (Aug 2026) and the deferred AI Act high-risk dates (now 2 Aug 2028 for medical-device AI under the Digital Omnibus). The deferral buys time but does not remove the obligation: keep building Article 9/10/17 evidence in parallel with your MDR technical documentation, because prEN 18286 (the QMS harmonised standard) will not be available before end-2026. For French-market SaaS, HDS v2.0 is now a hard gate: a non-certified or v1.x sub-processor is a Category A finding.")

# ----- SECTION 2: UK -----
s2 = section_badge(2, "United Kingdom")
s2 += highlight_card(
    "MHRA AI Airlock Phase 2 report published; Phase 3 funded to 2029",
    "MHRA published its AI Airlock Phase 2 report (9 Jun) with seven AI technologies and five insights, notably that human oversight cannot be treated as static across the lifecycle and that performance metrics must stay clinically meaningful. Phase 3 is funded at &pound;1.2m/year (2026-2029) to feed the forthcoming AIaMD framework.",
    "MHRA medregs blog", "https://medregs.blog.gov.uk/2026/06/09/advancing-ai-regulation-in-healthcare-insights-from-ai-airlock-phase-2/")

s2 += item(T_PROGRESS,
    "Draft Medical Devices (Amendment) Regulations 2026 &mdash; consultation closed 19 Jun".replace("&mdash;",":"),
    "MHRA pre-market reform: international reliance routes, strengthened SaMD/IVD requirements, mandatory UDI and implant cards, IVD risk-based classification. Expected adoption Dec 2026, entry into force Jun 2027. PCCP/SaMD specifics are reported from secondary coverage; verify against the WTO-notified text.",
    "gov.uk", "https://www.gov.uk/government/news/mhra-invites-views-on-proposed-changes-to-medical-device-regulation")

s2 += item(T_INFORCE,
    "Data (Use and Access) Act 2025 &mdash; mandatory complaints process from 19 Jun".replace("&mdash;",":"),
    "Final tranche commenced: controllers must offer a clear complaints route, acknowledge within 30 days and investigate without undue delay. No small-business exemption; directly relevant to health-data SaMD operators.",
    "ICO", "https://ico.org.uk/about-the-ico/what-we-do/legislation-we-cover/data-use-and-access-act-2025/")

s2 += item(T_NEW,
    "New AI/medicines regulatory sandboxes announced (London Tech Week, 9 Jun)",
    "MHRA announced an AI sandbox for medicines safety (up to five approaches in phase 1, starting summer 2026), distinct from the AI Airlock, plus a live-NHS-setting AIaMD strand with NHS England.",
    "gov.uk", "https://www.gov.uk/government/news/mhra-launches-ai-sandbox-to-accelerate-medicines-development-and-improve-safety")

s2 += item(T_PROPOSED,
    "UK AI regulation: no standalone AI Act; sandboxing via &quot;Regulating for Growth&quot; Bill",
    "The UK keeps a sectoral approach. The Regulating for Growth Bill (King&apos;s Speech, 13 May 2026) channels AI support through cross-economy sandboxing powers rather than an AI Act. No change in window.",
    "Parliament", "https://bills.parliament.uk/bills/3942")

s2 += opinion(
    "For clients selling into Great Britain, the Medical Devices (Amendment) Regulations 2026 is the file to watch: an international reliance route could materially shorten time-to-GB-market for devices already cleared in the US/Canada/Australia, but it yields a Certificate of International Reliance, not a UKCA mark. Build your regulatory strategy assuming a Jun 2027 entry into force. On AI, the MHRA continues to favour sandboxes and guidance over statute; the Airlock Phase 2 insight that human oversight is not static is worth importing directly into your IEC 62366-1 use-related risk analysis and your post-market performance monitoring plan. The DUAA complaints duty is live now: confirm your privacy operations actually meet the 30-day acknowledgement requirement.")

# ----- SECTION 3: US -----
s3 = section_badge(3, "United States (FDA / HIPAA)")

s3 += (f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>'
       f'<td width="49%" valign="top">'
       + highlight_card(
           "FDA signals AI + RWE convergence at DIA (17 Jun)",
           "FDA officials called AI and real-world evidence &quot;complementary tools&quot; and reported &gt;1,000 submissions with AI elements since 2016, concentrated in oncology. Industry asked for concrete use-case examples to accompany the pending AI-in-regulatory-decision-making draft. Signalling, not a published guidance.",
           "RAPS", "https://www.raps.org/resource/dia-fda-officials-discuss-trends-in-ai-rwe-in-submissions.html")
       + '</td><td width="2%"></td><td width="49%" valign="top">'
       + highlight_card(
           "HIPAA Security Rule NPRM: still not finalised",
           "The overhaul (mandatory encryption, MFA, 72h restoration, annual pen-testing, asset inventories) remains a proposal. The May 2026 target has slipped with no new date; 100+ hospital systems have asked OCR to withdraw. The 240-day compliance clock starts only on final publication, so no deadline is yet running.",
           "HHS", "https://www.hhs.gov/hipaa/for-professionals/security/hipaa-security-rule-nprm/factsheet/index.html")
       + '</td></tr></table>')

s3 += item(T_FINAL,
    "FDA real-world evidence guidance extended to CDRH/devices (3 Jun)",
    "FDA broadened its RWE guidance examples to explicitly cover devices, pairing with its earlier 2026 move to remove a barrier to RWE in application reviews. Just outside the window but the most recent FDA device-relevant action.",
    "FDA", "https://www.fda.gov/news-events/press-announcements/fda-eliminates-major-barrier-using-real-world-evidence-drug-and-device-application-reviews")

s3 += item(T_INFORCE,
    "QMSR in force since 2 Feb 2026 (context)",
    "21 CFR 820 now incorporates ISO 13485:2016 by reference; inspection program 7382.850 is in use. Internal audits and management reviews are now inspectable. Confirm your QMS documentation maps cleanly to the harmonised structure.",
    "FDA Digital Health", "https://www.fda.gov/medical-devices/digital-health-center-excellence")

s3 += item(T_FINAL,
    "CDS / General Wellness final guidance (6 Jan 2026, context)",
    "Loosens oversight of low-risk clinical decision support, wellness and wearables; high-risk diagnose/treat functions stay regulated. Re-confirm your intended-use statements still place your product on the regulated side where you rely on device claims.",
    "FDA Digital Health", "https://www.fda.gov/medical-devices/digital-health-center-excellence")

s3 += opinion(
    "A quiet week for binding US action, which is itself useful intelligence: the AI TPLC draft (Jan 2025) and PCCP final (Dec 2024) remain the operative references, and FDA continues to push examples rather than finalise. If you maintain a PCCP, keep aligning it with the EU approach (ACP under the Digital Omnibus) and flag the divergences for clients running dual submissions. On HIPAA, hold steady: do not start a remediation programme against the NPRM&apos;s encryption/MFA/pen-test requirements as if they were binding, but do treat them as a credible direction of travel and a low-regret security baseline. The QMSR transition is the one fully in-force item: a US-facing client whose QMS still references the old QSR terminology has an open gap.")

# ----- SECTION 4: Other regions -----
s4 = section_badge(4, "Other Regions")
s4 += highlight_card(
    "International / IMDRF most active: AI best-practices draft consultation closed 10 Jun",
    "IMDRF&apos;s draft framework harmonising best practices to mitigate AI-enabled medical device risks across the lifecycle (building on 2025 GMLP) closed public comment on 10 Jun. Dispositions head to the IMDRF Management Committee, 14-18 Sep 2026, Singapore. This is the document most likely to shape converged AI/ML expectations globally.",
    "RAPS", "https://www.raps.org/resource/imdrf-drafts-framework-on-best-practices-for-using-ai-in-medical-devices.html")

flag_card = lambda flag, country, tags_html, title, body, srclabel, srcurl: (
    f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
    f'style="border:1px solid {GREY_L};border-radius:12px;margin:0 0 10px 0;background:#ffffff;">'
    f'<tr><td style="padding:14px 16px;">'
    f'<div style="font-family:{FONT};font-size:12px;font-weight:700;color:{ORANGE};letter-spacing:.5px;margin-bottom:6px;">'
    f'{flag}&nbsp;&nbsp;{country}</div>'
    f'<div style="margin-bottom:6px;">{tags_html}</div>'
    f'<div style="font-family:{FONT};font-size:14px;font-weight:600;color:{NAVY};margin-bottom:4px;">{title}</div>'
    f'<div style="font-family:{FONT};font-size:13px;color:#465563;line-height:1.55;">{body}</div>'
    f'<div style="margin-top:4px;">{src(srclabel, srcurl)}</div>'
    f'</td></tr></table>')

s4 += flag_card("&#127462;&#127482;", "Australia (TGA)", T_PROGRESS,
    "PCCP draft guidance consultation closed 5 Jun",
    "Draft guidance for Predetermined Change Control Plans lets AI/software devices be modified post-market without a full new submission. Comment window closed 5 Jun; finalisation to follow. A parallel Conformity Assessment Procedures consultation is open.",
    "Medical Republic", "https://www.medicalrepublic.com.au/tga-giving-ai-updates-a-longer-leash/125029")

s4 += flag_card("&#127464;&#127462;", "Canada (Health Canada)", T_INFORCE,
    "Pre-market guidance for ML-enabled medical devices in force",
    "Published 1 Apr 2026: lifecycle expectations for MLMDs (data quality, training/validation, bias, performance monitoring, transparency) plus a PCCP mechanism. Companion post-market monitoring guidance published 9 Apr. No new activity this week.",
    "Health Canada", "https://www.canada.ca/en/health-canada/services/drugs-health-products/medical-devices/application-information/guidance-documents/pre-market-guidance-machine-learning-enabled-medical-devices.html")

s4 += flag_card("&#127480;&#127468;", "Singapore (HSA)", T_INFORCE,
    "AIHGle 2.0 and AI-SaMD risk-classification tool live (context)",
    "Refreshed AI in Healthcare Guidelines (10 Mar 2026) strengthen accountability, transparency and deployment risk mitigation; a beta AI risk-classification tool went live 30 Apr. Singapore is the first country at WHO&apos;s highest medical-device regulation classification. No new instrument this week.",
    "Baker McKenzie", "https://www.bakermckenzie.com/en/insight/publications/2026/03/singapore-moh-and-hsa-launch-refreshed-ai-in-healthcare-guidelines")

s4 += flag_card("&#127472;&#127479;", "South Korea (MFDS)", T_INFORCE,
    "Digital Medical Products Act (DMPA) fuller effect from Jan 2026",
    "DMPA reached fuller effect 24 Jan 2026 (new labelling for digital medical device software; revised classification regulations). Permits pre-approved change-management plans for algorithm updates within set parameters; safety-significant changes still require review. No new activity this week.",
    "Emergo by UL", "https://www.emergobyul.com/news/south-koreas-digital-medical-products-act-now-enforced")

s4 += flag_card("&#127480;&#127462;", "Saudi Arabia (SFDA)", T_PROGRESS,
    "SaMD &amp; AI risk-management workshop scheduled 30 Jun 2026",
    "SFDA&apos;s AI/Big Data guidance and MDS-G27 (digital health products) stand; the near-term actionable item is the 30 Jun workshop on risk management for SaMD and AI-enabled devices. SFDA-AAMI AI best-practices work continues.",
    "Al Tamimi", "https://www.tamimi.com/law-update-articles/new-guidance-for-ai-and-big-data-medical-devices-in-saudi-arabia/")

s4 += flag_card("&#127464;&#127475;", "China (NMPA)", T_PROGRESS,
    "2026 Medical Device Industry Standards plan (date unconfirmed)",
    "The 2026 standards plan reinforces ISO harmonisation, AI oversight and stricter technical/preclinical evaluation, with a proposed AI medical device standardisation organisation. Source page returned 403; exact announcement date unconfirmed.",
    "Cisema", "https://cisema.com/en/nmpa-2026-device-standards-plan/")

s4 += flag_card("&#127463;&#127479;", "Brazil (ANVISA / CFM)", T_INFORCE,
    "CFM Resolution 2,454/2026 on AI in medical practice",
    "SaMD remains regulated risk-based under RDC 657/2022. The 2026 development is a medical-council resolution regulating AI on a human-in-the-loop basis: AI as decision-support only, physician retains clinical authority. Exact date not pinned in sources.",
    "Freyr", "https://www.freyrsolutions.com/blog/resolution-for-regulation-of-software-as-medical-device-samd-in-brazil")

s4 += flag_card("&#127482;&#127475;", "WHO", T_NEW,
    "Discussion paper on AI and evidence-informed health policy (2 Jun)",
    "WHO paper on how AI reshapes health policy-making. Core position: AI should augment, not automate; recommends algorithmic impact assessments and multidisciplinary oversight panels. Reinforces the human-oversight theme converging across jurisdictions.",
    "WHO", "https://www.who.int/news/item/02-06-2026-new-who-discussion-paper-sets-out-opportunities-and-risks-of-ai-in-evidence-informed-health-policy")

s4 += opinion(
    "The unmistakable global pattern is convergence on PCCP-style change control for AI/ML devices: the EU (ACP), FDA (PCCP), Health Canada, TGA, Japan (IDATEN) and Korea (DMPA) now all run a variant of &quot;approve how the device is allowed to change, not each change.&quot; For a manufacturer with multi-market ambitions, the efficient strategy is to author one master change-control protocol and map it to each jurisdiction&apos;s template rather than maintain separate regimes. The second pattern is human-oversight-is-not-static (MHRA, WHO, IMDRF): bake lifecycle re-validation of human factors into your post-market plan. Watch the IMDRF AI best-practices framework: once finalised after the Sep 2026 Management Committee, it will become the reference text regulators worldwide cite, so aligning early is low-regret.")

# ----- ANNEX: Standards monitoring -----
annex_rows = ""
annex_data = [
    ("EU 2017/745 (MDR)", "Simplification proposal 2025/0404 in legislative procedure; no movement this week. Next: Parliament/Council 2026.", "watch"),
    ("EU 2024/1689 (AI Act)", "Digital Omnibus provisional agreement (7 May) defers medical-device AI high-risk obligations to 2 Aug 2028. Adoption expected Jun/Jul 2026.", "action"),
    ("EU 2016/679 (GDPR)", "No change. France: CNIL MR-001/MR-003 updated for research from 23 May 2026.", "nochange"),
    ("NF EN 62304/A1 (Software lifecycle)", "Edition 2 still expected August 2026. MAJOR: Classes A/B/C to rigour levels + AI/ML lifecycle. Begin gap-mapping now.", "action"),
    ("NF EN ISO 13485:2016/A11 (QMS)", "No change this week. New edition est. 2028-2029. US: QMSR in force 2 Feb 2026.", "nochange"),
    ("NF EN ISO 14971:2019/A11 (Risk)", "No revision planned. No change this week.", "nochange"),
    ("ISO 14155 (Clinical investigation)", "Edition 4 in force since 23 Mar 2026, no transition. Applies to new investigations immediately.", "action"),
    ("EN ISO 15223-1 (Symbols)", "Amendment A1:2025 cited in OJEU (17 Jun): EC REP to EU REP symbol. Update labelling change control. Deadline 2031.", "action"),
    ("NF EN 62366/A1 (Usability)", "No change. Import MHRA/WHO 'human oversight not static' theme into use-related risk analysis.", "nochange"),
    ("IEC 82304-1 (Health software)", "No change announced this week.", "nochange"),
    ("ISO 27001 / 27701 / 27017 / 27018", "No change this week. HDS v2.0 (mandatory 16 May 2026) aligns to ISO 27001:2022.", "watch"),
    ("ANS HDS v2.0 (health data hosting)", "Mandatory since 16 May 2026. No derogation. Audit cloud sub-processors now.", "action"),
    ("MDCG (SS(C)P / EUDAMED)", "New position paper on SS(C)P in EUDAMED (18 Jun). Aggregator label 'MDCG 2026-4' unconfirmed; verify before citing.", "watch"),
    ("MDCG 2021-5 Rev.1 Appendix", "New appendix on EU REP symbol transition (with EN ISO 15223-1/A1:2025).", "action"),
    ("prEN 18286 (AI Act QMS standard)", "Draft, enquiry closed 22 Jan 2026; hStandards slipped to end-2026 at earliest. Not yet in OJEU.", "watch"),
    ("IMDRF SaMD WG (N12/N81/N88)", "AI best-practices draft consultation closed 10 Jun; dispositions to MC 14-18 Sep 2026. Adverse-event terminology 2026 update issued.", "watch"),
    ("MDCG 2019-6 rev.1 (Cybersecurity)", "No revision this week. CRA CAB designation procedures published 11 Jun (indirect impact).", "watch"),
]
for ref, note, kind in annex_data:
    if kind == "action":
        bg = "#fff1ee"; bar = ORANGE; badge = tag("Action", ORANGE)
    elif kind == "watch":
        bg = "#fff8ee"; bar = ORANGE2; badge = tag("Monitor", ORANGE2)
    else:
        bg = GREY_LL; bar = "#c4ccd4"; badge = tag("No change", "#7a8693")
    annex_rows += (
        f'<tr style="background:{bg};">'
        f'<td style="padding:10px 12px;border-left:3px solid {bar};font-family:{FONT};font-size:12.5px;'
        f'font-weight:600;color:{NAVY};vertical-align:top;width:32%;">{ref}</td>'
        f'<td style="padding:10px 12px;font-family:{FONT};font-size:12px;color:#465563;line-height:1.5;vertical-align:top;">'
        f'{badge}<br><span style="display:inline-block;margin-top:4px;">{note}</span></td></tr>')

annex = (
    section_badge("A", "Standards Monitoring (DOC-POL-XXX v01)")
    + f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
      f'style="border-collapse:collapse;border-radius:12px;overflow:hidden;border:1px solid {GREY_L};">'
      f'<tr style="background:{NAVY};"><td style="padding:10px 12px;font-family:{FONT};font-size:11px;'
      f'font-weight:700;color:#ffffff;text-transform:uppercase;letter-spacing:.5px;">Reference</td>'
      f'<td style="padding:10px 12px;font-family:{FONT};font-size:11px;font-weight:700;color:#ffffff;'
      f'text-transform:uppercase;letter-spacing:.5px;">Status this week</td></tr>'
    + annex_rows + '</table>')

# ----- Header & footer -----
header = (
    f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
    f'style="background:linear-gradient(135deg,{NAVY} 0%,{NAVY2} 60%,#2a3d52 100%);border-radius:18px;'
    f'margin:0 0 26px 0;">'
    f'<tr><td style="padding:34px 30px;">'
    f'<div style="font-family:{FONT};font-size:13px;font-weight:700;color:{ORANGE};letter-spacing:1.5px;'
    f'text-transform:uppercase;">Theodo HealthTech</div>'
    f'<div style="font-family:{FONT};font-size:30px;font-weight:700;color:#ffffff;margin:8px 0 2px;'
    f'letter-spacing:-.5px;">Regulatory Watch</div>'
    f'<div style="font-family:{FONT};font-size:14px;color:#aebac7;font-weight:500;">'
    f'Medical Device Software &amp; AI Act</div>'
    f'<div style="margin-top:16px;"><span style="display:inline-block;background:{ORANGE};color:#ffffff;'
    f'font-family:{FONT};font-size:12px;font-weight:700;padding:6px 14px;border-radius:20px;letter-spacing:.5px;">'
    f'{PERIOD}</span></div>'
    f'</td></tr></table>')

footer = (
    f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
    f'style="background:{NAVY};border-radius:16px;margin:28px 0 0 0;">'
    f'<tr><td style="padding:24px 26px;">'
    f'<div style="font-family:{FONT};font-size:15px;font-weight:700;color:#ffffff;margin-bottom:10px;">'
    f'<span style="color:{ORANGE};">Theodo</span>HealthTech</div>'
    f'<div style="font-family:{FONT};font-size:11px;color:#8a97a5;line-height:1.6;">'
    f'This regulatory watch is an internal awareness briefing for QARA / MDSW teams. It summarises publicly '
    f'available regulatory developments for the period {PERIOD} and does not constitute legal or regulatory '
    f'advice. Always verify clause-level references against the primary source (OJEU, EC, ISO/IEC, MHRA, FDA) '
    f'before relying on them in technical documentation. Aggregator-attributed document numbers flagged as '
    f'unconfirmed must be verified before citation.</div>'
    f'<div style="font-family:{FONT};font-size:11px;color:#6b7785;margin-top:14px;border-top:1px solid #2c3c4d;'
    f'padding-top:12px;">Key sources: '
    f'<a href="https://health.ec.europa.eu/medical-devices-sector/new-regulations_en" style="color:{ORANGE};text-decoration:none;">EC Medical Devices</a> &middot; '
    f'<a href="https://www.qualitiso.com/veille/" style="color:{ORANGE};text-decoration:none;">Qualitiso</a> &middot; '
    f'<a href="https://www.dm-experts.fr/flash-reglementaire-normatif/" style="color:{ORANGE};text-decoration:none;">DM-Experts</a> &middot; '
    f'<a href="https://www.imdrf.org/" style="color:{ORANGE};text-decoration:none;">IMDRF</a> &middot; '
    f'<a href="https://www.gov.uk/government/organisations/medicines-and-healthcare-products-regulatory-agency" style="color:{ORANGE};text-decoration:none;">MHRA</a> &middot; '
    f'<a href="https://www.fda.gov/medical-devices/digital-health-center-excellence" style="color:{ORANGE};text-decoration:none;">FDA Digital Health</a> &middot; '
    f'<a href="https://www.cnil.fr/fr" style="color:{ORANGE};text-decoration:none;">CNIL</a>'
    f'</div></td></tr></table>')

# ----- Assemble -----
html_content = (
    f'<!DOCTYPE html><html><head><meta charset="utf-8">'
    f'<meta name="viewport" content="width=device-width,initial-scale=1.0">'
    f'<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">'
    f'</head><body style="margin:0;padding:0;background:{GREY_L};">'
    f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:{GREY_L};">'
    f'<tr><td align="center" style="padding:24px 12px;">'
    f'<table role="presentation" width="680" cellpadding="0" cellspacing="0" '
    f'style="max-width:680px;width:100%;background:#ffffff;border-radius:20px;padding:22px;'
    f'box-shadow:0 8px 30px rgba(28,40,55,.12);">'
    f'<tr><td>'
    f'{header}{priority_banner}{s1}{s2}{s3}{s4}{annex}{footer}'
    f'</td></tr></table>'
    f'</td></tr></table></body></html>')

# ---------- Plain text ----------
plain_text = f"""REGULATORY WATCH REPORT - Medical Device Software & AI Act
Period: {PERIOD} | Theodo HealthTech

PRIORITY ACTIONS
- CRITICAL: EUDAMED first four modules mandatory (since 28 May 2026); backfill existing devices by 27 Nov 2026.
- HIGH: EU REP symbol transition (EN ISO 15223-1:2021/A1:2025 + MDCG 2021-5 Rev.1 Appendix), cited OJEU 17 Jun. Deadline 2031.
- HIGH: SS(C)P-in-EUDAMED position paper (18 Jun) - Class III / implantable / IVD C-D.
- HIGH: HDS v2.0 mandatory since 16 May 2026 - audit cloud sub-processors now.
- MEDIUM: MHRA pre-market reg consultation closed 19 Jun; UK DUAA 2025 complaints process in force 19 Jun.

SECTION 1 - EU & INTERNATIONAL: EUDAMED operationalisation; Commission Implementing Decision (EU) 2026/1231 harmonised standards (11 Jun); Digital Omnibus defers medical-device AI high-risk to 2 Aug 2028; ISO 14155 Ed.4 in force; IEC 62304 Ed.2 still Aug 2026; prEN 18286 slipped to end-2026; CRA CAB procedures (11 Jun); France HDS v2.0 + CNIL MR-001/003.
SECTION 2 - UK: AI Airlock Phase 2 report + Phase 3 funded; Medical Devices (Amendment) Regs 2026 consultation closed 19 Jun; DUAA complaints duty in force.
SECTION 3 - US: Quiet week. FDA AI+RWE signalling (17 Jun); HIPAA Security Rule NPRM still not final; QMSR in force since 2 Feb 2026.
SECTION 4 - OTHER REGIONS: IMDRF AI best-practices draft closed 10 Jun (most active); TGA PCCP draft closed 5 Jun; Health Canada MLMD guidance in force; global convergence on PCCP-style change control.

ANNEX: Standards monitoring table (MDR, AI Act, IEC 62304 Ed.2, ISO 14155 Ed.4, EN ISO 15223-1/A1:2025, HDS v2.0, prEN 18286, IMDRF).

Full HTML version best viewed in an email client supporting HTML.
--
Theodo HealthTech | Regulatory Watch | Internal awareness briefing, not legal advice.
"""

# ---------- Send ----------
msg = email.mime.multipart.MIMEMultipart('alternative')
msg['To'] = ('nicolas.bertrand@theodo.com, thomas.walter@theodo.com, '
             'clemence.faulcon@theodo.com, manon.thiberge@theodo.com, '
             'louise.balague@theodo.com, pierre.momboisse@theodo.com')
msg['Subject'] = f'Regulatory Watch - Medical Device Software & AI Act - {DATE_LABEL}'
msg['From'] = 'me'
msg.attach(email.mime.text.MIMEText(plain_text, 'plain'))
msg.attach(email.mime.text.MIMEText(html_content, 'html'))

raw = base64.urlsafe_b64encode(msg.as_bytes()).decode('utf-8')
body = json.dumps({"raw": raw})

result = subprocess.run(
    ['gws', 'gmail', 'users', 'messages', 'send',
     '--params', '{"userId": "me"}',
     '--json', body],
    capture_output=True, text=True)
print("STDOUT:", result.stdout[:800])
print("STDERR:", result.stderr[:800])
print("Return code:", result.returncode)

with open('/Users/nicolasbertrand/.claude/regulatory-watch/last_email.html', 'w') as f:
    f.write(html_content)
print("HTML bytes:", len(html_content))
