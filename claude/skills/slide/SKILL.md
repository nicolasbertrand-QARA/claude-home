---
name: slide
description: Build self-contained HTML slide decks with editorial typography, 16:9 layout, keyboard navigation, real fullscreen mode (proportional rem scaling, not just browser fullscreen on a small frame), and print-to-PDF. Use when the user mentions building slides, a slidedeck, a presentation HTML, a deck, briefing slides, pitch slides, or asks for "slides" on a topic.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Bash
argument-hint: "[topic or brief]"
---

# Slide Deck Builder

Build a single self-contained HTML file that behaves like a real slide deck: 16:9 slides, keyboard navigation, true fullscreen mode that scales typography proportionally to the rendered slide (not a tiny letterbox in the middle of a black screen), and print-to-PDF that puts one slide per A4 landscape page.

The visual identity is editorial print-quality: Manrope (display) + Public Sans (body) + JetBrains Mono (mono), OKLCH palette with navy ink + yellow + terracotta accents, generous whitespace, dense information per slide without visual noise.

## When to use this skill

Anytime the user wants slides as HTML: client briefings, pitch decks, technical explanations, kickoff decks, training material, conference talks. Default to this format when the user says "slide deck", "présentation HTML", "deck", "briefing slides", "slides for X".

Don't use this for: long-form prose (use plain HTML or Markdown), one-off graphics, or actual Google Slides / PowerPoint (different deliverable).

## Operating principles

1. **Confirm scope first** (1 turn, terse): topic, audience, # slides, language, brand colors (default = navy/yellow/terra), output path. Don't ask if obvious from context.
2. **Copy the template, then adapt.** Start from `references/template.html`. Don't rebuild the scaffold from scratch each time.
3. **Pick the right pattern per slide.** Six core patterns exist (table below; each is a worked example in `references/template.html`). Most decks mix three or four of them.
4. **Telegraphic style.** Target ~80-120 words of content per slide (excluding titles). Sentences are fragments. Tables beat paragraphs. Lists beat prose.
5. **No AI-slop.** Apply the anti-slop checklist before delivery (see below).
6. **No em dashes in deliverable content** (CLAUDE.md global rule). Replace with colons, semicolons, parentheses, or sentence breaks.
7. **Open the file in the browser when done** (`open path.html` on macOS).

## Slide patterns

| Pattern | When to use | Structure |
|---|---|---|
| **Cover** | Slide 1 | Eyebrow + huge `h1` (5.2rem) + lead + brand meta + footer with reference |
| **Two-block lead** | Cadre / framing slides | `grid-asym` (1.05fr / 1fr): lead text + bullets on left, stacked colored blocks on right |
| **Comparative** | Side-by-side concepts | `grid-2` with two `.block` cards, each with colored left border, compact `.tbl` inside |
| **Wide table** | Detailed reference (e.g. requirements list) | Full-width `.tbl` with mono ID column, énoncé column, implication column. Use `tr.hilite` for emphasized rows |
| **Flow diagram + sidebar** | Technical architecture / data flow | Left: `.flow` with `.node` boxes + arrows. Right: stacked `.block` cards (default / dark / terra / warm) |
| **Action plan** | Closing slide / next steps | Left: ordered list (mono decimal-leading-zero). Right: dark block (livrables) + warm block (calendrier table) + closing note |

## Deck anatomy (every slide)

```html
<section class="slide [active]" data-topic="Topic name">
  <div class="strip">      <!-- top mono-cap strip with slide # and brand -->
  <div class="body|cover"> <!-- main content area -->
  <div class="foot">       <!-- bottom mono strip with page number -->
</section>
```

Inside `.body`:
- `.eyebrow` (mono uppercase, yellow-deep) — slide category
- `h2.slide-title` (Manrope 800, 2.4rem) — the slide title, with `<em>` for yellow accent words
- `.kicker` (Public Sans 300, 1.15rem) — one-sentence framing, max 1-2 lines
- Content area (grids, blocks, tables, flow)

## Block variants

Use color to create visual hierarchy without adding text:

- `.block` (default) — paper-soft background, for neutral info
- `.block.warm` — yellow accent, for warning / "watch this" notes
- `.block.dark` — navy fill with yellow headers, for primary rules / definitions
- `.block.terra` — terracotta accent, for pitfalls / red flags
- `.block.green` — green accent, for confirmations / OK paths

