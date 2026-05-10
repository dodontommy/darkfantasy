# Blender MCP Install

Installed MCP server:

```toml
[mcp_servers.blender]
command = "uvx"
args = ["blender-mcp"]
```

Config path:

```text
/home/dodontommy/.codex/config.toml
```

Generic workspace MCP config:

```text
/home/dodontommy/darkfantasy/.mcp.json
```

Cursor Agent workspace MCP config:

```text
/home/dodontommy/darkfantasy/.cursor/mcp.json
```

Cursor Agent global MCP config:

```text
/home/dodontommy/.cursor/mcp.json
```

Claude Code user MCP config was updated through:

```bash
claude mcp add --scope user blender -- uvx blender-mcp
```

GitHub Copilot CLI user MCP config was updated through:

```bash
copilot mcp add blender -- uvx blender-mcp
```

Vendored source:

```text
/home/dodontommy/darkfantasy/vendor/blender-mcp
```

Blender add-on source:

```text
/home/dodontommy/darkfantasy/vendor/blender-mcp/addon.py
```

Installed Blender user add-on directory:

```text
/home/dodontommy/.config/blender/4.0/scripts/addons/addon.py
```

## Use

1. Restart the client so it reloads MCP config.
2. Open Blender.
3. In the 3D View sidebar, press `N` if the sidebar is hidden.
4. Open the `BlenderMCP` tab.
5. Leave the port at `9876`.
6. Click `Connect to MCP server`.

Every client uses the same stdio MCP server command:

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

The MCP server expects the Blender add-on socket on `localhost:9876`.

## Client Checks

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

Cursor Agent may prompt to approve the workspace MCP server. In headless runs, use:

```bash
agent --approve-mcps --trust --workspace /home/dodontommy/darkfantasy
```

## Verified

- `codex mcp add blender -- uvx blender-mcp` succeeded.
- `claude mcp add --scope user blender -- uvx blender-mcp` succeeded.
- `copilot mcp add blender -- uvx blender-mcp` succeeded.
- `.mcp.json`, `.cursor/mcp.json`, and `~/.cursor/mcp.json` were written with the same generic MCP command.
- `codex mcp list` shows `blender` enabled.
- Blender 4.0 installed and enabled the `Interface: Blender MCP` add-on.
- A temporary background Blender process registered the add-on and opened the server socket on `localhost:9876`.
