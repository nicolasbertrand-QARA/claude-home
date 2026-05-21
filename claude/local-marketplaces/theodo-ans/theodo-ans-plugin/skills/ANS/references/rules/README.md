# Plugin rules — modular epistemic + plumbing

Each rule lives in its own file. Commands declare which rules apply via the `applies_rules` frontmatter key. The skill loader resolves and inlines them at command load time.

## Why modular

Pre-V0.3, these rules were hardcoded in `theodo-ans-ui/services/runner.py` and concatenated dynamically by `slug`. CLI users (`claude -p '/theodo-ans-gap-analysis:ans-build Sunrise'`) never received them — silent CLI/UI divergence, an audit-defensibility hole. Migration to plugin restores CLI parity (cf. `run_state_machine.md` § « Run lifecycle »).

## Rules

| Slug | File | Applies to | Type |
|---|---|---|---|
| `probe-evidence` | `probe-evidence.md` | `/ans-build`, `/ans-self-review` | Methodology |
| `docs-fetch` | `docs-fetch.md` | `/ans-build` | Plumbing (deterministic) |
| `absence-as-nc` | `absence-as-nc.md` | `/ans-build`, `/ans-self-review` | Methodology |
| `disagreement` | `disagreement.md` | `/ans-build` (merge), `/ans-self-review`, `/ans-merge` | Methodology |
| `publish-target` | `publish-target.md` | `/ans-publish` | Plumbing (mapping) |

## Acceptance test

A CI script renders the prompt for each command twice — once via CLI direct, once via UI runner — and diffs them. Diff must be empty modulo input substitution. See `tests/cli_parity_test.sh`.
