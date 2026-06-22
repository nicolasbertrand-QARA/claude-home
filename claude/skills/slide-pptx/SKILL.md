---
name: slide-pptx
description: Export an HTML slide deck (typically built with /slide) to PPTX. Two routes available; (1) image-based: each slide becomes a high-res PNG placed full-bleed on a 16:9 PPTX slide; visual fidelity 100%, text not editable; (2) native: text boxes, shapes, and tables in PPTX; editable but with font substitutions (Manrope→Poppins, Public Sans→Calibri, JetBrains Mono→Consolas) and OKLCH→sRGB color approximations. Use when the user mentions PPTX export, PowerPoint version of a deck, "convert this HTML to PPTX", "create a slidedeck.pptx", or asks for an editable PowerPoint.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Bash
argument-hint: "[path to HTML deck or topic]"
---

# Slide → PPTX

Take an HTML deck (built with `/slide` or otherwise) and produce a PPTX, in one of two routes. Both routes output a standard 16:9 (13.333 × 7.5 in) PowerPoint file readable by PowerPoint, Keynote, Google Slides, and LibreOffice.

## When to use

The user wants a PPTX file: client requested format, needs PowerPoint-native sharing, wants to present from Keynote, or needs Slides import. If the user is OK with PDF, use `/slide`'s built-in print and don't run this skill.

## Route choice (always ask before building)

| Route | Fidelity | Editability | File size | Build time | When |
|---|---|---|---|---|---|
| **Image-based** | 100% (Manrope, OKLCH, layout exact) | None (raster image per slide) | ~1.5-3 MB | 30 sec | Default for client deliverables. Slides become presentation-only screenshots. |
| **Native** | 80-85% (Poppins substitute, sRGB approx) | Full (text, shapes, tables editable) | ~50-80 KB | 1-2 min | When the client will edit, translate, or remix the slides. |

Default recommendation: **image-based**, unless editability is explicitly required. Memory note `feedback_no_slides_via_api.md` warns that native generation looks worse than the HTML source. Always disclose the trade-offs to the user before building.

## Prerequisites (one-time setup)

```bash
# 1. Chrome (macOS default path)
ls "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 2. Poppler for pdftoppm
brew install poppler

# 3. python-pptx in a venv (PEP 668 blocks global install)
python3 -m venv /tmp/pptx-venv
/tmp/pptx-venv/bin/pip install python-pptx

# 4. Poppins font (for native route only — Manrope substitute)
brew install --cask font-poppins
```

The `/tmp/pptx-venv` path is fine for repeated use; recreate if needed.

## Image-based route (recommended)

The fastest, highest-fidelity option. See `references/build_image.sh` for the complete script.

Pipeline:
1. **Copy HTML** and rewrite `@page` to `13.333in 7.5in` (true 16:9, not A4 landscape).
2. **Chrome headless print-to-PDF** with `--virtual-time-budget=5000` so Google Fonts load.
3. **pdftoppm** at 200 DPI produces one PNG per slide (2666 × 1500 px).
4. **python-pptx** creates a 13.333 × 7.5 in presentation, adds one blank slide per PNG, places picture full-bleed.
5. **Output** to `<basename>.pptx` next to the HTML.

Run:
```bash
bash ~/.claude/skills/slide-pptx/references/build_image.sh \
  /path/to/deck.html \
  /path/to/output.pptx
```

## Native route

Builds editable text boxes, shapes, and tables via python-pptx. See `references/build_native_template.py` for the full template.

The template provides:
- **Color tokens** (OKLCH → sRGB constants) — adjust if brand differs.
- **Font tokens** (DISPLAY/BODY/MONO) — swap if needed.
- **Helpers**: `add_strip`, `add_foot`, `add_block`, `add_text`, `add_table`, `bullet_list`, `numbered_list`, `flow_node`, `add_eyebrow`, `block_header`, `block_dark_header`, `add_kicker`.
- **6 worked patterns** (cover, cadre, comparatif, wide table, flow + sidebar, action plan) — copy the relevant ones and edit content.

Workflow:
1. Copy `build_native_template.py` to your working dir.
2. For each slide, copy the matching pattern block and replace the content (titles, bullets, table rows, etc.).
3. Run with the venv python: `/tmp/pptx-venv/bin/python build_native.py`.
4. Open the output to verify.

### Color tokens (defaults)

```python
PAPER       = RGBColor(0xFD, 0xFD, 0xFD)   # background
PAPER_SOFT  = RGBColor(0xF6, 0xF7, 0xFA)   # strip / foot fill
PAPER_WARM  = RGBColor(0xF7, 0xF2, 0xE2)   # warm block
NAVY        = RGBColor(0x1A, 0x1F, 0x3A)   # primary ink + dark block fill
INK_BODY    = RGBColor(0x35, 0x38, 0x4B)   # body text
INK_SOFT    = RGBColor(0x60, 0x63, 0x76)   # secondary text
INK_MUTE    = RGBColor(0x8B, 0x8D, 0x99)   # tertiary / mono labels
RULE        = RGBColor(0xD8, 0xD9, 0xDD)   # borders, table dividers
YELLOW      = RGBColor(0xEB, 0xC8, 0x45)   # accent dot, dark block bullets
YELLOW_DEEP = RGBColor(0xA8, 0x78, 0x10)   # eyebrow, accent text
YELLOW_SOFT = RGBColor(0xF6, 0xEC, 0xC8)   # hilite row in tables
TERRA       = RGBColor(0x96, 0x4A, 0x2E)   # terra accent (red-flag blocks)
TERRA_SOFT  = RGBColor(0xEF, 0xDB, 0xD0)   # terra block fill
GREEN       = RGBColor(0x4D, 0x76, 0x5E)   # green confirmation
WHITE       = RGBColor(0xFF, 0xFF, 0xFF)   # dark block text
```

