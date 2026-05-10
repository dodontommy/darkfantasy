#!/usr/bin/env bash
# Reset a failed (or done) ticket back to pending and optionally drop its
# worktree + branch so a clean re-dispatch is possible.
#
# Usage: retry-ticket.sh <ticket_id> [--keep-worktree]

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

TID=${1:?usage: retry-ticket.sh <ticket_id> [--keep-worktree]}
KEEP_WT=false
[[ "${2:-}" == "--keep-worktree" ]] && KEEP_WT=true

TICKET=$(ticket_locate "$TID") || die "ticket not found: $TID"

case "$TICKET" in
  *queue/pending/*) log "already in pending"; exit 0 ;;
  *queue/in_progress/*) die "ticket is in_progress; abort the worker first" ;;
  *queue/done/*|*queue/failed/*) ;;
esac

mv "$TICKET" "$ORCH_QUEUE/pending/$TID.md"
"$SELF_DIR/clean-ticket.sh" "$TID"

if [[ "$KEEP_WT" == "false" ]]; then
  WT="$ORCH_WORKTREES/$TID"
  if [[ -d "$WT" ]]; then
    git -C "$REPO_ROOT" worktree remove "$WT" --force
    log "removed worktree $WT"
  fi
  BRANCH="ticket/$TID"
  if git -C "$REPO_ROOT" branch --list "$BRANCH" | grep -q .; then
    git -C "$REPO_ROOT" branch -D "$BRANCH" >/dev/null
    log "deleted branch $BRANCH"
  fi
fi

log "ready to redispatch: orchestrator/bin/run-worker.sh <wc> $TID"
