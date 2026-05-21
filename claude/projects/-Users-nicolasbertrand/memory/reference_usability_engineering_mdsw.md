---
name: Usability Engineering for MDSW — Comprehensive Reference
description: Deep expertise on IEC 62366-1, usability engineering process, NB expectations, formative/summative evaluation, risk integration, SaMD specifics, agile integration, clinical evaluation, post-market — for EU MDSW projects
type: reference
---

# Usability Engineering for Medical Device Software in the EU

## 1. Regulatory Framework

### Primary Standards & Documents
| Document | Role |
|----------|------|
| **IEC 62366-1:2015 + Amd 1:2020** | Core usability engineering process standard (harmonised under MDR) |
| **IEC 62366-2:2016** | Informative guidance (methods, sample sizes in Annex K) |
| **ISO 14971:2019** | Risk management — 6 information flows with usability (Figure A.5 in Amd 1) |
| **ISO 24971:2020** | Guidance on ISO 14971 application, annex references for use-related hazards |
| **IEC 82304-1:2016** | Health software product safety — references IEC 62366-1 informatively |
| **ISO 13485:2016** | QMS — Clause 7 product realization must include usability engineering |
| **EU MDR 2017/745** | Annex I GSPRs: Clauses 5 (ergonomic design), 14.6 (use error risk reduction), 22 (lay user devices) |
| **MDCG 2020-1** | Clinical evaluation of MDSW — usability as technical/clinical performance evidence |
| **MDCG 2019-16 Rev.1** | Cybersecurity — tension between security and usability |
| **MDCG 2022-21** | PSUR guidance — use error trend reporting |

### Key Standards Locations
- IEC 62366-1 FR: `/Users/nicolasbertrand/Documents/Normes/NF EN 62366-1-2015 - FR.pdf`
- IEC 62366-1 Amd 1 EN: `/Users/nicolasbertrand/Documents/Normes/NF EN 62366-1.A1-2020 - EN (1).pdf`
- IEC 82304-1 EN: `/Users/nicolasbertrand/Documents/Normes/NF EN 82304-1-2017 - EN.pdf`
- ISO 13485 EN/FR: `/Users/nicolasbertrand/Documents/Normes/NF EN ISO 13485-2016.AC - EN.pdf`
- MDCG documents: `/Users/nicolasbertrand/Documents/Normes/MDCG/`
- Templates: `/Users/nicolasbertrand/Documents/Normes/Templates/` (UEF, formative plan/report, summative plan/report)

---

## 2. IEC 62366-1 Process (Clause 5) — 9 Steps

1. **5.1 — Use Specification**: Intended use, intended users (profiles), use environments, principle of operation
2. **5.2 — Identification of UI characteristics related to safety + known use problems**: State-of-the-art analysis, MAUDE/EUDAMED, literature, complaint data from equivalent devices
3. **5.3 — Identification of hazard-related use scenarios**: Task analysis → potential use errors → hazardous situations → harms. Feed into ISO 14971 risk management
4. **5.4 — Selection of hazard-related use scenarios for summative evaluation**: Critical subset that must be tested in summative
5. **5.5 — UI specification**: Design requirements for the user interface (revised in Amd 1)
6. **5.6 — Design and implementation of the UI**
7. **5.7.2 — Formative evaluation**: Iterative, exploratory — purpose revised entirely in Amd 1. Methods: think-aloud, cognitive walkthrough, heuristic evaluation, interviews, task-based testing. No pass/fail criteria — goal is to find and fix problems
8. **5.7.3 — Summative evaluation**: Objective evidence that the UI can be used safely and effectively. Requirements entirely replaced in Amd 1. Think-aloud must NOT be used (introduces bias). Must test all hazard-related use scenarios selected in 5.4
9. **5.8/5.9 — Residual risk evaluation and post-market feedback**

### Key Definitions (Clause 3)
- **Normal use** = correct use + use error (both within scope of IEC 62366-1 and ISO 14971)
- **Abnormal use** = deliberate (not "intentional" — changed in Amd 1) violation of normal use. Outside IEC 62366-1 scope but within ISO 14971 (reasonably foreseeable misuse)
- **Use error** ≠ device malfunction. Use error = act or omission by user that differs from manufacturer's intended interaction
- **Use difficulty** = "close call" — introduced in Amd 1:2020. Near-miss that could become a use error. Must be documented in summative evaluation
- **Tailoring** (not "scaling" — corrected in Amd 1) = adjusting the depth/breadth of usability engineering effort per Clause 4.3, based on novelty, complexity, criticality

