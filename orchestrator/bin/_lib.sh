#!/usr/bin/env bash
# Shared helpers for orchestrator scripts. Source, do not exec.

set -euo pipefail

ORCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$ORCH_ROOT/.." && pwd)"

ORCH_QUEUE="$ORCH_ROOT/queue"
ORCH_LOCKS="$ORCH_ROOT/locks"
ORCH_LOGS="$ORCH_ROOT/logs"
ORCH_WORKTREES="$ORCH_ROOT/worktrees"
ORCH_TEMPLATES="$ORCH_ROOT/templates"
MCP_LOCK="$ORCH_LOCKS/blender-mcp.lock"

ts() { date -u +%Y%m%dT%H%M%SZ; }

log() { printf '[%s] %s\n' "$(ts)" "$*" >&2; }
die() { log "FATAL: $*"; exit 1; }

# Read a single YAML scalar from the frontmatter block of a ticket file.
# Usage: fm_get <file> <key>
# Returns empty string if key absent. Only handles top-level scalar keys.
fm_get() {
  local file=$1 key=$2
  awk -v k="$key" '
    BEGIN { infm = 0 }
    /^---[[:space:]]*$/ { infm = !infm; if (!infm) exit; next }
    infm && $0 ~ "^"k":" {
      sub("^"k":[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      print
      exit
    }
  ' "$file"
}

# Read a YAML list from frontmatter. Each list item must be `  - value` on its own line.
# Usage: fm_list <file> <key>
fm_list() {
  local file=$1 key=$2
  awk -v k="$key" '
    BEGIN { infm = 0; inlist = 0 }
    /^---[[:space:]]*$/ { infm = !infm; if (!infm) exit; next }
    infm && $0 ~ "^"k":" { inlist = 1; next }
    infm && inlist && /^[a-zA-Z_]/ { inlist = 0 }
    infm && inlist && /^[[:space:]]+-[[:space:]]/ {
      sub("^[[:space:]]+-[[:space:]]+", "")
      sub("[[:space:]]+$", "")
      print
    }
  ' "$file"
}

# Locate a ticket by id. Searches pending, in_progress, done, failed.
# Echoes path to file or empty.
ticket_locate() {
  local tid=$1
  for d in pending in_progress done failed; do
    if [[ -f "$ORCH_QUEUE/$d/$tid.md" ]]; then
      echo "$ORCH_QUEUE/$d/$tid.md"
      return 0
    fi
  done
  return 1
}

# Atomic claim: mv pending/<id> -> in_progress/<id>. Returns path on stdout.
ticket_claim() {
  local tid=$1
  local src="$ORCH_QUEUE/pending/$tid.md"
  local dst="$ORCH_QUEUE/in_progress/$tid.md"
  [[ -f "$src" ]] || die "ticket not in pending: $tid"
  mv "$src" "$dst"
  echo "$dst"
}

# Verify each declared output path exists. Returns 0 if all present, 1 otherwise.
ticket_verify_outputs() {
  local file=$1
  local missing=0
  while IFS= read -r out; do
    [[ -z "$out" ]] && continue
    local path="$REPO_ROOT/$out"
    if [[ ! -e "$path" ]]; then
      log "missing output: $out"
      missing=$((missing + 1))
    fi
  done < <(fm_list "$file" outputs)
  return $missing
}

# Append a key:value to the YAML frontmatter of a ticket (idempotent: replaces if present).
fm_set() {
  local file=$1 key=$2 value=$3
  local tmp
  tmp=$(mktemp)
  awk -v k="$key" -v v="$value" '
    BEGIN { infm = 0; set = 0 }
    /^---[[:space:]]*$/ {
      infm++
      if (infm == 2 && !set) { print k": "v; set = 1 }
      print; next
    }
    infm == 1 && $0 ~ "^"k":" {
      if (!set) { print k": "v; set = 1 }
      next
    }
    { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

color() {
  local c=$1; shift
  case "$c" in
    red)    printf '\033[31m%s\033[0m' "$*" ;;
    green)  printf '\033[32m%s\033[0m' "$*" ;;
    yellow) printf '\033[33m%s\033[0m' "$*" ;;
    blue)   printf '\033[34m%s\033[0m' "$*" ;;
    bold)   printf '\033[1m%s\033[0m'  "$*" ;;
    *)      printf '%s' "$*" ;;
  esac
}
