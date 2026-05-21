# StockPulse — Complete UX & Visual Identity Overhaul

## Context

The current platform works functionally but the design is boring — corporate feel, no personality. The user wants it "hip, fun, the new cool kid on the block." This is a ground-up UX and visual redesign while keeping all existing functionality.

## Design Direction: "Electric Canvas"

A warm off-white canvas with deliberate pops of an electric coral/tangerine accent. High information density organized through bold typographic hierarchy rather than boxes and borders. Mostly quiet, with vivid intensity at the data points that matter.

---

## 1. Visual Identity

### Colors
| Token | Value | Purpose |
|-------|-------|---------|
| `--canvas` | `oklch(0.975 0.005 75)` | Warm off-white background |
| `--accent` | `oklch(0.65 0.24 30)` | Signature electric coral — NOT purple, NOT blue |
| `--gain` | `oklch(0.55 0.18 155)` | Rich teal-green |
| `--loss` | `oklch(0.58 0.2 18)` | Warm red |
| `--foreground` | `oklch(0.15 0.02 75)` | Warm near-black text |

### Typography
- **Headings:** Satoshi (Fontshare) — geometric, modern, confident
- **Body/data:** Geist Sans (already loaded, remove Helvetica override)
- **Prices:** Geist Mono — tabular figures for alignment

### Radius: `0.75rem` (softer, modern — not bubbly, not square)

---

## 2. Information Architecture — Restructured

### Merge Dashboard + Portfolio → single Home (`/`)
Current separation is redundant. One page with:
- **Hero:** Portfolio value (huge animated number) + daily change + inline sparkline
- **Stats row:** Invested, Value, P&L, Realized (borderless, on canvas)
- **Positions list:** Compact rows grouped by horizon (not cards, not tables)
- **Activity feed:** Collapsible recent transactions
- **Pending picks badge:** Floating indicator

### Recommendations → Picks (`/picks`) — card-by-card triage
- Pending: focused single-card review (one pick at a time, centered, large)
- Progress bar at top, keyboard shortcuts (A=approve, D=dismiss)
- Approved cards slide right (teal), dismissed slide left (fade)
- History: compact list with status

### Stock Detail → Slide-over panel (desktop) / full page (mobile)
- Clicking a position opens a right panel (60% width) over dimmed Home
- URL updates to `/stock/[ticker]` for direct links
- Chart, targets gauge, P&L, transactions inside panel

### Navigation: Kill the sidebar
- **Desktop:** Minimal 48px top bar — logo left, "Picks (3)" + logout right
- **Mobile:** Bottom tab bar with just 2 tabs (Home, Picks)
- Sidebar wasted 220px for 3 links — top bar reclaims that space

---

## 3. Five Distinctive Elements

### A. Animated Big Number
Portfolio value counts up from 0 on load using spring physics. Daily change fades in with color. Creates a "money is alive" feeling.

### B. Triage Card Stack (Picks)
One recommendation at a time, centered, large. Swipe right = invest, left = skip. Progress dots below. Game-like decision flow instead of overwhelming grid.

### C. Target Gauge
Horizontal progress bar showing stop loss ← current price → exit target. Instant visual read of position vs targets. Glows when targets hit.

### D. Animated Sparklines
SVG sparklines that draw themselves left-to-right on viewport entry. Expand on hover with tooltip.

### E. Freshness Dot
Breathing dot in top nav — teal when data fresh, amber when stale. Subtle ambient indicator that the app is alive.

---

## 4. Implementation Plan

### Phase 1: Foundation
- `globals.css` — New color system, radius, Satoshi font import, remove Helvetica override
- `layout.tsx` — Remove sidebar, add `<TopNav>`, full-width main
- New `components/layout/top-nav.tsx` — Replace sidebar-nav.tsx
- Delete `components/layout/sidebar-nav.tsx`

### Phase 2: Home Page (merge dashboard + portfolio)
- `page.tsx` — Transform from redirect into full home page (merge data fetching from both)
- New `components/home/hero-value.tsx` — Animated portfolio value
- New `components/home/stats-row.tsx` — Borderless stat blocks
- New `components/home/positions-list.tsx` — Compact grouped list with sparklines + P&L bars
- New `components/home/activity-feed.tsx` — Collapsible transactions
- Redirect `/dashboard` and `/portfolio` to `/`

### Phase 3: Stock Detail Panel
- New `components/stock-detail/panel.tsx` — Slide-over wrapper (desktop)
- New `components/stock-detail/target-gauge.tsx` — Visual target indicator
- New `components/stock-detail/content.tsx` — Shared content (chart, stats, txns)
- Keep `app/stock/[ticker]/page.tsx` for mobile/direct links

### Phase 4: Picks Triage
- New `app/picks/page.tsx` — Rename from recommendations
- New `components/picks/card-stack.tsx` — Swipe/keyboard card deck
- New `components/picks/pick-card.tsx` — Single focused recommendation card
- New `components/picks/history-list.tsx` — Reviewed picks list
- Redirect `/recommendations` to `/picks`

### Phase 5: Polish
- CSS animations: sparkline draw-in, count-up, card transitions
- `components/ui/freshness-indicator.tsx` — Breathing status dot
- Restyle `/login` page
- Micro-interactions: hover states, focus rings, transitions

### Phase 6: Mobile
- 2-tab bottom bar (Home, Picks)
- Stock detail as full-page push navigation
- Touch swipe gestures for pick triage
- Compact number formatting (€41.2k)

---

## Files Changed/Created

**Delete:** `sidebar-nav.tsx`
**Rewrite:** `globals.css`, `layout.tsx`, `page.tsx`, `login/page.tsx`
**New:** `top-nav.tsx`, `hero-value.tsx`, `stats-row.tsx`, `positions-list.tsx`, `activity-feed.tsx`, `panel.tsx`, `target-gauge.tsx`, `content.tsx`, `card-stack.tsx`, `pick-card.tsx`, `history-list.tsx`, `freshness-indicator.tsx`
**Redirect:** `/dashboard` → `/`, `/portfolio` → `/`, `/recommendations` → `/picks`

## Verification
1. Home page loads with animated value, positions list, stats
2. Click a position → slide-over panel opens on desktop, full page on mobile
3. Navigate to Picks → card-by-card triage with approve/dismiss
4. All existing data (portfolio, transactions, recommendations) preserved
5. Mobile: 2-tab bottom nav, swipe to triage, full-page stock detail
6. Deploy to Fly.io, test on phone
