# AI Client Pipeline

This project uses a generic stdio MCP server for Blender:

```json
{
  "mcpServers": {
    "blender": {
      "command": "uvx",
      "args": ["blender-mcp"]
    }
  }
}
```

The MCP server is client-agnostic. Codex, Claude Code, GitHub Copilot CLI, and Cursor Agent all launch the same command. The server then connects to the Blender add-on socket on `localhost:9876`.

## Required Runtime State

1. Blender is open.
2. The `Interface: Blender MCP` add-on is enabled.
3. In the Blender viewport sidebar, the `BlenderMCP` tab is connected on port `9876`.
4. The AI client has loaded a config containing the `blender` MCP server.

## Config Locations

Codex:

```text
/home/dodontommy/.codex/config.toml
```

Claude Code user config:

```text
/home/dodontommy/.claude.json
```

GitHub Copilot CLI user config:

```text
/home/dodontommy/.copilot/mcp-config.json
```

Generic workspace config:

```text
/home/dodontommy/darkfantasy/.mcp.json
```

Cursor Agent workspace config:

```text
/home/dodontommy/darkfantasy/.cursor/mcp.json
```

Cursor Agent global config:

```text
/home/dodontommy/.cursor/mcp.json
```

## Client Commands

Codex:

```bash
codex mcp get blender
```

Claude Code:

```bash
claude mcp get blender
```

GitHub Copilot CLI:

```bash
copilot mcp get blender
```

Cursor Agent:

```bash
agent mcp list
agent mcp enable blender
agent mcp list-tools blender
```

## Modeling Flow

1. Use CLI scripts for deterministic base assets:

```bash
blender --background --python-exit-code 1 --python scripts/create_dark_fantasy_lady_blockout.py
```

2. Open the generated `.blend`.
3. Start the Blender MCP socket from the Blender sidebar.
4. Use an MCP-capable AI client to inspect scene contents, adjust objects/materials, run Blender Python, and render previews.
5. Commit useful procedural changes back into scripts so the asset remains reproducible.

## Guardrails

- Keep generated assets original and only genre-inspired.
- Keep body, hair, armor, cloth, jewelry, lights, and cameras as separate named objects.
- Use MCP for interactive iteration; use Blender CLI scripts for repeatable milestones.
- Do not enable third-party asset download or 3D generation toggles unless the source/licensing is acceptable for the current asset.