These are sRGB approximations of the OKLCH palette in `/slide`. Lightness is approximately preserved but the perceptual uniformity is lost.

### Font tokens

```python
DISPLAY = 'Poppins'    # Manrope substitute (install via: brew install --cask font-poppins)
BODY    = 'Calibri'    # Public Sans substitute (default macOS / Windows)
MONO    = 'Consolas'   # JetBrains Mono substitute (default macOS / Windows)
```

### Layout dimensions

| Element | Inches |
|---|---|
| Slide | 13.333 × 7.5 (16:9) |
| Strip (top bar) | full width × 0.42 |
| Foot (bottom bar) | full width × 0.32 |
| Body padding (left/right) | 0.5 each side |
| Cover padding | 1.2 left, 1.2 top, etc. |
| Title h2 | size Pt(30) |
| Cover h1 | size Pt(92) |
| Kicker | size Pt(14) |
| Body text | size Pt(11) |
| Table body | size Pt(10) |
| Mono labels | size Pt(8-10) |
| Eyebrow | size Pt(10) mono uppercase |

### Block variants (matching `/slide`)

| Kind | Fill | Border | Header color | Bullet color |
|---|---|---|---|---|
| `default` | PAPER_SOFT | RULE | YELLOW_DEEP | NAVY |
| `warm` | PAPER_WARM | YELLOW | YELLOW_DEEP | NAVY |
| `dark` | NAVY | none | YELLOW | YELLOW (bullets) on WHITE text |
| `terra` | TERRA_SOFT | TERRA | TERRA | NAVY |

### Six worked patterns (in `build_native_template.py`)

1. **Cover** — Eyebrow + huge title (Pt 92) + lead + meta line at top + brand + reference at bottom.
2. **Two-block lead** — `h2` + kicker + 2-column body: left = sectioned bullets (h3 + ul), right = stacked blocks (dark + terra).
3. **Comparative** — Two `.block` cards side-by-side with colored left border (`add_rect` 0.06 in wide stripe) and inline key/value table.
4. **Wide table** — 9-12 row × 3 column table; ID column mono colored NAVY (or TERRA for hilite), Énoncé in BODY 10pt, Implication in 9pt INK_SOFT.
5. **Flow diagram + sidebar** — Left: backdrop block + rows of `flow_node` boxes connected by `→` text; node variants `default / k (navy fill, white text) / y (yellow soft fill) / t (terra soft fill)`. Right: stacked blocks (default + terra).
6. **Action plan** — Left: `numbered_list` (mono decimal-leading-zero 01-06). Right: dark block (livrables) + warm block (calendrier mini-table) + italic note.

## Tips and gotchas

- **Poppins metrics differ from Manrope** — titles may be slightly wider/narrower. Spot-check h2 wrapping on each slide after build.
- **Native tables don't have hover** — use `hilite_rows` parameter in `add_table` to set yellow background for emphasized rows (e.g. IEPS 9, IEU 7, IEU 9).
- **Bullets are inline `•` chars**, not native PowerPoint bullets. This preserves visual but loses auto-indent if users add lines manually.
- **OKLCH → sRGB drift**: yellow_deep, terra, and navy are close but slightly less saturated in sRGB. If the client compares the HTML and PPTX side by side, the PPTX will look mildly desaturated.
- **Flow diagram arrows** are text characters (`→`), not native connectors. If the client edits a node position, the arrow won't follow.
- **For French content**: ensure French quotes (« »), non-breaking spaces, and `‑` (U+2011) for hyphens that shouldn't break (e.g. `PGSSI‑S`).
- **No em dashes** (CLAUDE.md global rule) — replace with colons, parens, semicolons.
- **Verify font rendering**: open the PPTX after build. If Poppins isn't installed, install it first (`brew install --cask font-poppins`) and reopen.

## Upload to Drive (optional)

```bash
# Auth if expired (interactive, user runs this themselves)
# ! gws auth login

gws drive +upload /path/to/output.pptx           # to My Drive root
gws drive +upload /path/to/output.pptx --parent FOLDER_ID   # to specific folder
```

For ANS missions, the standard location is `Shared Drive Hokla > Projets > <client>` (see memory `reference_drive_ans_missions.md`). For personal Drive, omit `--parent`.

## References

- `references/build_image.sh` — Shell script for the image-based route. One command, 4 stages.
- `references/build_native_template.py` — Python template for the native route. Helpers + 6 worked patterns. Copy and adapt.
