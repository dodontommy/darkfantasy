#!/usr/bin/env bash
# Print queue, worker, and lock state. Safe to run constantly via `watch`.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

shopt -s nullglob

bar() { printf -- '%.0s-' {1..72}; printf '\n'; }

bar
color bold "ORCHESTRATOR STATUS  $(ts)"; echo
bar

color bold "Queue"; echo
for d in pending in_progress done failed; do
  count=$(find "$ORCH_QUEUE/$d" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)
  case "$d" in
    pending)     c=blue ;;
    in_progress) c=yellow ;;
    done)        c=green ;;
    failed)      c=red ;;
  esac
  printf "  %-14s " "$d"
  color "$c" "$count"
  echo
done
echo

color bold "In progress"; echo
in_progress_files=("$ORCH_QUEUE/in_progress"/*.md)
if [[ ${#in_progress_files[@]} -eq 0 ]]; then
  echo "  (none)"
else
  for f in "${in_progress_files[@]}"; do
    tid=$(basename "$f" .md)
    wc=$(fm_get "$f" worker_class 2>/dev/null || echo "?")
    started=$(fm_get "$f" started_at 2>/dev/null || echo "?")
    printf "  %-40s %-12s started %s\n" "$tid" "$wc" "$started"
  done
fi
echo

color bold "Recent failed (last 5)"; echo
recent=$(find "$ORCH_QUEUE/failed" -maxdepth 1 -name '*.md' -printf '%T@\t%p\n' 2>/dev/null \
         | sort -rn | head -5 | cut -f2)
if [[ -z "$recent" ]]; then
  echo "  (none)"
else
  while IFS= read -r f; do
    tid=$(basename "$f" .md)
    rc=$(fm_get "$f" exit_code 2>/dev/null || echo "?")
    reason=$(fm_get "$f" failure_reason 2>/dev/null || echo "?")
    printf "  %-40s rc=%-4s %s\n" "$tid" "$rc" "$reason"
  done <<< "$recent"
fi
echo

color bold "MCP lock"; echo
if [[ -f "$MCP_LOCK" ]]; then
  if flock -n "$MCP_LOCK" -c true 2>/dev/null; then
    echo "  free"
  else
    holder=$(fuser "$MCP_LOCK" 2>/dev/null | tr -d ' ' || echo "?")
    echo "  HELD by pid $holder"
  fi
else
  echo "  free (no lock file)"
fi
echo

color bold "Tmux session"; echo
if tmux has-session -t darkfantasy 2>/dev/null; then
  tmux list-windows -t darkfantasy -F '  #{window_index}: #{window_name}#{?window_active, (active),}'
else
  echo "  no session 'darkfantasy' (run bootstrap-tmux.sh)"
fi
bar
