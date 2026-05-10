# Patches against ahujasid/blender-mcp `addon.py`

Base: vendored snapshot 1.5.5 (commit `7636d13`, 2026-01-23).
Patched here so we can:
1. Bind the addon's TCP server to a configurable host (default `127.0.0.1`,
   set `0.0.0.0` to accept LAN connections — useful with Tailscale + socat
   on a remote host running the MCP server).
2. Drive both host and port from environment variables (`BLENDER_MCP_HOST`,
   `BLENDER_MCP_PORT`) at register time, without UI clicks.
3. Show the bound host in the panel label.

Net delta: ~17 lines added, all marked `# PATCH (darkfantasy)`. No upstream
behavior changes when env vars are unset and the host is left at default.

## Diff summary (vs upstream addon.py)

| Site                          | Change                                             |
|-------------------------------|----------------------------------------------------|
| `BlenderMCPServer.__init__`   | host/port default to env or fallbacks              |
| `BLENDERMCP_PT_Panel.draw`    | new `layout.prop(scene, "blendermcp_host")` row    |
| Same panel — running label    | shows `host:port` instead of just port             |
| `BLENDERMCP_OT_StartServer`   | passes `scene.blendermcp_host` into the server     |
| `register()`                  | new `blendermcp_host` StringProperty + env default |
| `unregister()`                | symmetric `del` of the new property                |

## Why not upstream

The wrapper has been quiet since Jan 2026 (per
`docs/research/blender-mcp-deep-dive.md`). We may upstream this patch later;
for now the project carries it locally.

## What's NOT patched

- The MCP server (Python side, `uvx blender-mcp`) still hardcodes
  `localhost` for its connect target. To talk to a remote addon, either run
  `socat TCP-LISTEN:9876,bind=127.0.0.1,fork TCP:<remote>:9876` on the
  server side, or use `ssh -R 9876:localhost:9876` from the addon side.
  See `orchestrator/README.md` § "Running on a headless host".
- `mcp__blender__execute_blender_code` is still unsandboxed RCE per
  `docs/research/blender-mcp-deep-dive.md`. Out of scope for this patch.
- Hyper3D Rodin is still hardcoded to Gen-1 Sketch + Raw mode. Out of scope
  for this patch — production hero base mesh should call Rodin Gen-2 via
  direct API, see `docs/research/ai-3d-generation-2026.md`.
