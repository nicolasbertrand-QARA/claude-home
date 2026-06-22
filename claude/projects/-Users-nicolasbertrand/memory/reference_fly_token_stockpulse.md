---
name: reference-fly-token-stockpulse
description: "Deploying stock-monitor to Fly requires sourcing the access token from ~/.fly/config.yml into FLY_ACCESS_TOKEN; `fly deploy` alone errors with \"no access token available\""
metadata: 
  node_type: memory
  type: reference
  originSessionId: 631de221-30f9-40d0-8255-ce874bb65013
---

To deploy stock-monitor (StockPulse) to Fly, the `fly` CLI does NOT pick up auth from `~/.fly/config.yml` automatically. Wrap the deploy command with:

```
export FLY_ACCESS_TOKEN="$(grep '^access_token:' ~/.fly/config.yml | awk '{print $2}')" && fly deploy -a stockpulse
```

Without the export the CLI errors with `Error: no access token available. Please login with 'flyctl auth login'`.

The CLAUDE.md in `/Users/nicolasbertrand/stock-monitor/` references `FLY_API_TOKEN` but that variable is NOT set in the shell — the token actually lives in `~/.fly/config.yml` under `access_token:`.

The deploy log will print `WARNING The app is not listening on the expected address` on every rolling restart. This is a benign snapshot-timing artefact: the smoke checks pass and live curls return real status codes. Ignore it unless `fly status` shows the machine unhealthy.
