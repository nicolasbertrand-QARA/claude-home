#!/bin/bash
# Weekly Stock Picks Newsletter — runs every Monday at 8:03 AM
#
# Architecture (v2, 2026-05-21): Claude does research + writes HTML; this script
# delivers the email via SMTP (swaks). OAuth-free, so the recurring
# `invalid_rapt` failure mode that plagued the gws-based version is gone.
#
# Failure surfacing: pre-checks both Claude auth AND SMTP auth BEFORE the long
# research run. On any failure (pre-check, Claude exit, HTML missing, SMTP send),
# fires a macOS notification AND exits non-zero so cron logs a real error.

set -uo pipefail

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/stock_newsletter_$(date '+%Y-%m-%d_%H%M').log"
HTML_FILE="/tmp/stock_newsletter.html"

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Load StockPulse + SMTP credentials
source "$HOME/.claude/stockpulse.env"
export ADMIN_SECRET STOCKPULSE_URL
export SMTP_HOST SMTP_PORT SMTP_USER SMTP_APP_PASSWORD EMAIL_FROM EMAIL_TO

log()    { printf '%s\n' "$*" | tee -a "$LOG_FILE"; }
notify() {
  local title="$1" msg="$2"
  /usr/bin/osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null || true
}
fail() {
  local stage="$1" msg="$2"
  log "FAIL [$stage] $msg"
  notify "StockPulse newsletter failed" "$stage — see ${LOG_FILE##*/}"
  exit 1
}

log "=== Stock Newsletter Run: $(date) ==="

# ─── Pre-check 1: required env vars present ──────────────────────────────────
for v in ADMIN_SECRET STOCKPULSE_URL SMTP_HOST SMTP_PORT SMTP_USER SMTP_APP_PASSWORD EMAIL_FROM EMAIL_TO; do
  if [ -z "${!v:-}" ]; then
    fail "env" "Missing required variable: $v (check ~/.claude/stockpulse.env)"
  fi
done
if [ "$SMTP_APP_PASSWORD" = "REPLACE_WITH_16_CHAR_APP_PASSWORD" ]; then
  fail "env" "SMTP_APP_PASSWORD still placeholder. Generate one at https://myaccount.google.com/apppasswords and update ~/.claude/stockpulse.env"
fi

# ─── Pre-check 2: claude CLI is logged in ────────────────────────────────────
AUTH_CHECK=$(/opt/homebrew/bin/claude -p "say OK" --model haiku 2>&1)
if echo "$AUTH_CHECK" | grep -qiE "not logged in|please run /login"; then
  log "$AUTH_CHECK"
  fail "claude-auth" "claude CLI not logged in. Open a terminal and run: claude  then  /login"
fi

# ─── Pre-check 3: SMTP auth works (no email sent, just AUTH then QUIT) ───────
# swaks --auth ... --quit-after AUTH: EHLO, STARTTLS, AUTH, then QUIT. If creds
# are bad (or app passwords disabled at the Workspace level), this exits non-zero.
SMTP_CHECK=$(/opt/homebrew/bin/swaks \
  --to "$EMAIL_TO" \
  --from "$EMAIL_FROM" \
  --server "$SMTP_HOST" \
  --port "$SMTP_PORT" \
  --auth LOGIN \
  --auth-user "$SMTP_USER" \
  --auth-password "$SMTP_APP_PASSWORD" \
  --tls \
  --quit-after AUTH \
  --hide-all 2>&1)
SMTP_CHECK_EXIT=$?
if [ $SMTP_CHECK_EXIT -ne 0 ]; then
  log "swaks pre-check output:"
  log "$SMTP_CHECK"
  fail "smtp-auth" "SMTP authentication failed (exit $SMTP_CHECK_EXIT). Likely causes: bad app password, 2FA not enabled, App Passwords disabled by Workspace admin."
fi
log "Pre-checks passed (claude auth + SMTP auth OK)"

# ─── Run Claude: research + HTML generation + portfolio update ───────────────
# Cleanup any stale HTML from prior runs so a missing file means Claude failed.
rm -f "$HTML_FILE"
log "Starting Claude research run..."

/opt/homebrew/bin/claude -p \
  "$(cat "$HOME/.claude/stock_newsletter_prompt.txt")" \
  --model opus \
  --effort max \
  --allowedTools "WebSearch,WebFetch,Bash,Write,Read,Edit,Grep,Glob" \
  --dangerously-skip-permissions \
  >> "$LOG_FILE" 2>&1
CLAUDE_EXIT=$?
log "Claude run finished (exit $CLAUDE_EXIT)"
if [ $CLAUDE_EXIT -ne 0 ]; then
  fail "claude-run" "claude CLI exited non-zero ($CLAUDE_EXIT). See log for details."
fi

# ─── Validate the HTML output ────────────────────────────────────────────────
if [ ! -f "$HTML_FILE" ]; then
  fail "html-missing" "Claude finished but $HTML_FILE was not written"
fi
HTML_SIZE=$(wc -c < "$HTML_FILE")
if [ "$HTML_SIZE" -lt 5000 ]; then
  fail "html-too-small" "$HTML_FILE is only $HTML_SIZE bytes (expected >5KB). Likely truncated."
fi
log "HTML file OK: $HTML_FILE ($HTML_SIZE bytes)"

# ─── Send the email via swaks ────────────────────────────────────────────────
SUBJECT="Stock Picks Weekly - $(date '+%d %b %Y')"
SEND_OUTPUT=$(/opt/homebrew/bin/swaks \
  --to "$EMAIL_TO" \
  --from "$EMAIL_FROM" \
  --server "$SMTP_HOST" \
  --port "$SMTP_PORT" \
  --auth LOGIN \
  --auth-user "$SMTP_USER" \
  --auth-password "$SMTP_APP_PASSWORD" \
  --tls \
  --header "Subject: $SUBJECT" \
  --header "Content-Type: text/html; charset=UTF-8" \
  --body @"$HTML_FILE" \
  --hide-all 2>&1)
SEND_EXIT=$?
if [ $SEND_EXIT -ne 0 ]; then
  log "swaks send output:"
  log "$SEND_OUTPUT"
  fail "smtp-send" "Email send failed (exit $SEND_EXIT). HTML is preserved at $HTML_FILE."
fi

log "=== Newsletter delivered to $EMAIL_TO ($(date)) ==="
notify "StockPulse newsletter sent" "Delivered to $EMAIL_TO"
exit 0
