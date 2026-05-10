---
id: {{ID}}
worker_class: {{WORKER_CLASS}}
mcp_lock_required: {{MCP_LOCK}}
writes_tracked_source: {{WRITES_TRACKED}}
priority: 3
estimated_minutes: 10
created_at: {{CREATED_AT}}
status: pending
inputs:
  - path/to/input.py
outputs:
  - path/to/output.py
depends_on: []
---

# Task

One-paragraph problem statement. Self-contained. Assume the worker has zero
context from this conversation — restate what matters.

## Conventions

- Source of truth is the tracked .py script. .blend files are build outputs.
- Object naming: lowercase with spaces, scoped prefix.
- All paths via `pathlib.Path` relative to repo root computed from `__file__`.
- Headless invocation: `blender --background --factory-startup --enable-autoexec --python-exit-code 2 --python <script>`.
- See `docs/research/headless-blender-2026.md` for the complete CLI invariant.

## Inputs

- `path/to/input.py` — describe what the worker will read.

## Outputs

- `path/to/output.py` — describe what must exist when the ticket completes.

## Verification

How the worker should self-verify before exiting. Examples:
- `blender --background --python-exit-code 2 --python <script>` exits 0
- A specific file exists and is non-empty
- A specific render is produced and is at least N×N pixels

## Run

For `worker_class: shell` only — the literal commands to execute, in a single
fenced block. Everything outside this block is ignored by the shell worker.

```bash
echo "shell tickets put commands here"
```

## Notes

Free-form notes for the orchestrator's later review. Workers may ignore.
