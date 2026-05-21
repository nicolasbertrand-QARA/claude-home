# Run / Mission State Machine — V0.3

This document defines the explicit state machine governing run lifecycle, jalon signatures, overrides, and degenerate-run blocks. Pre-V0.3, these were implicit; V3 peer review (2026-05-08) flagged "design without architecture". This document is normative — every state transition must be implemented in `theodo_ans_ui/db.py` (table `mission_state_transitions`) and respected by the runner + form handlers.

---

## States (per mission)

| State | Description | Allowed actions |
|---|---|---|
| `idle` | No run in progress, no jalon pending. | start any command, edit Project Brief, edit verdicts, sign jalon. |
| `running` | A run is executing (`/ans-build`, `/ans-probe`, etc.) — lock held. | wait, cancel run. **No** edits to Project Brief or verdicts. |
| `degenerate-blocked` | Last `/ans-build` triggered the degenerate-run heuristic (cf. `quality_thresholds.md`). | edit Project Brief (fix the cause), re-run `/ans-build`, **DP override-with-rationale** to bypass and advance. |
| `jalon-1-pending` / `jalon-2-pending` / `jalon-3-pending` | Run completed, awaiting DP signature. | sign jalon, edit verdict_overrides, edit Project Brief. |
| `jalon-1-signed` / `jalon-2-signed` / `jalon-3-signed` | DP has signed this jalon. Downstream commands unlocked. | start next-jalon command. Editing verdicts moves state to `jalon-N-stale`. |
| `jalon-1-stale` / `jalon-2-stale` / `jalon-3-stale` | A signed jalon has been invalidated by post-signature edits (verdict_overrides, sub-decision re-version). | re-sign jalon (back to `jalon-N-signed`), or revert the edit. |

---

## Transitions

### Run lifecycle

| From | Trigger | To | Notes |
|---|---|---|---|
| `idle` | `claude -p '/ans-X'` started | `running` | Lockfile acquired (cf. lockfile contract). |
| `running` | exit 0 | depends on cmd | `/ans-build` → `jalon-2-pending` OR `degenerate-blocked` (if heuristic). `/ans-deliverables` → `jalon-3-pending`. `/ans-publish` → `idle`. `/ans-probe` → previous state (probe doesn't gate jalons). |
| `running` | exit ≠ 0 | `idle` | Lockfile released. Run marked `failed`. |
| `running` | SIGTERM / cancel | `idle` | Lockfile released. Run marked `cancelled`. |

### Jalon signature lifecycle

| From | Trigger | To | Constraints |
|---|---|---|---|
| `jalon-N-pending` | DP signs all required sub-decisions | `jalon-N-signed` | All sub-decisions for this jalon have at least 1 version. |
| `jalon-N-signed` | verdict_override added/edited OR sub-decision re-versioned with downstream impact | `jalon-N-stale` | Stale-tracking via `sub_decision_impact.json` dependency map. |
| `jalon-N-stale` | DP re-signs (new version of jalon validation sub-decision) | `jalon-N-signed` | Must include `rationale_change`. |
| `jalon-2-signed` | `/ans-deliverables` started | `running` | Lockfile acquired; jalon-2 stays signed until completion. |
| `jalon-N-signed` | `/ans-build` re-run with new project-brief | `running` then `jalon-2-pending` | Old signature preserved in audit trail; new pending. |

### Degenerate-blocked lifecycle

| From | Trigger | To | Notes |
|---|---|---|---|
| `running` | `/ans-build` exit 0 + heuristic fires | `degenerate-blocked` | Banner shown; advance to `/ans-deliverables` blocked. |
| `degenerate-blocked` | `/ans-build` re-run, exit 0, heuristic clears | `jalon-2-pending` | Issue resolved (e.g., docs_drive_url corrected, gws auth fixed). |
| `degenerate-blocked` | DP signs an "override-with-rationale" decision | `jalon-2-pending` | Bypass requires explicit signature + rationale (audit trail). |

### Override lifecycle

| From | Trigger | To | Notes |
|---|---|---|---|
| any | new `verdict_override` written via UI | same state, then maybe `jalon-N-stale` | Override is itself versioned (append-only) — supersedes_override_id chain. |
| `jalon-2-signed` | new `verdict_override` written | `jalon-2-stale` | Re-sign required. |
| `jalon-2-stale` | re-sign jalon-2 ratifying current overrides | `jalon-2-signed` | Override list snapshot is part of the signature payload. |

---

## Concurrency

The mission lockfile (`~/missions/<client>/.lock`, PID + ISO8601 timestamp) is acquired:

- Always at run start (any `/ans-*` command). Released on exit.
- Optionally by UI form save handler (writes to project-brief.json).

Conflicts:

- Run vs UI form: form save while run is active → form returns 409 with link to run log.
- UI form vs UI form (multi-tab): last-write-wins (single-user). Etag check optional in V0.4.
- Stale lock (orphan PID): UI's `db.reap_orphans()` removes lock if PID no longer exists.

---

## Audit trail

Every transition is logged in SQLite table `mission_state_transitions`:

| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| mission_id | INTEGER FK | |
| from_state | TEXT | |
| to_state | TEXT | |
| triggered_by | TEXT | run_id, user signature, system (orphan reap) |
| occurred_at | TEXT (ISO8601) | |
| project_brief_sha | TEXT | hash of project-brief.json at transition time — reproducibility |
| context_json | TEXT | freeform context (e.g., heuristic criteria triggered for `degenerate-blocked`) |

Exported in `audit-packets/` on `/ans-publish` (post-V0.3).

---

## CLI parity test

Edgar should be able to reach the same states from CLI:

```bash
claude -p '/theodo-ans-gap-analysis:ans-build Sunrise'
# → reads ~/missions/Sunrise/intake/project-brief.json
# → respects lockfile
# → on exit triggers same state transition as UI run would
```

The plugin commands write transitions to the same SQLite if `THEODO_ANS_UI_DATA_DIR` is set; otherwise to a local `~/.theodo-ans-cli/transitions.jsonl` for later sync. This preserves audit trail even for CLI-only users.
