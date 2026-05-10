#!/usr/bin/env bash
# One-shot setup: create the darkfantasy tmux session with the standard window layout.
# Idempotent — re-running adds any missing windows but won't restart Blender.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

if ! tmux has-session -t darkfantasy 2>/dev/null; then
  tmux new-session -d -s darkfantasy -n orchestrator -c "$REPO_ROOT"
  log "created session darkfantasy"
fi

ensure_window() {
  local name=$1 cmd=$2
  if tmux list-windows -t darkfantasy -F '#{window_name}' | grep -qx "$name"; then
    return
  fi
  tmux new-window -t darkfantasy -n "$name" -c "$REPO_ROOT" "$cmd"
  log "created window $name"
}

# Window 1: Blender GUI process (singleton)
# Note: The MCP socket connection still requires one manual click in the
# BlenderMCP sidebar (Connect to MCP server). Future TODO is to drop a
# startup script under ~/.config/blender/<ver>/scripts/startup/ to flip it.
ensure_window blender "DISABLE_TELEMETRY=true blender; exec bash"

# Window 2: live status dashboard
ensure_window dispatcher "watch -t -n 2 '$ORCH_ROOT/bin/status.sh'"

# Worker windows
for w in worker-cop-1 worker-cop-2 worker-cur-1 worker-mcp-1; do
  ensure_window "$w" "echo worker $w ready; exec bash"
done

# Logs tail
ensure_window logs "tail -F $ORCH_LOGS/*.log 2>/dev/null || (echo 'no logs yet'; exec bash)"

log "bootstrap complete. Attach with: tmux attach -t darkfantasy"
log "REMINDER: in the blender window, click 'Connect to MCP server' in the BlenderMCP sidebar."
