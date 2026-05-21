---
description: Convertit les livrables HTML en Google Docs et les publie sur Drive (folder mission).
argument-hint: <client-slug>
applies_rules: [publish-target]
requires_tier_at_least: T3
retry_policy: transient_only
criticality: warning
failure_blocks: []
---

# /ans-publish {{ args }}

Tu publies les livrables HTML produits par `/ans-deliverables` en **Google Docs natifs** sur le folder Drive de la mission. Conversion via gws CLI (`gws drive files upload --convert`) qui prend l'HTML et crée un Google Doc équivalent.

## Pré-requis

- `/ans-deliverables {{ args }}` exécuté → fichiers HTML dans `deliverables/` du folder mission
- gws CLI authentifié sur compte Theodo (cf. `scripts/setup.sh`)
- ID du folder Drive de la mission (depuis `intake/project-brief.json` → `mission.client.drive_folder_id` ou `intake/kickoff-info.md`)
- État machine : `jalon-3-signed` (ou DP override) — `/ans-publish` est destiné à la remise client

## Charge de la rule publish-target

→ Voir `skills/ANS/references/rules/publish-target.md` (auto-loaded via `applies_rules`). Mapping subfolder Drive + idempotence checksum + chmod 444 préservé pour probes.

## Discipline gws — V0.4 Lot 11 (NON NÉGOCIABLE)

Le folder mission vit sur un **Shared Drive** (Hokla > Projets > <client>).
Tous les appels gws drive DOIVENT inclure les flags Shared-Drive sinon
ils renvoient 404 ou des résultats partiels :

- `gws drive files get` / `update` / `delete` / `copy` :
  ajouter `"supportsAllDrives":true` aux `--params`.
- `gws drive files list` :
  ajouter `"supportsAllDrives":true,"includeItemsFromAllDrives":true,"corpora":"allDrives"`.

**Sans ces flags, un folder dans un Shared Drive renvoie 404 même si
existant et accessible.** C'est la cause racine du bug Sunrise 2026-05-09
qui a re-publié dans `Contrats/Sunrise/` au lieu de `Projets/Sunrise/`.

## Discipline drive_folder_id (V0.4 Lot 11)

Le `mission.client.drive_folder_id` lu dans `intake/project-brief.json`
est **autoritaire**. Si ce `gws drive files get --params {fileId,
supportsAllDrives:true}` ne le résout pas :

