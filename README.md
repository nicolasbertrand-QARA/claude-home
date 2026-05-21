# claude-home

Personal backup of Claude Code configuration for nicolas.bertrand@theodo.com.
Mirrors `~/CLAUDE.md` and the tracked portions of `~/.claude/`.

## Layout

```
home/CLAUDE.md                       -> ~/CLAUDE.md
claude/settings.json                 -> ~/.claude/settings.json   (global, no secrets)
claude/skills/                       -> ~/.claude/skills/         (all skills)
claude/hooks/                        -> ~/.claude/hooks/
claude/scripts/                      -> ~/.claude/scripts/
claude/plans/                        -> ~/.claude/plans/
claude/regulatory-watch/             -> ~/.claude/regulatory-watch/  (prompt.md + run.sh only)
claude/projects/.../memory/          -> ~/.claude/projects/<host>/memory/
claude/local-marketplaces/theodo-ans -> ~/.claude/local-marketplaces/theodo-ans
claude/manifests/                    -> list of plugins and marketplaces to reinstall
claude/run_stock_newsletter.sh       -> ~/.claude/run_stock_newsletter.sh
claude/stock_newsletter_prompt.txt   -> ~/.claude/stock_newsletter_prompt.txt
crontab.txt                          -> current user's crontab dump
bootstrap.sh                         -> idempotent setup script for a new machine
```

## What is NOT in this repo (intentionally)

| Item | Reason | Recovery on new machine |
|---|---|---|
| `~/.claude/settings.local.json` | Contains live Slack/Fly/Gemini tokens inlined in permission strings | Will regenerate as you re-grant permissions |
| `~/.claude/stockpulse.env` | Live API secret | Restore from 1Password |
| `~/.claude/plugins/` payload | Reinstallable from marketplaces | `claude /plugin install ...` per `claude/manifests/installed_plugins.json` |
| `~/.claude/projects/<host>/` transcripts | 442 MB of conversation history | Not portable across Claude accounts |
| `~/.claude/regulatory-watch/repo/` | Nested git repo | `git clone https://github.com/nicolasbertrand-QARA/Compliance-timeline.git ~/.claude/regulatory-watch/repo` |
| `~/Documents/Normes/` | 142 MB of regulatory PDFs | Separate repo: `qara-normes-library` |
| Logs, caches, sessions, history.jsonl | Ephemeral runtime state | Regenerated automatically |

## Setup on a new machine

1. **Reinstall CLIs** before running bootstrap:
   ```
   brew install gh node python claude
   npm install -g @theodo/gws @notion-cli/notion
   ```
2. **Authenticate:**
   ```
   gh auth login                 # GitHub
   claude                        # then /login on first run
   gws auth login                # per Google account
   notion login                  # Notion CLI
   ```
3. **Clone and bootstrap:**
   ```
   git clone git@github.com:nicolasbertrand-QARA/claude-home.git ~/claude-home
   cd ~/claude-home && ./bootstrap.sh
   ```
4. **Restore secrets from 1Password:**
   - `~/.claude/stockpulse.env` (STOCKPULSE_URL, ADMIN_SECRET)
   - Apple notary profile `laserdash-notary` (re-import via `xcrun notarytool store-credentials`)
   - Slack token, Fly.io token, Gemini API key, Notion API key (re-export in shell or pass per-command)
5. **Reinstall plugins** listed in `claude/manifests/installed_plugins.json`:
   ```
   # Official Anthropic marketplace
   claude plugin install swift-lsp
   # Local theodo-ans marketplace (already symlinked into place by bootstrap)
   claude plugin add-marketplace ~/.claude/local-marketplaces/theodo-ans
   claude plugin install theodo-ans-gap-analysis
   ```
6. **Reconnect MCP integrations** on the new claude.ai account (web UI, Settings -> Connectors):
   - Notion
   - Google Drive
   - Superhuman Mail
7. **Restore crontab:**
   ```
   crontab ~/claude-home/crontab.txt
   ```
8. **Clone the Normes library** (separate repo):
   ```
   git clone git@github.com:nicolasbertrand-QARA/qara-normes-library.git ~/qara-normes-library
   ln -s ~/qara-normes-library ~/Documents/Normes
   ```
9. **Rotate the previously-leaked tokens** (Slack `xoxe.xoxp-1-...`, Fly.io `FlyV1 fm2_...`, Gemini `AIza...`) regardless of whether you're moving machines or not. They were sitting in `settings.local.json` and should be considered compromised.

## Updating the repo over time

The bootstrap script symlinks everything (it doesn't copy), so any change you make to `~/CLAUDE.md`, `~/.claude/skills/*/SKILL.md`, etc. is automatically reflected in the repo. Just `cd ~/claude-home && git add -A && git commit && git push` periodically.
