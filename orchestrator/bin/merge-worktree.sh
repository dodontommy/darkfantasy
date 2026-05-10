#!/usr/bin/env bash
# Merge a completed ticket's worktree branch into main. By default produces
# a single squash commit using the ticket's id and intent as the message.
# Then removes the worktree and branch.
#
# Usage: merge-worktree.sh <ticket_id> [--message "<override>"]
#
# Pre-conditions:
#   - The ticket must be in queue/done/ (use status.sh to confirm)
#   - The worktree at orchestrator/worktrees/<ticket_id> must exist
#   - The branch ticket/<ticket_id> must exist
#   - main must be checked out cleanly in the primary working tree
#
# Post-conditions:
#   - One new squash commit on main
#   - Worktree removed; ticket-branch deleted
#   - Ticket file's frontmatter gets `merged_into_main: <new_sha>`

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/_lib.sh"

TID=${1:?usage: merge-worktree.sh <ticket_id> [--message MSG]}
shift
MSG_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --message) MSG_OVERRIDE=$2; shift 2 ;;
    *) die "unknown flag: $1" ;;
  esac
done

TICKET="$ORCH_QUEUE/done/$TID.md"
[[ -f "$TICKET" ]] || die "ticket not in done/: $TID"
WT="$ORCH_WORKTREES/$TID"
[[ -d "$WT" ]] || die "no worktree at $WT"
BRANCH="ticket/$TID"
git -C "$REPO_ROOT" branch --list "$BRANCH" | grep -q . || die "no branch $BRANCH"

cd "$REPO_ROOT"
[[ "$(git symbolic-ref --short HEAD)" == "main" ]] || die "primary worktree must be on main"

DIRTY=$(git status --porcelain)
[[ -z "$DIRTY" ]] || die "primary worktree has uncommitted changes; commit or stash first"

# Build squash commit. Read intent from the ticket's # Task heading.
INTENT=$(awk '/^# Task/{flag=1; next} /^## /{exit} flag' "$TICKET" \
  | sed '/^[[:space:]]*$/d' | head -3 | tr '\n' ' ' | sed 's/  */ /g; s/ *$//')

if [[ -z "$MSG_OVERRIDE" ]]; then
  MSG="ticket $TID

$INTENT

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
else
  MSG="$MSG_OVERRIDE

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
fi

# If the worktree has uncommitted changes (typical — workers don't commit),
# stage and commit them on the ticket branch first so squash-merge has
# something to fold in.
if [[ -n "$(git -C "$WT" status --porcelain)" ]]; then
  git -C "$WT" add -A
  git -C "$WT" -c commit.gpgsign=false commit -m "scratch: worktree state for $TID" >/dev/null
  log "committed worktree state on $BRANCH"
fi

log "squash-merging $BRANCH into main"
git merge --squash "$BRANCH"
git commit -m "$MSG"
NEW_SHA=$(git rev-parse HEAD)

log "removing worktree + branch"
git worktree remove "$WT" --force
git branch -D "$BRANCH" >/dev/null

fm_set "$TICKET" merged_into_main "$NEW_SHA"
log "MERGED $TID -> $NEW_SHA"
