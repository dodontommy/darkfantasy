# Orchestrator

Filesystem-backed work queue + lock + tmux worker fleet for the dark fantasy character pipeline.
Survives orchestrator restart. A fresh Claude session can resume by reading this file.

## Premises (non-negotiable)

1. **`.py` scripts under `scripts/` are the source of truth.** `.blend` files in `outputs/` are
   build artifacts, regenerable by running the script. Diff is impossible on `.blend`; reviewability
   lives in the script.
2. **The Blender MCP socket on `localhost:9876` is a singleton.** Only one worker may speak MCP at
   a time. Enforced by `flock` on `orchestrator/locks/blender-mcp.lock`.
3. **Headless `blender --background --python` runs are parallel-safe.** Each is its own process
   acting on its own `.blend` file.
4. **Workers are run-to-completion CLIs**, not daemons. The orchestrator dispatches one ticket per
   invocation. State lives on disk, not in worker memory.
5. **Worktrees isolate any worker that writes tracked source.** `outputs/`-only tickets run in the
   live tree; tickets that touch `scripts/`, `skills/`, `docs/`, or `orchestrator/` get their own
   `git worktree`.

## Layout

```
orchestrator/
├── README.md                      # this file
├── bin/
│   ├── _lib.sh                    # shared bash helpers (frontmatter parsing, logging)
│   ├── new-ticket.sh              # scaffold a ticket from template
│   ├── run-worker.sh              # the universal worker invocation; called by dispatch
│   ├── dispatch.sh                # send a ticket to a tmux worker window
│   ├── status.sh                  # print queue + worker + lock state
│   ├── spawn-worker.sh            # create a tmux worker window
│   ├── bootstrap-tmux.sh          # create the darkfantasy tmux session
│   ├── scan-stale.sh              # find orphaned in_progress tickets (>30min old)
│   └── lock-status.sh             # who holds blender-mcp.lock
├── templates/
│   ├── ticket-template.md
│   ├── preamble-copilot.md        # injected before ticket body for copilot CLI workers
│   ├── preamble-cursor.md         # injected for cursor agent text/script workers
│   ├── preamble-cursor-mcp.md     # injected for cursor agent MCP workers
│   └── preamble-shell.md          # injected for shell-extract-and-run workers
├── queue/
│   ├── pending/                   # tickets ready to claim (atomic mv into in_progress)
│   ├── in_progress/               # claimed tickets
│   ├── done/                      # completed; frontmatter updated with rc/duration
│   └── failed/                    # failed; sidecar .stderr saved
├── locks/
│   └── blender-mcp.lock           # flock target; holding this == owning MCP
├── logs/
│   └── <worker>-<ticket>-<ts>.log # one log per worker invocation
├── worktrees/                     # gitignored; one subdir per active tracked-source ticket
└── examples/                      # sample tickets demonstrating each worker class
```

## Worker classes

| Class          | CLI invoked                                       | MCP? | Use for                                              |
|----------------|---------------------------------------------------|------|------------------------------------------------------|
| `copilot`      | `copilot -p ... --allow-all-tools --add-dir ...`  | no   | Authoring/refactoring `.py`, lint, manifest checks   |
| `cursor`       | `agent -p --yolo --output-format text ...`        | no   | Same domain as copilot; alternative engine           |
| `cursor-mcp`   | `agent -p --yolo --approve-mcps ...`              | YES  | Live Blender editing, viewport screenshots, AI-gen   |
| `cursor-ask`   | `agent -p --mode ask ...`                         | no   | Read-only critique (renders, code review)            |
| `claude-cli`   | `claude --print --model <m> --add-dir ...`        | no   | Anthropic-quota work; model from `CLAUDE_CLI_MODEL`  |
| `shell`        | `bash` extracting `## Run` section                | no   | Pure deterministic CLI runs (`blender --background`) |
| `claude-self`  | dispatched in this Claude session, not tmux       | no   | Architecture, taste, merging, talking to user        |

### Selecting workers per pipeline run

Tickets declare a *logical* worker class. The actual CLI that runs is resolved
at dispatch time by the `REMAP_*` table in `orchestrator/workers.conf`. This
lets you reshape an entire pipeline run without editing tickets:

```
# orchestrator/workers.conf
REMAP_copilot=copilot          # default: identity mapping
REMAP_cursor_ask=claude-cli    # route critique through claude --print
CLAUDE_CLI_MODEL=opus          # ...with Opus when critique runs
```

Edit `workers.conf` directly, or run the interactive helper:

```bash
orchestrator/bin/configure-pipeline.sh
```

`cursor-mcp` is the only physical class wired to the `--approve-mcps` flag, so
remapping a `cursor-mcp` ticket to a non-MCP worker will fail by design — keep
MCP tickets on `cursor-mcp`.

## Ticket lifecycle

```
new-ticket.sh           dispatch.sh            run-worker.sh                 review
     │                       │                       │                          │
     ▼                       ▼                       ▼                          ▼
pending/  ─ atomic mv ─►  in_progress/  ─ exec ─►  done/      ─ orchestrator ─► commit
                                       └ fail ─►  failed/                       triage
```

