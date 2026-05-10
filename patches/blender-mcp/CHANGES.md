# Patches against ahujasid/blender-mcp 1.5.5

Base: vendored snapshot 1.5.5 (upstream commit `7636d13`, 2026-01-23).
Local version stamp: `1.5.5+darkfantasy.1` (in `pyproject.toml`).

This directory is a **complete, installable** copy of the upstream package
plus our patches. Install with:

```bash
uvx --from /home/dodontommy/darkfantasy/patches/blender-mcp blender-mcp
```

(All four MCP client configs in this project — workspace `.mcp.json`,
`.cursor/mcp.json`, `~/.cursor/mcp.json`, `~/.copilot/mcp-config.json` — are
already wired to use this path.)

## Patch 1 — env-driven host on the addon (Jan/May 2026)

Files: `addon.py`.

Lets the addon bind to a configurable host (default `127.0.0.1`, set
`0.0.0.0` to accept LAN/Tailscale connections) and read host/port from
`BLENDER_MCP_HOST` / `BLENDER_MCP_PORT` env vars at register time. Adds a
"Host" field to the BlenderMCP sidebar panel, and shows `host:port` in the
running label.

Net delta: ~17 lines added, all marked `# PATCH (darkfantasy)`.

## Patch 2 — cross-host viewport screenshot (May 2026)

Files: `addon.py`, `src/blender_mcp/server.py`.

The upstream code constructs a temp file path on the **server** host
(`tempfile.gettempdir()` → `/tmp/...` on Linux) and sends it to the addon to
write to. When the addon is on a different host (Windows over SSH tunnel),
`/tmp` does not exist there; `bpy.ops.screen.screenshot_area` silently fails
and the server raises "Screenshot file was not created".

The patch flips the responsibility: the addon writes to its own local temp
path, base64-encodes the bytes, returns them in a `data_b64` field, then
deletes the local temp file. The server decodes the bytes and returns an
`Image`. No file sharing required between hosts.

Backward compatibility:
- **New server + new addon** → bytes-in-response (cross-host works).
- **Old server + new addon** → addon receives a server-supplied filepath; if
  the parent dir does not exist on the addon's host, addon falls back to
  local temp + bytes anyway. The addon also writes to the requested path
  when feasible.
- **New server + old addon** → broken (old addon errors on missing filepath).
  The server's error message tells the user to install the patched addon.
- **Old server + old addon** → unchanged upstream behavior.

Net delta: ~50 lines changed across the two files.

## What's still NOT patched

- `mcp__blender__execute_blender_code` is still unsandboxed RCE on the host
  running Blender, per `docs/research/blender-mcp-deep-dive.md`. Use
  tracked `.py` scripts for any production geometry; never let a worker
  drive arbitrary mutations through this tool.
- Hyper3D Rodin is still hardcoded to Gen-1 Sketch + Raw mode. For hero
  character base mesh, call Rodin Gen-2 directly via
  `scripts/ai_gen/rodin_gen2.py` (not yet written; flag in
  `skills/ai-3d-mesh-handler`).
- `mcp__blender__import_generated_asset_hunyuan` accepts arbitrary URLs
  (SSRF surface). Restrict in ticket prompts.
