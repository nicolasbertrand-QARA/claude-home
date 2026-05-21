# MDSW Compliance Assessment Tool

## Context

Theodo HealthTech's 2026 Hoshin includes transforming the QMS into a scalable compliance platform. This tool is the first step: an AI-powered compliance assessment engine that checks QMS and technical documentation against the full EU MDSW regulatory corpus (~90 documents in `~/Documents/Normes/`). It identifies non-conformities, grades them, proposes remediations, and can generate a corrected document version.

**Project location:** `~/mdsw-compliance-tool`

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 15 (App Router, TypeScript) |
| Styling | Tailwind CSS 4 + Theodo HealthTech design tokens |
| AI SDK | Vercel AI SDK (`ai`) + Anthropic SDK |
| LLM | Claude Sonnet 4 (section analysis) / Opus for consolidation |
| Vector DB | SQLite + `sqlite-vec` (local, zero infrastructure) |
| Embeddings | Voyage AI `voyage-3-large` (one-time indexing) |
| PDF extraction (indexing) | Python `pymupdf4llm` + Tesseract (for 8 scanned PDFs) |
| PDF extraction (runtime) | `unpdf` (Node, for uploaded docs) |
| DOCX extraction | `mammoth` |
| State management | Zustand |
| File upload | `react-dropzone` |
| Language | English (UI + analysis) |

---

## Architecture Overview

### Knowledge Base (one-time preprocessing)

```
~/Documents/Normes/ (90 docs, 142MB)
    |
    v
Python: pymupdf4llm + Tesseract OCR
    |-- Text extraction (handles both text-based and scanned PDFs)
    |-- Output: Markdown with clause structure preserved
    |
    v
Node: Clause-aware chunking
    |-- Split at clause/article/section level (not arbitrary token windows)
    |-- Each chunk includes: full clause path, requirement text, SHALL/should marker
    |-- Metadata: standard_id, clause_id, requirement_type, topic_tags
    |-- Target: 500-800 tokens per chunk + parent context
    |
    v
Voyage AI: Embed chunks -> SQLite-vec
    |-- ~5,000 chunks, ~20MB index
    |-- Stored in data/standards.db (gitignored)
```

### Assessment Pipeline (5 stages, per document upload)

```
Stage 1: Document Classification (1 Claude call)
  -> Identify doc type, applicable standards, sections, safety class

Stage 2: Requirements Retrieval (vector search, no Claude call)
  -> Query sqlite-vec for relevant standard clauses per topic area
  -> Retrieve 50-150 chunks, filtered by requirement_type

Stage 3: Section-by-Section Analysis (N parallel Claude calls)
  -> Each section assessed against its relevant standard requirements
  -> Output: structured findings (NC/OFI) with severity, clause ref, remediation
  -> Streamed to frontend as they complete

Stage 4: Cross-Section Consolidation (1 Claude call)
  -> Detect document-level gaps, deduplicate, normalize severity

Stage 5: Summary Generation (1 Claude call)
  -> Executive summary, statistics, priority-ordered remediation plan
```

### NC/OFI Grading System

| Type | Severity | Criteria |
|------|----------|----------|
| NC | Critical | Missing/fundamentally inadequate implementation of a SHALL requirement that directly impacts patient safety or regulatory compliance |
| NC | Major | Requirement partially addressed with significant gaps that a notified body would flag |
| NC | Minor | Requirement addressed with minor deviations, incomplete details, or reference issues |
| OFI | — | Meets mandatory requirements but could improve per SHOULD recommendations, MDCG best practices, or industry standards |

### "Fix My Document" (format-preserving output)

The remediated document is produced **in the same format as the input**:

| Input Format | Output Strategy | Library |
|-------------|----------------|---------|
| DOCX | Parse with `python-docx`, apply remediations in-place, re-export DOCX with changes highlighted | `python-docx` (Python sidecar) |
| PDF | Extract content, apply remediations, generate new PDF with corrected content and matching structure | `puppeteer` (HTML->PDF) or `pdfmake` |
| Markdown | Direct text modification, output `.md` | Native string ops |
| HTML | Parse DOM, apply remediations, re-export | `cheerio` |

