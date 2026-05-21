# Rule — Publish Target (folder mapping)

**Applies to**: `/ans-publish`.

When uploading to Drive, **reuse the subfolder structure created by `/ans-init`** instead of dumping at root.

## Mapping (mission folder → Drive subfolder)

| Local file pattern | Drive subfolder |
|---|---|
| `01-gap-analysis.xlsx` | `analysis/` |
| `02-…` to `10-…` (pré-kit Convergence) | `deliverables/` |
| `README mission` | root of mission folder |
| `briefs-revue/jalon-X.md` | `briefs-revue/` |
| `analysis/coverage.md`, `disagreements.md`, `assessments.*.json`, `merge-trace.json` | `analysis/` |
| **All `probes/`** (Playwright specs, captures, JSON, capture protocols, strategy.md, exigences-coverage.md, reports/, MANIFEST.md) | `probes/` (mirror local structure recursively) |
| `intake/decisions.md`, `kickoff-info.md`, `fiche-projet.html`, `pathway-decision.md`, `docs-tracking.md`, `document-request-letter.md`, `visio-prep.md`, `project-brief.json`, `project-brief.html` | `intake/` |
| `archive/` (intermediate versioned assessments, audit-bearing) | `archive/` (cold storage) |

## Excluded from upload

`node_modules/`, `package-lock.json`, `.DS_Store`, `*.tmp`, `~$*` (Office lockfiles), `.lock`, `.venv/`, **`access/credentials.json` (testing creds, chmod 600 — never on Drive)**.

## Why probes/ must be on Drive

1. The DP needs Playwright screenshots to audit NCs in jalon 2.
2. `capture-protocol-{ios,android}.md` files are meant to be transmitted to the client RAQ — they must live on Drive for read-only sharing without email attachments.

## Procedure

For each file, get the target subfolder ID (recursive creation if needed for `probes/reports/artifacts/` etc.):

```
gws drive files list ... 'name=X and mimeType=...folder'
gws drive files upload <local> --parent-folder=<subfolderId>
```

For non-HTML (md, ts, json, png), do NOT pass `--convert`.

## Idempotence (strict checksum)

If file already exists on Drive (same name in same parent), compare local SHA256 to Drive `md5Checksum` (Drive native field). If identical, **skip upload**. If different, update via:

```
gws drive files update --upload <local> --params '{"fileId":"<id>"}'
```

Avoid creating duplicates.

## Update index

Update `deliverables/published-urls.md` with **all** Drive URLs (deliverables + shareable probes + intake) so `/ans-publish` is re-runnable idempotently.
