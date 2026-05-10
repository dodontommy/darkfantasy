#!/usr/bin/env bash
# Send a ticket to a tmux worker window.
#
# Usage: dispatch.sh <ticket_id> [<window_name>]
#   If <window_name> is omitted, picks the first idle window matching the ticket's worker_class.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

TID=${1:?usage: dispatch.sh <ticket_id> [window]}
WIN=${2:-}

TICKET=$(ticket_locate "$TID") || die "ticket not found: $TID"
case "$TICKET" in
  *queue/pending/*) ;;
  *queue/in_progress/*) log "ticket already in_progress; redispatching" ;;
  *) die "ticket is in done/failed, not dispatchable: $TICKET" ;;
esac

WC=$(fm_get "$TICKET" worker_class)
[[ -n "$WC" ]] || die "ticket missing worker_class: $TICKET"

if [[ -z "$WIN" ]]; then
  case "$WC" in
    copilot)     WIN="worker-cop-1" ;;
    cursor)      WIN="worker-cur-1" ;;
    cursor-mcp)  WIN="worker-mcp-1" ;;
    cursor-ask)  WIN="worker-cur-1" ;;
    shell)       WIN="worker-cur-1" ;;
    *) die "unknown worker_class for default window: $WC" ;;
  esac
fi

if ! tmux has-session -t darkfantasy 2>/dev/null; then
  die "no tmux session 'darkfantasy'. Run: orchestrator/bin/bootstrap-tmux.sh"
fi

if ! tmux list-windows -t darkfantasy -F '#{window_name}' | grep -qx "$WIN"; then
  log "window $WIN not found; spawning"
  "$SELF_DIR/spawn-worker.sh" "$WIN"
fi

CMD="$ORCH_ROOT/bin/run-worker.sh $WC $TID"
log "dispatching $TID -> darkfantasy:$WIN ($CMD)"
tmux send-keys -t "darkfantasy:$WIN" "$CMD" Enter
