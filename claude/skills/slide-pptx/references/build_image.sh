#!/usr/bin/env bash
# Image-based HTML → PPTX pipeline.
# Each slide of the HTML deck becomes a high-resolution PNG placed full-bleed
# on a 16:9 PowerPoint slide. Visual fidelity 100%, text not editable.
#
# Usage:
#   bash build_image.sh <input.html> <output.pptx>
#
# Prerequisites (one-time):
#   - Google Chrome at /Applications/Google Chrome.app
#   - poppler:   brew install poppler
#   - python-pptx in venv:
#       python3 -m venv /tmp/pptx-venv
#       /tmp/pptx-venv/bin/pip install python-pptx
#
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <input.html> <output.pptx>" >&2
  exit 1
fi

INPUT_HTML="$1"
OUTPUT_PPTX="$2"

if [ ! -f "$INPUT_HTML" ]; then
  echo "Error: input HTML not found: $INPUT_HTML" >&2
  exit 1
fi

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
VENV_PY="/tmp/pptx-venv/bin/python"

if [ ! -x "$CHROME" ]; then
  echo "Error: Chrome not found at expected path: $CHROME" >&2
  exit 1
fi
if [ ! -x "$VENV_PY" ]; then
  echo "Error: python-pptx venv not found at $VENV_PY" >&2
  echo "Create it with:" >&2
  echo "  python3 -m venv /tmp/pptx-venv" >&2
  echo "  /tmp/pptx-venv/bin/pip install python-pptx" >&2
  exit 1
fi
if ! command -v pdftoppm >/dev/null 2>&1; then
  echo "Error: pdftoppm not found. Install with: brew install poppler" >&2
  exit 1
fi

WORK="$(mktemp -d -t pptx-build-XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

echo "[1/4] Preparing HTML with 16:9 page size..."
cp "$INPUT_HTML" "$WORK/deck-print.html"
# Force @page to 13.333in x 7.5in (true 16:9), regardless of existing @page rule.
# Replace common variants.
sed -i '' -E \
  -e 's/@page \{[^}]*size:[^;]*;[^}]*margin:[^;}]*;[^}]*\}/@page { size: 13.333in 7.5in; margin: 0; }/' \
  -e 's/@page \{ size: A4 landscape; margin: 0; \}/@page { size: 13.333in 7.5in; margin: 0; }/' \
  "$WORK/deck-print.html"

echo "[2/4] Rendering HTML to PDF via Chrome headless..."
"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$WORK/deck.pdf" \
  --virtual-time-budget=5000 \
  "file://$WORK/deck-print.html" 2>&1 | grep -v "^$" || true

if [ ! -f "$WORK/deck.pdf" ]; then
  echo "Error: PDF not generated" >&2
  exit 1
fi

echo "[3/4] Converting PDF pages to PNGs at 200 DPI..."
pdftoppm -png -r 200 "$WORK/deck.pdf" "$WORK/slide" 2>&1 | grep -v "Bad bounding box" || true

PNG_COUNT=$(ls "$WORK"/slide-*.png 2>/dev/null | wc -l | tr -d ' ')
if [ "$PNG_COUNT" -eq 0 ]; then
  echo "Error: no PNGs generated from PDF" >&2
  exit 1
fi
echo "      -> $PNG_COUNT PNG(s) generated"

echo "[4/4] Building PPTX with python-pptx..."
"$VENV_PY" <<PYEOF
import glob, os
from pptx import Presentation
from pptx.util import Inches

prs = Presentation()
prs.slide_width  = Inches(13.333)
prs.slide_height = Inches(7.5)
blank = prs.slide_layouts[6]

pngs = sorted(glob.glob("$WORK/slide-*.png"))
for png in pngs:
    slide = prs.slides.add_slide(blank)
    slide.shapes.add_picture(png, 0, 0, width=prs.slide_width, height=prs.slide_height)

out = "$OUTPUT_PPTX"
prs.save(out)
print(f"      -> {out} ({os.path.getsize(out)} bytes, {len(pngs)} slides)")
PYEOF

echo "Done."