Additionally, a **Remediation Report** is always generated alongside the fixed document, showing before/after for each finding with clause references.

---

## Design System (Theodo HealthTech)

Extracted from existing `sop_to_theodo.py` brand tooling:

```
Navy:       #12305D (primary)
Gold:       #FFC800 (accent/status)
Orange:     #FF512C (CTA/highlights)
Mid-blue:   #294F73 (secondary)
Darkest:    #1D2939 (text primary)
Grey-500:   #6B7280 (text secondary)
Surfaces:   #FFFFFF / #F8F9FA / #F3F4F6
Border:     #E5E7EB
Font:       Poppins (system-ui fallback)

Finding severity colors:
  Critical:  #DC2626 on #FEF2F2
  Major:     #EA580C on #FFF7ED
  Minor:     #CA8A04 on #FEFCE8
  OFI:       #2563EB on #EFF6FF
```

Logo assets from `~/Downloads/`:
- `logoTheodoHealthTech.png` (compact)
- `Theodo HealthTech Wordmark Positive.png` (full)
- `Theodo HealthTech Favicon.png` (favicon)

---

## Project Structure

```
mdsw-compliance-tool/
├── app/
│   ├── layout.tsx                    # Root layout, branding, Poppins
│   ├── page.tsx                      # Landing page with upload zone
│   ├── assess/
│   │   └── page.tsx                  # Assessment results (streaming)
│   └── api/
│       ├── upload/route.ts           # File upload handling
│       ├── assess/route.ts           # Pipeline orchestrator (streaming)
│       ├── remediate/route.ts        # Doc remediation endpoint
│       └── standards/status/route.ts # KB status
├── components/
│   ├── ui/                           # Button, Badge, Card, ProgressBar, Skeleton
│   ├── upload/                       # UploadZone, FileList
│   ├── assessment/                   # SummaryDashboard, MetricCard, ComplianceScore,
│   │                                 # FindingsToolbar, FindingsList, FindingCard,
│   │                                 # RemediationPanel, AssessmentProgress, StageIndicator
│   └── layout/                       # Navbar, Footer
├── lib/
│   ├── ai/                           # client, prompts, schemas, pipeline stages
│   ├── documents/                    # extract-pdf, extract-docx, chunker
│   ├── knowledge-base/               # db, search, types
│   └── remediation/                  # generate, format-preserving output (DOCX/PDF/MD)
├── store/
│   └── assessment.ts                 # Zustand store
├── scripts/                          # Python + Node preprocessing
│   ├── index-standards.py            # Main indexing orchestrator
│   ├── extract-text.py               # PDF/OCR extraction
│   ├── chunk-standards.ts            # Clause-aware chunking
│   ├── generate-embeddings.ts        # Voyage AI embeddings
│   └── build-manifest.ts             # Standards inventory
├── data/
│   ├── standards.db                  # SQLite + vectors (gitignored)
│   └── standards-manifest.json       # Document inventory
├── public/                           # Logos, favicon
├── tailwind.config.ts
├── next.config.ts
├── .env.local                        # ANTHROPIC_API_KEY, VOYAGEAI_API_KEY
└── package.json
```

---

## Implementation Phases

### Phase 1: Project Setup & Knowledge Base
1. Initialize Next.js 15 project with TypeScript, Tailwind, Poppins font
2. Set up Python env: `pip install pymupdf4llm pytesseract`, `brew install tesseract tesseract-lang`
3. Write `build-manifest.ts` — inventory & deduplicate standards (target ~55 unique docs)
4. Write `extract-text.py` — extract text from all PDFs (OCR for 8 scanned ones)
5. Write `chunk-standards.ts` — clause-aware hierarchical chunking with metadata
6. Write `generate-embeddings.ts` — Voyage AI embeddings -> SQLite-vec
7. Validate: test queries return correct clauses

