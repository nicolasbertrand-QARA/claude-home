---
name: Theodo QMS team — gender for French agreement
description: Known gender (f/m) of Theodo team members involved in QMS workflows, for French verb/adjective agreement in emails and docs
type: reference
originSessionId: f34fd628-0741-46e3-b734-2f29ae1e79b8
---
Used by `/Users/nicolasbertrand/.claude/scripts/qms-relancer.py` (`GENDER_BY_EMAIL`) and any other automation that generates French text addressed to a Theodo person.

| Email | Name | Gender |
|---|---|---|
| nicolas.bertrand@theodo.com | Nicolas Bertrand | m |
| marine.accolas@theodo.com | Marine Accolas | f |
| noemie.parker@theodo.com | Noémie Parker | f |

When new verifiers/approvers appear in the QMS Notion DB, extend this list and the script's `GENDER_BY_EMAIL` map. The script logs a `WARN` to `qms-relancer.err.log` when it encounters an unknown email and falls back to masculine.
