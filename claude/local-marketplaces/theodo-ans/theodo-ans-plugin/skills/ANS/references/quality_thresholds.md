# Quality Thresholds — Degenerate Run Detection

Used by `/ans-build` post-output and by UI bandeau detection. Pre-V0.3, hardcoded "À confirmer ≥ 50%" was the only check — caused 91-À-confirmer Sunrise V4 to ship without alert.

---

## Multi-criteria heuristic

A run is flagged **degenerate** if ANY of:

| Criterion | Threshold | Likely cause | Suggested action |
|---|---|---|---|
| `À confirmer` ≥ 50% | absolute | docs_drive_url not fetched, profils not decided | Verify `tech.docs_drive_url` in Project Brief; check gws auth; verify T3 fields |
| `Non applicable` ≥ 60% | absolute | Voie B mass-update without intent, OR all profils unchecked | Verify `dp_decisions.jalon_1.profils_dmn`; verify `voie_ins.audit_outcome_for_other` |
| `Non conforme` = 0 (count, not %) | exact | Probe couldn't authenticate, OR docs hallucinated | Verify probe ran successfully (no `[PROBE-AUTH-FAILED]`); verify docs hashes match |
| `sources_client` empty on ≥ 30% | absolute | docs/ folder empty, agent inferred without primary source | Verify ls ~/missions/<client>/docs/ ; check docs-fetch step succeeded |

If degenerate detected: state machine moves to `degenerate-blocked` (cf. `run_state_machine.md`). Banner displays in UI with the criteria triggered + suggested action. DP can override with signed rationale to bypass.

---

## Regression differential

If a previous run for the same mission exists, also compare:

| Delta criterion | Threshold | Action |
|---|---|---|
| `À confirmer` jumps by ≥ 30 absolute points | warning | Show "régression suspectée" — what changed in Project Brief? |
| `Non conforme` count drops by ≥ 50% | warning | Show "potential under-flagging — verify scope changes intentional" |
| Total exigences count changes | warning | Schema mismatch — likely bug |

---

## Baseline distributions per (pathway, voie)

To avoid false positives on legitimately-narrow scopes (e.g., a Voie B mission where N/A ≥ 60% is expected), expert-set baselines tighten the heuristic.

See `baseline_distributions.json` (V0.3 stub — to be enriched as missions accumulate). Banner uses `delta vs baseline > 2σ` rather than absolute thresholds when a baseline exists.

---

## CLI parity

Plugin command `/ans-build` runs this check at the end of step 8 (output). The CLI version writes the result into `analysis/coverage.md` in a frontmatter block:

```
---
degenerate_check:
  triggered: false
  criteria_passed: [a-confirmer-pct, na-pct, nc-count, sources-empty]
---
```

UI reads this frontmatter to drive the bandeau. If `triggered: true`, UI blocks advancement and shows criteria + suggested action.