### Risk Control Priority (Clause 4.1.2)
1. Inherently safe design (eliminate the hazard)
2. Protective measures in the UI (guards, warnings, constraints)
3. Information for safety (IFU, labels)
4. Training (added explicitly in Amd 1:2020 as fourth level)

---

## 3. Usability Engineering File (UEF) — Clause 4.2

The UEF documents the entire usability engineering process. Must contain or reference:
- Use specification (user profiles, use environments, intended use)
- Known use problems research
- Hazard-related use scenarios and their selection for summative
- UI specification
- Formative evaluation plans and results
- Summative evaluation plan and results
- Risk management cross-references (bidirectional traceability)
- Post-market usability data

**NB expectation**: The UEF must demonstrate a clear, traceable thread from intended use → user profiles → use scenarios → risk analysis → design decisions → formative evidence → summative evidence.

---

## 4. Formative Evaluation Best Practices

- **Purpose**: Find and fix usability problems iteratively. No pass/fail — purely exploratory
- **Methods**: Think-aloud protocol, cognitive walkthrough, heuristic evaluation, expert review, interviews, task-based usability testing, A/B comparison
- **Frequency**: As often as possible; in agile, every 1-2 sprints at major UI milestones
- **Participants**: Representative users, but smaller samples acceptable (5-8 per round is common)
- **Documentation**: Each round → formative evaluation report with findings, design changes made/planned, use errors and use difficulties observed
- **Think-aloud is allowed** in formative (but NOT in summative)
- **Personas**: Can use persona-based approach if real users unavailable for early iterations

---

## 5. Summative Evaluation — Critical Requirements

### Sample Size
- **IEC 62366-1**: No mandated minimum. IEC 62366-2 Annex K suggests 15/group
- **FDA**: Minimum 15 per distinct user group
- **Statistical basis** (Faulkner 2003): 15 users detect ~97% of problems on average; binomial model: P(detect) = 1-(1-p)^n
- **Okeiro procedure**: Requires 15 users per profile (QS-R&D-PRO-003 §2.11)

### Method Requirements (per Amd 1:2020)
- Must test all hazard-related use scenarios selected in Clause 5.4
- Think-aloud must NOT be used (introduces coaching bias → invalidates results)
- Must use simulated or actual use environment representative of real conditions
- Participants must be representative of intended user profiles
- Must document: use errors, use difficulties (close calls), task completion, root cause analysis
- Must define acceptance criteria BEFORE testing (pass/fail based on safety)

### When Re-testing is Needed
- Significant UI changes after summative → re-evaluate affected use scenarios
- New user groups identified → test with those groups
- Post-market data reveals unexpected use errors → may trigger additional summative

---

## 6. Notified Body Expectations — Common Findings

### Most Frequently Flagged Issues
1. **Incomplete UEF** — no clear traceability thread
2. **Siloed risk/usability files** — use-related hazards not in risk management file and vice versa
3. **Insufficient formative documentation** — skipping formative or not documenting iterations
4. **Summative deficiencies** — critical use errors found but not remediated before submission
5. **Weak use specification** — vague user profiles, missing use environments
6. **No post-market usability plan** — how will use errors be monitored after launch?

### What NBs Want to See
- Bidirectional traceability: risk file ↔ UEF
- Evidence of iterative design improvement (formative rounds)
- Justified sample sizes
- Clear acceptance criteria for summative
- Root cause analysis for every use error observed in summative
- Documented rationale for tailoring decisions

---

## 7. SaMD/MDSW-Specific Considerations

- **UI IS the device** — no physical safeguards; all safety-critical controls are software-mediated
- **Platform variability** — must consider multiple screen sizes, OS versions, input methods
- **Update frequency** — each significant UI change may require usability re-evaluation
- **Diverse users** — HCPs with varying IT literacy + potentially lay users (MDR Annex I §22)
- **Connected environment** — interruptions, network variability, multi-device workflows
- **Simulated use** — must include realistic digital environment (typical hardware, connectivity, concurrent apps)
- **Analytics advantage** — MDSW can collect real-world usage data (task completion rates, error rates, time-on-task) for post-market surveillance

### MDCG 2020-1 Integration
- Usability = component of **Technical Performance** validation (Section 4.3)
- Usability = component of **Clinical Performance** demonstration (Section 4.4)
- For MDSW without measurable clinical benefit: usability can be **primary clinical evidence** (Section 4.1)
- Per MDR Article 61(10): when clinical data not appropriate, manufacturer may rely on "performance evaluation, bench testing, preclinical evaluation, and **usability assessment**"

