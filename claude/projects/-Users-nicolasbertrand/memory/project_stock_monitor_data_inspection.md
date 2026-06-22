---
name: project-stock-monitor-data-inspection
description: stock-monitor — local dev.db is stale (pre-currency schema); prod DB reads via fly ssh need explicit user approval
metadata: 
  node_type: memory
  type: project
  originSessionId: 5f6387f7-8900-4acd-9461-7f9c27e96fd2
---

In `~/stock-monitor` ("StockPulse"), the local `dev.db` is stale: it predates the `Stock.currency` column and does not mirror prod data. Never use it as a data reference.

**Why:** Real data lives only in `/data/prod.db` on Fly. Reading it via `fly ssh console` is classified as a Production Read and requires the user to explicitly approve, naming the prod target.

**How to apply:** To reason about prod data, rely on code evidence (CLAUDE.md architecture notes, code comments like the AXSM closed-trade one) or ask the user to approve a read-only `fly ssh console` query. Realized P&L EUR values are frozen per transaction in `Transaction.priceEur` since June 2026 (commit fcd8f66); a boot-time healer backfills missing rows with date-accurate rates.
