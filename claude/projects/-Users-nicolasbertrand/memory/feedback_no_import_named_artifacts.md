---
name: Don't import named artifacts from reference SOPs without verification
description: When adapting a reference SOP/template (Doctolib, FDA guidance, peer company), do not import named deliverables/roles/gates verbatim. Each named element must exist at Theodo (or be explicitly created) before being used in a Theodo standard.
type: feedback
originSessionId: f89056ae-539b-4c13-98f4-0c0fff6d60e0
---
When drafting a Theodo standard using a reference SOP or template (e.g., Doctolib's lifecycle SOP), DO NOT import named artifacts (deliverables, roles, document types, ceremonies, gates) without first verifying they exist at Theodo or are being explicitly introduced.

**Why:** I imported "Lifecycle Scoping Document (LSD)" from Doctolib's SOP into the Theodo SaMD lifecycle standard. LSD is Doctolib-specific — it does not exist at Theodo, where the SDP (Software Development Plan) already plays that role. The user caught it. Importing foreign vocabulary creates documents that confuse Theodo operators (the primary audience per `feedback_sop_audience.md`).

**How to apply:**
- For each named artifact in a reference doc, check: does Theodo already have an equivalent? If yes, use Theodo's name. If no, decide whether to introduce it (with explicit justification) or rewrite without it.
- When in doubt, ask the user before adopting any document type / role / ceremony name from a reference.
- Reference docs (Doctolib SOP, FDA guidance, peer company templates) are inspirational *patterns*, not vocabulary sources. Translate the pattern into Theodo-native terms.
- Theodo-native sources to check first: PRO-006-V08 (current design SOP), PRO-007/008/011/017, the Tracks-roles-competencies DB, the Academy standards DB.
