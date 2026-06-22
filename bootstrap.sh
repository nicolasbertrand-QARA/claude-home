#!/usr/bin/env bash
# Bootstrap a new machine by symlinking tracked artifacts from this repo
# into the expected locations. Idempotent: backs up any pre-existing target
# to <target>.bootstrap-backup-<timestamp> before linking.
#
# Usage: ./bootstrap.sh [--dry-run]

set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
HOSTNAME_TAG="-Users-$(whoami)"

log() { printf '[bootstrap] %s\n' "$*"; }
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

link() {
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    log "SKIP (source missing): $src"
    return
  fi
  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      log "OK     $dst -> $src"
      return
    fi
    log "RELINK $dst (was -> $current)"
    run "rm '$dst'"
  elif [ -e "$dst" ]; then
    local backup="${dst}.bootstrap-backup-${TIMESTAMP}"
    log "BACKUP $dst -> $backup"
    run "mv '$dst' '$backup'"
  fi
  run "mkdir -p '$(dirname "$dst")'"
  run "ln -s '$src' '$dst'"
  log "LINK   $dst -> $src"
}

# Home-level
link "$REPO_DIR/home/CLAUDE.md" "$HOME/CLAUDE.md"

# ~/.claude single files
link "$REPO_DIR/claude/settings.json"               "$HOME/.claude/settings.json"
link "$REPO_DIR/claude/run_stock_newsletter.sh"     "$HOME/.claude/run_stock_newsletter.sh"
link "$REPO_DIR/claude/stock_newsletter_prompt.txt" "$HOME/.claude/stock_newsletter_prompt.txt"

# ~/.claude directories
link "$REPO_DIR/claude/skills"                "$HOME/.claude/skills"
link "$REPO_DIR/claude/hooks"                 "$HOME/.claude/hooks"
link "$REPO_DIR/claude/scripts"               "$HOME/.claude/scripts"
link "$REPO_DIR/claude/plans"                 "$HOME/.claude/plans"
link "$REPO_DIR/claude/regulatory-watch"      "$HOME/.claude/regulatory-watch"
link "$REPO_DIR/claude/local-marketplaces"    "$HOME/.claude/local-marketplaces"

# Memory: project dir is keyed off working directory. If the new machine has a
# different username, this path differs. Symlink the memory subdir into whatever
# project key matches the current user.
PROJECT_DIR="$HOME/.claude/projects/$HOSTNAME_TAG"
run "mkdir -p '$PROJECT_DIR'"
link "$REPO_DIR/claude/projects/-Users-nicolasbertrand/memory" "$PROJECT_DIR/memory"

# launchd scheduled jobs. Plists are COPIED (not symlinked: launchd resolves and
# may reject symlinked agents) and then loaded. The scripts they invoke live under
# ~/.claude/ and are symlinked above, so the plist paths stay valid.
LAUNCH_DIR="$HOME/Library/LaunchAgents"
run "mkdir -p '$LAUNCH_DIR'"
if [ -d "$REPO_DIR/launchd" ]; then
  for plist in "$REPO_DIR"/launchd/*.plist; do
    [ -e "$plist" ] || continue
    name="$(basename "$plist")"
    log "LAUNCHD copy $name -> $LAUNCH_DIR/"
    run "cp '$plist' '$LAUNCH_DIR/$name'"
    run "launchctl unload '$LAUNCH_DIR/$name' 2>/dev/null || true"
    run "launchctl load '$LAUNCH_DIR/$name'"
  done
fi

cat <<'EOF'

[bootstrap] Done. Next manual steps:
  1. Restore secrets from 1Password:
     - ~/.claude/stockpulse.env
     - Apple notary profile (xcrun notarytool store-credentials laserdash-notary ...)
  2. Reinstall plugins (see claude/manifests/installed_plugins.json):
       claude plugin install swift-lsp
       claude plugin add-marketplace ~/.claude/local-marketplaces/theodo-ans
       claude plugin install theodo-ans-gap-analysis
  3. Reconnect MCP connectors on claude.ai web (Notion, Drive, Superhuman)
  4. Scheduled jobs now run via launchd (plists copied + loaded above). Verify:
       launchctl list | grep -E 'nicolasbertrand|theodo'
     (crontab.txt is retained only for historical reference; cron is no longer used.)
  5. Clone Normes:       git clone git@github.com:nicolasbertrand-QARA/qara-normes-library.git ~/qara-normes-library
                         ln -s ~/qara-normes-library ~/Documents/Normes
  6. Clone regulatory-watch repo:
       git clone https://github.com/nicolasbertrand-QARA/Compliance-timeline.git ~/.claude/regulatory-watch/repo
  7. Rotate previously-leaked tokens (Slack/Fly/Gemini) if not already done.
EOF
