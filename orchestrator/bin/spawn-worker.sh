#!/usr/bin/env bash
# Create a tmux worker window in the darkfantasy session.
#
# Usage: spawn-worker.sh <window_name>
#   The window starts a bash shell in the repo root. dispatch.sh sends
#   commands to it via tmux send-keys. The shell stays alive between
#   tickets; CLIs are launched as one-shot subprocesses by run-worker.sh.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

WIN=${1:?usage: spawn-worker.sh <window_name>}

tmux has-session -t darkfantasy 2>/dev/null \
  || die "no session darkfantasy (run bootstrap-tmux.sh)"

if tmux list-windows -t darkfantasy -F '#{window_name}' | grep -qx "$WIN"; then
  log "window $WIN already exists"
  exit 0
fi

tmux new-window -t darkfantasy -n "$WIN" -c "$REPO_ROOT" \
  "bash -i -c 'echo worker $WIN ready; exec bash'"
log "spawned $WIN"
