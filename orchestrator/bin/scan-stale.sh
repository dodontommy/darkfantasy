#!/usr/bin/env bash
# Find in_progress tickets older than N minutes (default 30) — likely orphaned by a
# crashed worker. Prints id and age. Does not auto-recover; orchestrator triages.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

THRESHOLD_MIN=${1:-30}
NOW=$(date +%s)

shopt -s nullglob
found=0
for f in "$ORCH_QUEUE/in_progress"/*.md; do
  mtime=$(stat -c %Y "$f")
  age_min=$(( (NOW - mtime) / 60 ))
  if (( age_min >= THRESHOLD_MIN )); then
    tid=$(basename "$f" .md)
    wc=$(fm_get "$f" worker_class 2>/dev/null || echo "?")
    started=$(fm_get "$f" started_at 2>/dev/null || echo "?")
    printf "STALE %-40s wc=%-12s started=%s age=%dm\n" "$tid" "$wc" "$started" "$age_min"
    found=$((found + 1))
  fi
done

if (( found == 0 )); then
  echo "no stale in_progress tickets (threshold ${THRESHOLD_MIN}m)"
fi
