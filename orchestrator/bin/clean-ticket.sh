#!/usr/bin/env bash
# Strip runtime frontmatter (status / started_at / finished_at / duration_s /
# exit_code / failure_reason / log_path) from a ticket file in place. Useful
# before redispatching a ticket from done/ or failed/ back to pending.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

TID=${1:?usage: clean-ticket.sh <ticket_id>}
TICKET=$(ticket_locate "$TID") || die "ticket not found: $TID"

tmp=$(mktemp)
grep -v -E '^(status|started_at|finished_at|duration_s|exit_code|failure_reason|log_path):' \
  "$TICKET" > "$tmp"
mv "$tmp" "$TICKET"
log "cleaned $TID ($(realpath --relative-to="$REPO_ROOT" "$TICKET"))"
