#!/usr/bin/env bash
# Show who holds the blender-mcp lock.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

if [[ ! -f "$MCP_LOCK" ]]; then
  echo "lock file does not exist (lock is free)"
  exit 0
fi

if flock -n "$MCP_LOCK" -c true 2>/dev/null; then
  echo "free"
else
  pid=$(fuser "$MCP_LOCK" 2>/dev/null | tr -d ' ')
  if [[ -n "$pid" ]]; then
    echo "HELD by pid(s) $pid"
    ps -p $pid -o pid,etime,cmd 2>/dev/null || true
  else
    echo "HELD (holder pid not resolvable via fuser)"
  fi
fi
