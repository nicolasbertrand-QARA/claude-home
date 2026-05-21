# Rule — Docs Fetch (deterministic step)

**Applies to**: `/ans-build` (mandatory step before any verdict).

If the Project Brief (`intake/project-brief.json`) declares `tech.docs_drive_url` (folder Google Drive containing SRS / SDS / SOPs / URS / client manuals), you MUST first repatriate these files into `~/missions/<client>/docs/`:

1. Extract folder ID from URL (substring after `/folders/`, until `?` or end).
2. List via:
   ```
   gws drive files list --params '{"q":"<folderId> in parents and trashed=false","fields":"files(id,name,mimeType,size)","supportsAllDrives":true,"includeItemsFromAllDrives":true,"pageSize":100}'
   ```
3. For each PDF/DOCX/binary:
   ```
   gws drive files get <fileId> -o ~/missions/<client>/docs/<safeName> --params '{"alt":"media","supportsAllDrives":true}'
   ```
4. For native Google Docs/Sheets:
   ```
   gws drive files export <fileId> -o <name>.pdf --params '{"mimeType":"application/pdf","supportsAllDrives":true}'
   ```
5. Verify with `ls ~/missions/<client>/docs/`. If empty after attempt, log error in `coverage.md` and continue, BUT mark functional doc as "non récupérée" in coverage.
6. Read each downloaded file via the Read tool (PDF natively supported).

Without this step, Q9-A triangulation is impossible and you will produce a degenerate gap with 90% « À confirmer » — unacceptable.