**Critical reference files:**
- `~/Documents/Normes/62304 Medical Devices Software - Software Life Cycle Processes.pdf` (extractable base edition, 60K words)
- `~/Documents/Normes/MDCG/mdcg_2019_11 rev 1_en.pdf` (clean extraction, good chunking test)
- `~/Documents/Normes/Templates (NOT FOR YOU CLAUDE CODE)/sop_to_theodo.py` (brand CSS)

### Phase 2: Assessment Engine
1. Set up Anthropic SDK + Vercel AI SDK
2. Define Zod schemas for structured finding output
3. Implement Stage 1: Document classification & scoping
4. Implement Stage 2: Vector retrieval with topic-aware filtering
5. Implement Stage 3: Section-by-section analysis with streaming
6. Implement Stage 4: Cross-section consolidation
7. Implement Stage 5: Summary generation
8. Write system prompts with severity calibration examples and grounding instructions
9. Test with existing SOP: `~/Documents/Normes/Templates (NOT FOR YOU CLAUDE CODE)/SOP-CC-MDSW-EU.md`

### Phase 3: Frontend
1. Build Navbar with Theodo HealthTech branding + logo
2. Build landing page with Hero section and UploadZone (drag-and-drop)
3. Build assessment results page:
   - SummaryDashboard with MetricCards (Critical/Major/Minor/OFI counts + ComplianceScore gauge)
   - FindingsToolbar (severity filter, standard filter, search, sort)
   - FindingsList with FindingCards (streaming — findings appear as analysis progresses)
   - RemediationPanel (expandable per finding)
4. Build AssessmentProgress overlay (stage stepper + section progress bar)
5. Loading states with skeleton placeholders
6. Wire API routes to frontend with Vercel AI SDK hooks

### Phase 4: Remediation & Polish
1. Implement format-preserving remediation engine:
   - DOCX: Python sidecar using `python-docx` for in-place editing with highlighted changes
   - PDF: Generate corrected PDF via `puppeteer` (HTML->PDF) or `pdfmake`
   - Markdown/HTML: Direct text modification
2. Generate remediation report (before/after per finding) alongside every fixed document
3. Implement "Fix My Document" button — detects input format, returns same format
4. Polish animations, transitions, edge cases
5. Test end-to-end with multiple document types and formats

---

## Key Design Decisions

1. **SQLite-vec over cloud vector DB** — ~5K chunks is trivially small; zero infrastructure overhead
2. **Clause-aware chunking over token-window chunking** — regulatory standards have hierarchical clause structure; generic chunking destroys clause references
3. **Sonnet for analysis, Opus optional for consolidation** — 5x cost savings on the N parallel calls; Sonnet handles structured extraction well
4. **Streaming findings over batch response** — assessment takes 30-90s; progressive UI prevents perceived waiting
5. **Strict grounding prompts** — Claude must only cite requirements from retrieved excerpts; prevents hallucinated clause numbers
6. **Format-preserving remediation** — output matches input format (DOCX->DOCX, PDF->PDF, MD->MD); DOCX via `python-docx`, PDF via HTML->PDF conversion, always accompanied by a remediation report

---

## Verification Plan

1. **Knowledge base**: Query "What does IEC 62304 require for software requirements?" — should return clause 5.2 chunks with correct SHALL markers
2. **Assessment pipeline**: Upload `SOP-CC-MDSW-EU.md` — should identify applicable standards (IEC 62304, ISO 13485, ISO 14971), find real NCs/OFIs with valid clause references
3. **Grading consistency**: Run same document twice — severity grades should be consistent
4. **False positive check**: Upload a risk management SOP — should NOT flag usability engineering gaps as NCs
5. **Streaming**: Findings should appear progressively in the UI during analysis
6. **Remediation**: Upload a DOCX -> "Fix My Document" returns a DOCX; upload a PDF -> returns a PDF. Both address all Critical and Major NCs. A remediation report is generated alongside.
7. **Visual**: UI matches Theodo HealthTech brand — navy/gold palette, Poppins font, logo placement