- **NE JAMAIS** fallback en name-search (`q: "name='Sunrise'"`) — un nom
  client est rarement unique (ex. `Sunrise` existe sous `Contrats` ET
  `Projets`, le name-search retourne le premier match alphabétique qui
  n'est presque jamais le bon).
- **NE JAMAIS** créer un nouveau folder « Sunrise » ou « Mission ANS — Gap
  analysis » à un endroit deviné.
- À la place, exit avec code 3 (`brief_missing` étendu sémantiquement à
  `drive_folder_unresolvable`) + écrire `analysis/.last-run-status.json`
  avec `reason_code: "drive_folder_unresolvable"` + le message humain
  « ID `<ID>` configuré dans le brief ne résout pas. Vérifie le brief
  ou demande au PM la bonne URL Drive avant de relancer. ».

## Étapes

### 0. Pré-flight Drive folder (V0.4 Lot 11)

```bash
BRIEF=~/missions/{{ args }}/intake/project-brief.json
FOLDER_ID=$(jq -r '.mission.client.drive_folder_id // empty' "$BRIEF")
if [ -z "$FOLDER_ID" ]; then
  python3 -c '
import json, datetime
from pathlib import Path
out = Path.home() / "missions" / "{{ args }}" / "analysis" / ".last-run-status.json"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({
    "exit_code": 3,
    "reason_code": "drive_folder_id_missing",
    "stage": "etape_0",
    "command": "ans-publish",
    "message_human": "mission.client.drive_folder_id absent du brief — patche-le ou réinitialise via /ans-init",
    "finished_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
}, ensure_ascii=False, indent=2), encoding="utf-8")
'
  echo "ÉCHEC : drive_folder_id manquant dans le brief"; exit 3
fi

# Resolution AVEC supportsAllDrives — sans ce flag, 404 sur shared drive
RESOLVED=$(gws drive files get --params "{\"fileId\":\"$FOLDER_ID\",\"supportsAllDrives\":true,\"fields\":\"id,name,parents,driveId\"}" 2>/dev/null | jq -r '.id // empty')
if [ -z "$RESOLVED" ]; then
  python3 -c "
import json, datetime
from pathlib import Path
out = Path.home() / 'missions' / '{{ args }}' / 'analysis' / '.last-run-status.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({
    'exit_code': 3,
    'reason_code': 'drive_folder_unresolvable',
    'stage': 'etape_0',
    'command': 'ans-publish',
    'configured_id': '$FOLDER_ID',
    'message_human': 'drive_folder_id $FOLDER_ID configuré dans le brief mais gws ne le résout pas (même avec supportsAllDrives:true). Vérifie le brief ou demande au PM la bonne URL Drive avant de relancer. NE JAMAIS fallback name-search — risque de pousser dans un homonyme.',
    'finished_at': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
}, ensure_ascii=False, indent=2), encoding='utf-8')
"
  echo "ÉCHEC : folder $FOLDER_ID inaccessible — voir analysis/.last-run-status.json"; exit 3
fi
echo "[publish] drive_folder_id résolu : $FOLDER_ID"
```

### 1. Vérifier les pré-requis

- Folder mission Drive identifié (extrait de `kickoff-info.md` ou demandé au PM)
- Liste des HTMLs dans `deliverables/` :
  - `01-executive-summary.html`
  - `03-roadmap-P0-P1-P2.html`
  - `04-note-positionnement-INS.html` (Voie A ou B selon décision)
  - `05-plan-gestion-identites.html` (V0.x — squelette ou MD si HTML pas encore disponible)
  - `06-matrice-rbac-identite.html` (V0.x)
  - `07-dpia-template.html` (V0.x)
  - `08-lettre-demande-PSC.html` (V0.x)
  - `09-lettre-demande-INSi.html` (V0.x — si Voie A)
  - `10-lettre-demande-MSSante.html` (V0.x — si applicable)
- Le gap-analysis.xlsx est déjà natif (pas besoin de conversion)

### 2. Pour chaque HTML, inliner le CSS de la charte

Lire `templates/charte/theodo-healthtech.css` et remplacer le placeholder `{{ INLINE_CSS_HERE }}` dans chaque HTML par le contenu du CSS.

```bash
CSS_CONTENT=$(cat ~/theodo-ans-plugin/templates/charte/theodo-healthtech.css)
for html in deliverables/*.html; do
    # Remplace le placeholder par le CSS inline
    awk -v css="$CSS_CONTENT" '
        /\{\{ INLINE_CSS_HERE/ { print css; next }
        { print }
    ' "$html" > "${html}.inlined" && mv "${html}.inlined" "$html"
done
```

### 3. Conversion + upload Drive (Google Doc) — idempotent strict

Pour chaque HTML, suivre le **mapping subfolder** de `rules/publish-target.md` puis :

```bash
FOLDER_ID="<extracted-from-project-brief.json>"

for html in deliverables/*.html; do
    name=$(basename "$html" .html)
    # 1. Calcul SHA256 local
    LOCAL_SHA=$(shasum -a 256 "$html" | cut -d' ' -f1)
    # 2. Lookup Drive existant — IMPORTANT: supportsAllDrives + corpora
    #    sinon le list ne voit pas les enfants d'un Shared Drive.
    EXISTING_ID=$(gws drive files list --params "{\"q\":\"name='{{ args }} — $name' and '$DELIVERABLES_FOLDER_ID' in parents and trashed=false\",\"fields\":\"files(id,md5Checksum)\",\"supportsAllDrives\":true,\"includeItemsFromAllDrives\":true,\"corpora\":\"allDrives\"}" | jq -r '.files[0].id // empty')
    if [ -n "$EXISTING_ID" ]; then
        DRIVE_MD5=$(gws drive files get "$EXISTING_ID" --params '{"fields":"md5Checksum"}' | jq -r '.md5Checksum')
        # On compare via MD5 pour Drive (Drive native field) — local on convertit
        # NB : Pour HTML→Google Doc converti, on ne peut pas comparer md5 du source HTML directement.
        # Fallback : compare le sha local au précédent stocké dans deliverables/published-urls.md (colonne sha).
        STORED_SHA=$(grep -E "^\| $name \|" deliverables/published-urls.md | awk -F '|' '{print $5}' | tr -d ' ')
        if [ "$LOCAL_SHA" = "$STORED_SHA" ]; then
            echo "[skip] $name unchanged"
            continue
        fi
        # Update existing
        gws drive files update --upload "$html" --params "{\"fileId\":\"$EXISTING_ID\"}"
    else
        gws drive files upload "$html" --convert --parent-folder="$DELIVERABLES_FOLDER_ID" --title="{{ args }} — $name"
    fi
done
```

Met à jour `deliverables/published-urls.md` avec colonne `sha256_local` pour la prochaine comparaison.

Inclut aussi : sync `analysis/` (final + merge-trace), `archive/` (intermediates), `briefs-revue/`, `intake/` (project-brief.json + decisions.md + autres), `probes/` (specs + reports + MANIFEST.md). Cf. mapping `rules/publish-target.md`.

### 4. Vérifier la conversion

Pour chaque Google Doc créé, ouvrir l'URL en lecture et vérifier :
- [ ] Header navy + accent jaune visible
- [ ] Tables rendues correctement (bordures + headers mono)
- [ ] IDs pills navy/yellow/terra rendus (ou fallback texte si pseudo-elements perdus)
- [ ] Callouts (navy background) présents
- [ ] Polices Manrope / Public Sans / JetBrains Mono utilisées (Google Fonts natives)

⚠ **Pertes attendues** à la conversion (non-bloquantes V0.1) :
- Grids CSS (colonnes deviennent linéaires) — préférer `.tbl` à 2 colonnes
- Pseudo-elements `::before` `::after` (les "Q." / "R." / "✕" / "▶") — perdus, à hardcoder en V0.2
- oklch couleurs → fallback hex automatique (acceptable)

### 5. Permissions

S'assurer que les Google Docs créés ont les bonnes permissions :
- Theodo PM + DP : edit
- Client RAQ + DPO : reader (pour le pré-kit final, jalon 3)
- Pas d'accès anonyme

```bash
# Si fait après remise du pré-kit (jalon 3 OK) :
for url in $(cat deliverables/published-urls.md); do
    gws drive files share "$url" --reader="{{ raq_email }}"
    gws drive files share "$url" --reader="{{ dpo_email }}"
done
```

### 6. Mettre à jour le README mission

Ajouter dans `README.md` du folder Drive mission une section « Livrables Google Docs » avec les URLs.

## Output au PM

```
{{ args }} — livrables publiés en Google Docs.

Fichiers convertis :
- 01-executive-summary → <URL>
- 03-roadmap-P0-P1-P2 → <URL>
- 04-note-positionnement-INS → <URL>
- ...

URLs listées : deliverables/published-urls.md

Vérifications visuelles à faire (3-5 min) :
- Ouvrir chaque Google Doc et vérifier le rendu de la charte
- Si écart majeur, lancer /ans-publish à nouveau ou reporter à un fix V0.2

Permissions : Theodo en edit, client en reader (à activer après jalon 3 validé).
```

## Discipline

- **Ne jamais convertir un HTML qui n'a pas été inliné** : sans CSS inliné, le Google Doc résultant sera nu (pas de styles)
- **Vérifier que le CSS placeholder a été remplacé** avant upload (sinon le `<style>` sera vide)
- **Ne pas écraser** les Google Docs existants : `gws drive files upload` doit créer une nouvelle version, pas remplacer
- **Si gws CLI échoue** : fallback manuel = ouvrir l'HTML dans Chrome → Print → "Save as PDF" + uploader le PDF dans Drive (Drive convertit en Google Doc automatiquement)
