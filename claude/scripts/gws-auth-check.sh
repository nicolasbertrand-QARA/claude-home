#!/bin/bash
# Daily GWS auth health check + auto-send any pending regulatory watch newsletter.
set -u

LOG=/Users/nicolasbertrand/.claude/scripts/gws-auth-check.log
WATCH_DIR=/Users/nicolasbertrand/Documents/regulatory-watch
ts() { date "+%Y-%m-%d %H:%M:%S"; }

# Step 1: probe auth with a cheap call
OUTPUT=$(/opt/homebrew/bin/gws gmail users messages list \
    --params '{"userId":"me","maxResults":1}' 2>&1)

if echo "$OUTPUT" | grep -qE 'authError|invalid_grant|invalid_rapt|reauth'; then
    echo "[$(ts)] EXPIRED — notifying user" >> "$LOG"
    /usr/bin/osascript -e 'display notification "Token expired. Open Terminal and run: gws auth login" with title "GWS auth — reauth required" subtitle "Newsletter will auto-send once renewed" sound name "Glass"'
    exit 1
fi

echo "[$(ts)] OK" >> "$LOG"

# Step 2: auth is OK — look for any pending unsent regulatory-watch newsletter and send it.
# Convention: a folder is "pending" if it contains send.py and email.html but no .sent marker.
if [ -d "$WATCH_DIR" ]; then
    for dir in "$WATCH_DIR"/*/; do
        [ -d "$dir" ] || continue
        if [ -f "$dir/send.py" ] && [ -f "$dir/email.html" ] && [ ! -f "$dir/.sent" ]; then
            echo "[$(ts)] Found pending newsletter at $dir, sending..." >> "$LOG"
            # Ensure /tmp staging dir exists (send.py reads from /tmp; copy from persistent source)
            staging_name=$(basename "$dir")
            staging="/tmp/regulatory-watch-${staging_name}"
            mkdir -p "$staging"
            cp "$dir/email.html" "$staging/email.html"
            if /usr/bin/python3 "$dir/send.py" >> "$LOG" 2>&1; then
                date "+sent at %Y-%m-%d %H:%M:%S" > "$dir/.sent"
                echo "[$(ts)] Sent $dir successfully" >> "$LOG"
                /usr/bin/osascript -e "display notification \"Newsletter $(basename $dir) sent\" with title \"Regulatory Watch\" sound name \"Glass\""
            else
                echo "[$(ts)] Send FAILED for $dir" >> "$LOG"
            fi
        fi
    done
fi

exit 0