## Anti-slop checklist (apply before delivery)

Forbidden patterns in slide content:

| Pattern | Why bad | Replace with |
|---|---|---|
| "X n'est pas Y, c'est Z" / "Not X, but Y" | Classic AI rhetorical fingerprint | Direct factual statement |
| Italics on filler words (concrètement, structurellement, fondamentalement) | Performative emphasis | Cut the word |
| Triadic title structures ("Deux portes, deux X, deux Y") | AI loves rule of three | One direct phrase |
| Anthropomorphic slogans ("PSC porte l'auth") | Marketing tone, not technical | Subject-verb-object factual |
| "Voici", "Concrètement", "En substance", "À retenir" tags | Filler / TOC-like | Remove |
| "Comment X vérifie que..." rhetorical openers | AI essay framing | Direct claim |
| Em dashes (—) | Deliverable rule (CLAUDE.md) | Colon, comma, parens, period |
| "Impérativement", "non négociable", "structurel" | Performative intensifiers | "Doit", "obligatoire" |
| Double statement ("insuffisant. Non conforme.") | Redundant | Pick one |
| Metaphors ("le couloir attendu", "la carte mentale") | Anthropomorphism | Plain noun |

Run `grep -nE "n'est pas|c'est plus|carte mentale|impérativement|non négociable|deux portes|chaînage|—" path.html` before declaring done.

## Content compression rules

| Source style | Target style |
|---|---|
| 2-line kicker | 1-line kicker |
| Paragraph of 4 sentences | Bullet list of 4 items |
| Table cell with sentence | Table cell with fragment |
| "Vérifier l'adresse email à création" | "Email vérifié à création" |
| "Le système DOIT permettre..." | "Permet..." or just verb infinitive |
| Repetition between kicker and bullets | Cut the kicker repetition |

Rough budget: title (1 line) + kicker (1 line) + 60-100 words of body. If a slide approaches 150 words, split it.

## Fullscreen behaviour

The template includes JS that, on `F` key:
1. Calls `documentElement.requestFullscreen()` (with `-webkit-` fallback for Safari)
2. On the `fullscreenchange` event, toggles `html.fs` and `body.fs` classes
3. Calculates the rendered slide height: `min(viewportH, viewportW × 9/16)`
4. Sets `html.style.fontSize = slideH / 720 × 17 + 'px'` so every `rem` scales proportionally to the original 1280×720 design
5. A `resize` listener re-runs this if the viewport changes mid-fullscreen

This is what makes the deck actually fill the screen with proportional typography, rather than staying as a 1280px frame surrounded by gray.

## Other keyboard shortcuts

- `← / →` / `PageUp / PageDown` / `Space` — navigate
- `Home / End` — first / last slide
- `F` — toggle fullscreen
- `P` — open browser print dialog
- Click on dots in nav bar — jump to slide
- URL hash `#3` — deep-link to slide 3

## Build workflow

1. Read `references/template.html` to get the scaffold.
2. Identify how many slides the user wants. Default to 8-10.
3. For each slide, decide which pattern fits (cover for slide 1, plan for last slide, table for detailed reference content, etc.).
4. Write the file to the user's preferred path (default: `/Users/nicolasbertrand/Documents/<topic>-deck.html`).
5. Run the anti-slop grep.
6. `open` the file.
7. Report: file path, slide count, patterns used, word count per slide.

## Customization

**Brand colors** — change the `:root` OKLCH tokens at the top of the CSS. Default is navy/yellow/terra (Theodo HealthTech). For other brands, swap `--navy`, `--yellow`, `--terra` to match. Keep OKLCH for consistent perceptual lightness.

**Fonts** — current is Manrope + Public Sans + JetBrains Mono via Google Fonts. Swap the `<link>` and the `--display/--body/--mono` variables if a different family is needed.

**Aspect ratio** — `.slide` uses `aspect-ratio: 16 / 9`. For 4:3 decks, change to `4 / 3` and adjust the fullscreen math in JS (`* 9 / 16` → `* 3 / 4`, `/ 720 * 17` → `/ 960 * 17`).

**Number of slides** — no hard limit. Navigation auto-counts.

## References

- `references/template.html` — full HTML scaffold with one worked example of each of the six patterns, inline comments above each, plus all CSS, navigation JS, fullscreen scaling, and print stylesheet. Load when starting a new deck.
