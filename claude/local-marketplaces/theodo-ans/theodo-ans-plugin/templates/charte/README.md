# Charte graphique — Theodo HealthTech

Charte appliquée à tous les livrables HTML / Google Docs produits par le plugin theodo-ans-gap-analysis. Source : `sunrise-ans-cheatsheet.html` (5 mai 2026, kick-off Sunrise).

## Fichiers

- `theodo-healthtech.css` — feuille de styles complète (couleurs, typo, composants)

## Système de couleurs (oklch)

| Variable | Usage |
|---|---|
| `--paper` / `--paper-soft` / `--paper-deep` | Fonds (page, blocks soft) |
| `--paper-warm` | Fond yellow soft (encarts d'attention) |
| `--navy` (#1a2540 environ) | Couleur principale, headers, callouts |
| `--ink` / `--ink-body` / `--ink-soft` / `--ink-mute` | Texte (du plus foncé au plus clair) |
| `--yellow` / `--yellow-deep` / `--yellow-soft` | Accent jaune signal Theodo |
| `--terra` / `--terra-soft` | Avertissements / À éviter |
| `--green` | OK / vert vif |
| `--rule` / `--rule-strong` | Bordures et lignes |

## Typographie (Google Fonts)

À charger en `<link>` dans le `<head>` de chaque livrable :

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&family=Public+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

| Famille | Usage |
|---|---|
| **Manrope** (display, weight 700-800) | Titres h1, h2, h3, leads, phrases, callouts |
| **Public Sans** (body, weight 400) | Corps de texte, paragraphes, listes |
| **JetBrains Mono** | IDs (.id), métadonnées TOC, headers de tableaux, codes |

## Composants disponibles

### Header
```html
<header class="head">
  <div class="head-l">
    <h1>Titre principal — accent <em>jaune</em> sur les mots clés</h1>
    <p class="sub">Sous-titre court</p>
  </div>
  <div class="head-r">
    <span class="br">theodo<span class="dot"></span><span class="sub">HealthTech</span></span>
    Date · Mention
  </div>
</header>
```

### TOC (table des matières)
```html
<nav class="toc">
  <a href="#s1"><span>01</span>Section 1</a>
  <a href="#s2"><span>02</span>Section 2</a>
</nav>
```

### Section
```html
<section id="s1">
  <div class="sec-title">
    <span class="num">01</span>
    <h2>Titre de section</h2>
    <span class="meta">Métadonnée optionnelle</span>
  </div>
  <!-- contenu -->
</section>
```

### Blocks
```html
<div class="block">         <!-- block standard, paper-soft -->
<div class="block warm">    <!-- jaune doux pour attention -->
<div class="block dark">    <!-- navy pour callout fort -->
```

### Tables
```html
<table class="tbl">
  <thead><tr><th>Col 1</th><th>Col 2</th></tr></thead>
  <tbody><tr><td>...</td><td>...</td></tr></tbody>
</table>
```

### IDs (pills navy/yellow/terra)
```html
<span class="id">INS 1</span>           <!-- navy default -->
<span class="id y">IEU 9</span>         <!-- yellow (pivot) -->
<span class="id t">INS 39</span>        <!-- terra (warning/critical) -->
```

### Tags
```html
<span class="tag warn">Recommandée</span>
<span class="tag alert">Bloquante</span>
<span class="tag ok">OK</span>
<span class="tag neutral">N/A</span>
```

### Q&A
```html
<div class="qa">
  <p class="q">Question</p>
  <p class="a">Réponse</p>
</div>
```

### Callout (navy strong)
```html
<div class="callout">
  Phrase forte — accent <strong>jaune</strong> sur les mots clés.
</div>
```

### Glossary
```html
<dl class="gloss">
  <dt>Acronyme</dt><dd>Définition</dd>
</dl>
```

### Footer
```html
<footer>
  <span>Document — Date</span>
  <span><span class="y">theodo. HealthTech</span> · usage interne</span>
</footer>
```

## Règles d'application

1. **Inliner le CSS** dans chaque template `.html.tpl` via `<style>` (pas de `<link>` externe — sinon perdu après upload Google Docs).
2. **Conserver les Google Fonts** via `<link>` (Drive Docs supporte les fonts Google natives).
3. **Maintenir les classes** sans renommer — la cohérence cross-livrables impose un vocabulaire unique.
4. **Pas d'images custom** dans les livrables V0.x — tout en CSS pour préserver la conversion HTML → Google Docs.

## Conversion HTML → Google Docs

Le plugin produit du HTML, puis upload sur Drive avec conversion automatique en Google Doc :

```bash
# Via gws CLI (Theodo)
gws drive files upload <client>-executive-summary.html --convert --parent-folder=<mission-folder-id>

# Pertes attendues à la conversion :
# - Grids CSS (les colonnes deviennent linéaires) → préférer .tbl pour les structures à 2 colonnes
# - oklch couleurs → fallback hex automatique (acceptable)
# - Pseudo-elements ::before / ::after → perdus (les content="Q." / content="✕" sont remplacés par du texte hardcodé en V0.2)
# - Background-color → conservé sur les tableaux et blocks
# - Fonts Google → conservées (Manrope / Public Sans / JetBrains Mono natives Google Docs)
```

## Roadmap charte

- V0.1 — CSS source + 4 templates HTML clés (executive summary, roadmap P0/P1/P2, note positionnement INS, intake fiche projet)
- V0.2 — Tous les autres livrables convertis HTML
- V0.3 — Fallback texte pour les pseudo-elements (Q. / R. / ✕ / ▶ en hardcode pour Google Docs)
- V0.4 — Logo Theodo HealthTech embedded en SVG (V1+ si demandé)

---

*Charte préparée le 2026-05-07. Version 1.0.0.*