---

## 8. Risk Management Integration (ISO 14971 ↔ IEC 62366-1)

### Six Information Flows (Figure A.5, Amd 1:2020)
- **A**: Intended use, user profiles → use specification
- **B**: Hazard identification → hazard-related use scenarios
- **C**: Risk analysis → selection of critical use scenarios for evaluation
- **D**: Risk control measures → UI design requirements
- **E**: Residual risk evaluation → summative evaluation results
- **F**: Post-market information → both risk management and usability updates

### Use Error Analysis Techniques
- **UFMEA** (Use Failure Mode & Effects Analysis): task decomposition → use errors → severity × occurrence × detection
- **URRA** (Use-Related Risk Analysis): FDA-required mapping of tasks → use errors → hazards → harms → controls
- **HTA** (Hierarchical Task Analysis): goal decomposition into sub-goals, tasks, operations
- **PUEA** (Predictive Use Error Analysis): HTA + cognitive walkthrough
- **SHERPA**: taxonomy-based error classification (action, checking, retrieval, communication, selection errors)
- **FTA** (Fault Tree Analysis): top-down from harm through AND/OR gates to use error root causes

---

## 9. Agile Integration

- **Sprint 0**: Initial use specification, user profiles, known use problems
- **Each sprint**: Update use specification, lightweight formative evaluation (heuristic/cognitive walkthrough)
- **Major UI milestones**: User-based formative evaluation
- **Pre-release**: Finalize use specification, conduct summative on release candidate
- **UEF**: Progressive elaboration — living document updated throughout development
- **Definition of Done**: Include use error assessment for new features
- **Key insight**: IEC 62366-1 is inherently iterative, not waterfall. Amd 1:2020 reinforced this

---

## 10. Cybersecurity-Usability Intersection (MDCG 2019-16 Rev.1)

- **Weak security** → safety risk from unauthorized access/modification
- **Restrictive security** → safety risk from impeding legitimate use (especially emergency access)
- Authentication flows, password policies, security alerts must be included in task analysis and evaluated
- Apply risk priority hierarchy to security controls: biometric > MFA > complex passwords
- Test emergency access under stress in summative evaluation
- Security update workflows are a usability requirement for IFU

---

## 11. Post-Market Usability Surveillance

### MDR Requirements
- **Art. 83-84**: PMS system and plan must include use error data collection
- **Art. 85/86**: PMSR (Class I) / PSUR (Class IIa+) must analyze use-related incidents
- **Art. 88**: Trend reporting — statistically significant increases in use error frequency/severity

### Data Sources
- Complaints categorized by use error taxonomy
- Support logs and patterns of confusion
- In-app analytics (for MDSW): task completion, error rates, abandoned workflows
- Vigilance reports, EUDAMED, MAUDE
- Literature monitoring for equivalent devices
- App store reviews (consumer MDSW)

### Triggers for UEF Update
- Previously unidentified use errors discovered
- Known use error frequency exceeds expectations
- New user groups or use environments emerge
- Design changes based on post-market findings

---

## 12. FDA vs EU Key Differences

| Aspect | FDA | EU (IEC 62366-1 + MDR) |
|--------|-----|------------------------|
| Framework | Guidance (non-binding but expected) | Harmonised standard (presumption of conformity) |
| Abnormal use scope | Narrow (intentional abuse only) | Broader (any deliberate deviation) |
| URRA | Standalone document required | Achieved through process, no standalone doc mandated |
| Sample size | 15/group mandated | No mandate; 15/group suggested in IEC 62366-2 |
| Submission content | Tiered per device risk | Full UEF in technical documentation (Annex II) |
| Recognition | IEC 62366-1 recognized as consensus standard | IEC 62366-1 harmonised |

---

## 13. Common Mistakes to Avoid

1. Confusing use error with device malfunction
2. Using think-aloud in summative evaluation (invalidates results)
3. Treating UEF as a retrospective document rather than a living process record
4. Not defining summative acceptance criteria before testing
5. Siloing usability and risk management activities
6. Skipping formative evaluation and going straight to summative
7. Not documenting use difficulties (close calls) — required since Amd 1:2020
8. Using "scaling" instead of "tailoring" (terminology corrected in Amd 1)
9. Not including cybersecurity controls in task analysis
10. Forgetting post-market usability monitoring plan
