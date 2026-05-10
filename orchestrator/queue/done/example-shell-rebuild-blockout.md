---
id: example-shell-rebuild-blockout
worker_class: shell
mcp_lock_required: false
writes_tracked_source: false
priority: 5
estimated_minutes: 2
created_at: 20260510T051600Z
inputs:
  - scripts/create_dark_fantasy_lady_blockout.py
outputs:
  - outputs/nocturne_matriarch_blockout.blend
  - outputs/renders/nocturne_matriarch_blockout.png
depends_on: []
---

# Task

Regenerate the Nocturne Matriarch blockout `.blend` and its preview render from
the existing tracked script. This is a verification step — confirms the script
still runs cleanly under the project's headless invariant after any unrelated
edits.

## Conventions

- Source of truth: `scripts/create_dark_fantasy_lady_blockout.py`.
- Outputs are gitignored build artifacts; deleting them and re-running this ticket
  must be lossless.

## Verification

`run-worker.sh` checks that both declared `outputs` exist after the run. Exit 0
from the shell block indicates success; non-zero (including via
`--python-exit-code 2` from Blender) marks the ticket failed.

## Run

```bash
blender --background \
  --factory-startup \
  --enable-autoexec \
  --python-exit-code 2 \
  --python scripts/create_dark_fantasy_lady_blockout.py
```

## Notes

This is the simplest possible ticket. Use as the canary before committing any
change to scripts/, skills/, or the orchestrator itself — the regen should always
succeed and the produced files should be identical hash to the previous run
(modulo Blender's nondeterministic Cycles sample noise).
