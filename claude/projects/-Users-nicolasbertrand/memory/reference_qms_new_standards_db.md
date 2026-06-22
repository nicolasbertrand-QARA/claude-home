---
name: reference-qms-new-standards-db
description: "Theodo HealthTech \"new QMS standards\" live in the BDD new standards Notion DB; how-to house format, État workflow, trace spine, author identity"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6b2931d0-85f5-4c49-b0bd-29c4f1c267c8
---

The Theodo HealthTech QMS "new standards" (MDR + AI Act, SaMD + AI System) live in the **BDD new standards** data source: `collection://3528f377-6f4f-803c-a09b-000b2e18f0d3` (parent page "BDD new standards" 3528f3776f4f80fd81b6c489506515ad, under Obeya - QMS IA Act). Distinct from the Theodo Academy Standards DB ([[reference_theodo_academy_standards]]) and from the controlled ISO 13485 doc set (Quality Manual QM-001, QM-002 Quality Policy, PRO-xxx procedures).

**Structure:** Lifecycle standards (Standard - SaMD Lifecycle 35e8f377...8817f; Standard - AI System Lifecycle 36c8f377...9514) → Phase pages 1-7 + Gates 1-4 → how-to/activity standards (Design Inputs 3758f377...a8ed; Specifications "STRD - specifications" 3528f377...37e4; Verification 3758f377...b544; **User Story 3808f377...9c0c**; Gouvernance & Sprint 0 3598f377...be95) → templates (Spec template 3528f377...f20c).

**Trace spine (the golden thread):** Gemba/intended use → input register → URS v1 (lock at Gate 1) → SRS per feature (decomposed in Design) → User Story + Acceptance Criteria → Verification (AC lifted unchanged into verification rows, Gate 3) → Validation (Gate 4). Decomposition is never a new requirement; a genuinely new requirement re-routes through PRO-017. The AI model is specified by the **model card + locked AI design inputs**, NOT by an SRS.

**How-to house format (mirror this for any new how-to standard):** nav callout (🧭 blue_bg: "Plugs into / Locks-or-Closes-or-Feeds Gate N / Status: DRAFT vX") → `# Intent {pink_bg}` (incl. explicit scope-exclusions) → `# Key info {green_bg}` (mermaid trace spine + a "N mandatory properties; missing one = X not Y" table) → `# Operating mode {blue_bg}` (numbered Steps as toggle headings `{toggle="true" color="gray_bg"}`, each = Owner / Approver / How bullets / Done when) → optional `{red_bg}` critical section → `# Common mistakes {purple_bg}` (KO list, each line ends "KO.") → `# Resources {yellow_bg}` (Calling standards / Related standards & procedures / Regulatory & normative anchors) → `# Annex {gray_bg}` (version table, dates DD/MM/YY). House rule: no em dashes.

**État workflow:** Not started → Draft IA Act → In verification IA Act → In approval IA Act → Approved. "Verified by [QMS IA Act]" and "Approved by [QMS IA Act]" are HUMAN gates. When drafting a NEW standard: set `État = "Draft IA Act"`, `Author = ["118d872b-594c-8110-b4a0-000290ccd72d"]` (Nicolas Bertrand), leave verifier/approver + dates empty. Title property is "Nom"; naming convention "Standard - X" (older entries use "STRD - x"). Cross-referenced procedures: PRO-006 Design, PRO-008 Traceability, PRO-011 Risk Mgmt, PRO-013 Non-compliance, PRO-017 Change Control.
