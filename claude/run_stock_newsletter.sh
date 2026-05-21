#!/bin/bash
# Weekly Stock Picks Newsletter — runs every Monday at 8:03 AM
# Launches Claude Code (Opus 4.6) to research stocks, email the report,
# and update all portfolio analyses on StockPulse

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/stock_newsletter_$(date '+%Y-%m-%d_%H%M').log"

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Load StockPulse API credentials
source "$HOME/.claude/stockpulse.env"
export ADMIN_SECRET
export STOCKPULSE_URL

echo "=== Stock Newsletter Run: $(date) ===" >> "$LOG_FILE"

# Auth pre-check: confirm Claude Code is still logged in before kicking off the long research run.
AUTH_CHECK=$(/opt/homebrew/bin/claude -p "say OK" --model haiku 2>&1)
if echo "$AUTH_CHECK" | grep -qi "not logged in\|please run /login"; then
  echo "AUTH FAILED — claude CLI is not logged in. Aborting." >> "$LOG_FILE"
  echo "$AUTH_CHECK" >> "$LOG_FILE"
  /opt/homebrew/bin/gws gmail +send \
    --to nicolas.bertrand@ymail.com \
    --subject "⚠️ StockPulse newsletter skipped — claude not logged in" \
    --body "The weekly newsletter cron tried to run but the claude CLI is no longer logged in. Open a terminal, run \`claude\` then \`/login\` to re-authenticate, then re-run ~/.claude/run_stock_newsletter.sh manually if you want this week's email." \
    >> "$LOG_FILE" 2>&1
  echo "=== Aborted (auth) at $(date) ===" >> "$LOG_FILE"
  exit 2
fi

/opt/homebrew/bin/claude -p \
  "$(cat "$HOME/.claude/stock_newsletter_prompt.txt")" \
  --model opus \
  --effort max \
  --allowedTools "WebSearch,WebFetch,Bash,Write,Read,Edit,Grep,Glob" \
  --dangerously-skip-permissions \
  >> "$LOG_FILE" 2>&1

EXIT_CODE=$?
echo "=== Finished: $(date) | Exit code: $EXIT_CODE ===" >> "$LOG_FILE"
