#!/usr/bin/env bash
# Scaffold a new ticket from the template.
#
# Usage: new-ticket.sh <slug> <worker_class> [--mcp] [--writes-tracked]
#   Produces orchestrator/queue/pending/<timestamp>-<slug>.md and prints its path.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

[[ $# -ge 2 ]] || die "usage: new-ticket.sh <slug> <worker_class> [--mcp] [--writes-tracked]"
SLUG=$1; WC=$2; shift 2
MCP=false; TRACKED=false
for arg in "$@"; do
  case "$arg" in
    --mcp) MCP=true ;;
    --writes-tracked) TRACKED=true ;;
    *) die "unknown flag: $arg" ;;
  esac
done

case "$WC" in
  copilot|cursor|cursor-mcp|cursor-ask|shell) ;;
  *) die "invalid worker_class: $WC" ;;
esac

STAMP=$(date -u +%Y%m%dT%H%M%S)
TID="$STAMP-$SLUG"
DEST="$ORCH_QUEUE/pending/$TID.md"

[[ -f "$DEST" ]] && die "ticket already exists: $DEST"

# Render template with substitutions
sed \
  -e "s|{{ID}}|$TID|g" \
  -e "s|{{WORKER_CLASS}}|$WC|g" \
  -e "s|{{MCP_LOCK}}|$MCP|g" \
  -e "s|{{WRITES_TRACKED}}|$TRACKED|g" \
  -e "s|{{CREATED_AT}}|$(ts)|g" \
  "$ORCH_TEMPLATES/ticket-template.md" > "$DEST"

log "created $DEST"
echo "$DEST"
