#!/usr/bin/env bash
# Universal worker runner. Called by dispatch.sh; safe to invoke directly for debugging.
#
# Usage: run-worker.sh <worker_class> <ticket_id>
#   worker_class: copilot | cursor | cursor-mcp | cursor-ask | shell
#   ticket_id:    bare id (no .md, no path)

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

[[ $# -eq 2 ]] || die "usage: run-worker.sh <worker_class> <ticket_id>"
WC=$1
TID=$2

case "$WC" in
  copilot|cursor|cursor-mcp|cursor-ask|shell) ;;
  *) die "unknown worker_class: $WC" ;;
esac

START_TS=$(ts)
START_EPOCH=$(date +%s)
LOG="$ORCH_LOGS/$WC-$TID-$START_TS.log"
exec > >(tee -a "$LOG") 2>&1

log "==== run-worker $WC $TID ===="
log "log: $LOG"

# 1. Claim the ticket (atomic mv pending -> in_progress). If already in_progress, accept it.
TICKET=""
if [[ -f "$ORCH_QUEUE/pending/$TID.md" ]]; then
  TICKET=$(ticket_claim "$TID")
  log "claimed $TID from pending"
elif [[ -f "$ORCH_QUEUE/in_progress/$TID.md" ]]; then
  TICKET="$ORCH_QUEUE/in_progress/$TID.md"
  log "resuming $TID from in_progress"
else
  die "ticket $TID not in pending or in_progress"
fi

# 2. Parse ticket frontmatter
TICKET_WC=$(fm_get "$TICKET" worker_class || true)
[[ -z "$TICKET_WC" || "$TICKET_WC" == "$WC" ]] || \
  log "WARNING: ticket worker_class=$TICKET_WC but invoked as $WC"

MCP_LOCK_REQ=$(fm_get "$TICKET" mcp_lock_required || echo false)
WRITES_TRACKED=$(fm_get "$TICKET" writes_tracked_source || echo false)

# 3. Optional worktree
WORKDIR="$REPO_ROOT"
WORKTREE_PATH=""
if [[ "$WRITES_TRACKED" == "true" ]]; then
  BRANCH="ticket/$TID"
  WORKTREE_PATH="$ORCH_WORKTREES/$TID"
  if [[ -d "$WORKTREE_PATH" ]]; then
    log "reusing existing worktree at $WORKTREE_PATH"
  else
    git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WORKTREE_PATH" main
    log "worktree created: $WORKTREE_PATH (branch $BRANCH)"
  fi
  WORKDIR="$WORKTREE_PATH"
fi

# 4. Assemble prompt = preamble + ticket
PREAMBLE="$ORCH_TEMPLATES/preamble-$WC.md"
[[ -f "$PREAMBLE" ]] || die "missing preamble: $PREAMBLE"
PROMPT_FILE=$(mktemp -t orch-prompt.XXXXXX.md)
trap 'rm -f "$PROMPT_FILE"' EXIT
{
  cat "$PREAMBLE"
  printf '\n\n---\n\n# Ticket %s\n\n' "$TID"
  cat "$TICKET"
} > "$PROMPT_FILE"

# 5. Build invocation. Each CLI gets its own command line.
# We use a small inner runner so that we can wrap it with flock cleanly.
INNER=$(mktemp -t orch-inner.XXXXXX.sh)
trap 'rm -f "$PROMPT_FILE" "$INNER"' EXIT
chmod +x "$INNER"

case "$WC" in
  copilot)
    cat > "$INNER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$WORKDIR"
exec copilot -p "\$(cat "$PROMPT_FILE")" \\
  --allow-all-tools --add-dir "$WORKDIR" \\
  --effort high
EOF
    ;;
  cursor)
    cat > "$INNER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$WORKDIR"
exec agent -p --yolo --output-format text "\$(cat "$PROMPT_FILE")"
EOF
    ;;
  cursor-mcp)
    cat > "$INNER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$WORKDIR"
export DISABLE_TELEMETRY=true
exec agent -p --yolo --approve-mcps --output-format text "\$(cat "$PROMPT_FILE")"
EOF
    ;;
  cursor-ask)
    cat > "$INNER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$WORKDIR"
exec agent -p --mode ask --output-format text "\$(cat "$PROMPT_FILE")"
EOF
    ;;
  shell)
    # Extract the ## Run code block from the ticket and execute verbatim.
    cat > "$INNER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$WORKDIR"
$(awk '/^## Run/{f=1; next} /^```/{ if(f && started) exit; if(f) {started=1; next} } f && started' "$TICKET")
EOF
    ;;
esac

# 6. Execute (with optional MCP lock)
fm_set "$TICKET" status "in_progress"
fm_set "$TICKET" started_at "$START_TS"
fm_set "$TICKET" log_path "$(realpath --relative-to="$REPO_ROOT" "$LOG")"

set +e
if [[ "$MCP_LOCK_REQ" == "true" ]]; then
  log "acquiring blender-mcp lock (timeout 120s)"
  flock -w 120 "$MCP_LOCK" "$INNER"
  rc=$?
else
  "$INNER"
  rc=$?
fi
set -e

END_EPOCH=$(date +%s)
DURATION=$((END_EPOCH - START_EPOCH))
log "exit=$rc duration=${DURATION}s"

# 7. Disposition
fm_set "$TICKET" finished_at "$(ts)"
fm_set "$TICKET" duration_s "$DURATION"
fm_set "$TICKET" exit_code "$rc"

if [[ $rc -eq 0 ]]; then
  if ticket_verify_outputs "$TICKET"; then
    fm_set "$TICKET" status "done"
    mv "$TICKET" "$ORCH_QUEUE/done/$TID.md"
    log "DONE: $TID"
  else
    fm_set "$TICKET" status "failed"
    fm_set "$TICKET" failure_reason "missing_declared_outputs"
    mv "$TICKET" "$ORCH_QUEUE/failed/$TID.md"
    log "FAIL (missing outputs): $TID"
    exit 4
  fi
else
  fm_set "$TICKET" status "failed"
  fm_set "$TICKET" failure_reason "nonzero_exit_$rc"
  mv "$TICKET" "$ORCH_QUEUE/failed/$TID.md"
  log "FAIL (rc=$rc): $TID"
  exit $rc
fi