1. `new-ticket.sh <slug>` writes a ticket from the template into `pending/`.
2. Orchestrator (Claude or human) edits the ticket to fill in task body, inputs, outputs.
3. `dispatch.sh <ticket-id> <tmux-window>` sends `run-worker.sh` to that window.
4. `run-worker.sh`:
   - claims the ticket via atomic `mv pending/ → in_progress/`
   - if `mcp_lock_required: true`, acquires `blender-mcp.lock` via `flock -w 120`
   - if `writes_tracked_source: true`, creates a `git worktree` under `worktrees/`
   - assembles `preamble-<class>.md + ticket.md` as the prompt
   - invokes the CLI with logs streamed to `logs/<worker>-<ticket>-<ts>.log`
   - on exit-0: verifies declared `outputs:` exist, moves ticket to `done/`
   - on exit-N: writes `failed/<ticket>.stderr`, moves ticket to `failed/`
   - always: releases lock, leaves worktree intact for review if a diff was produced
5. Orchestrator reviews `done/` outputs (or worktree diffs), commits to main.

## Standing tmux session

Bootstrap once per machine:

```bash
orchestrator/bin/bootstrap-tmux.sh
```

Creates session `darkfantasy` with:

| Window | Name             | Contents                                                  |
|--------|------------------|-----------------------------------------------------------|
| 0      | `orchestrator`   | shell for `claude` CLI or attached observer               |
| 1      | `blender`        | GUI Blender process (the singleton holding port 9876)     |
| 2      | `dispatcher`     | `watch -n 2 orchestrator/bin/status.sh`                   |
| 3      | `worker-cop-1`   | idle copilot worker slot                                  |
| 4      | `worker-cop-2`   | idle copilot worker slot                                  |
| 5      | `worker-cur-1`   | cursor agent slot (text/script)                           |
| 6      | `worker-mcp-1`   | cursor agent slot dedicated to MCP work (single, by lock) |
| 7      | `logs`           | `tail -F orchestrator/logs/*.log`                         |

Window 1 (`blender`) requires one manual step: in the BlenderMCP sidebar, click
*Connect to MCP server*. This cannot be automated without modifying the upstream addon.
A future TODO is to drop a `~/.config/blender/4.x/scripts/startup/auto_start_mcp.py`
that flips the toggle on Blender startup.

### Running on a headless host

This project's primary host is headless Linux (no DISPLAY). Implications:

- **Non-MCP work is fine.** All `copilot`, `cursor`, `cursor-ask`, `claude-cli`,
  and `shell` tickets work without a Blender GUI. The substrate runs without
  tmux too — invoke `run-worker.sh` directly.
- **`cursor-mcp` requires a live Blender GUI on `localhost:9876`.** Two options:
  1. **Xvfb on this box**: `xvfb-run -a blender` in the `blender` window. Slow,
     and `get_viewport_screenshot` outputs a black frame unless GPU is wired
     through EGL (see `docs/research/headless-blender-2026.md`).
  2. **Remote Blender via SSH reverse tunnel.** Run Blender on a Windows or
     macOS machine, then from that machine:
     ```
     ssh -R 9876:localhost:9876 user@<linux-host>
     ```
     The Linux-side `uvx blender-mcp` then connects to `localhost:9876`, which
     is the tunnel, which is the remote Blender. The `flock` lock still works
     (it lives on Linux). Recommended for any real MCP work from this host.

## Source-of-truth promotion (MCP → script)

Every cursor-mcp ticket ends with the worker emitting a `## Promotion` block in its log
that contains the bpy operations it ran, ready for paste into a tracked script. The
orchestrator follow-up ticket (`promote-mcp-session`) takes that block and turns it into
a tracked `.py` under `scripts/parts/`. The headless run regenerates the `.blend`. The
diff from regenerated → MCP-edited `.blend` should be empty (or very near it) — that's
how we verify parity.

## Failure recovery

| Failure mode                          | Recovery                                                  |
|---------------------------------------|-----------------------------------------------------------|
| Orchestrator (Claude) restarts        | Read this file + `MEMORY.md` + `orchestrator/bin/status.sh` |
| Worker crashes mid-task               | `flock` releases on process death; `scan-stale.sh` flags |
| Blender process dies                  | Restart in window 1; reconnect MCP socket manually        |
| Ticket fails repeatedly               | Inspect `failed/<id>.stderr` and `logs/`; revise + redrop |
| Worktree left dirty after merge       | `git worktree remove orchestrator/worktrees/<ticket>`     |

## Conventions referenced by ticket prompts

- Object naming: lowercase with spaces, scoped prefix (`left pauldron spike`).
- All paths in scripts: `pathlib.Path` relative to repo root computed from `__file__`.
- All scripts must end with `if __name__ == "__main__": main()`.
- All `blender --background` invocations use `--factory-startup --enable-autoexec --python-exit-code 2`.
- Render output goes under `outputs/renders/<character>/<step>.png`.
- See `docs/research/headless-blender-2026.md` for the full CLI invariant.

## Safety notes

- `mcp__blender__execute_blender_code` is unsandboxed RCE on this host. cursor-mcp tickets
  must avoid using it for production geometry — promote to tracked script instead.
- `mcp__blender__import_generated_asset_hunyuan` accepts arbitrary URLs (SSRF surface).
  Restrict to known endpoints in ticket prompts.
- Hyper3D Rodin via the MCP wrapper is stuck on Gen-1 Sketch + Raw mode (hardcoded in
  vendored addon `1.5.5`). For hero-character base meshes, call Rodin Gen-2 (T-Pose,
  18k_Quad) via direct API in a tracked script — see `docs/research/ai-3d-generation-2026.md`.
- Telemetry: set `DISABLE_TELEMETRY=true` in the env that launches `uvx blender-mcp`.
