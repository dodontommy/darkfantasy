# Installing the patched blender-mcp

This patched copy of `ahujasid/blender-mcp` lives in
`/home/dodontommy/darkfantasy/patches/blender-mcp/` and is a full installable
package. There are two halves — the **MCP server** (Python, runs on the
machine that hosts your AI client) and the **addon** (Python, runs inside
Blender). Both are patched; both should be installed for the cross-host
features to work end-to-end.

## 1. MCP server (Linux, this repo's host)

The four MCP client configs in this project already point at the patched
package via `uvx --from`. Nothing to install — the first invocation triggers
`uv` to build and cache the package. Verify with:

```bash
uvx --from /home/dodontommy/darkfantasy/patches/blender-mcp blender-mcp --help
```

If you change MCP client configs by hand, use this server entry:

```json
{
  "mcpServers": {
    "blender": {
      "command": "uvx",
      "args": [
        "--from",
        "/home/dodontommy/darkfantasy/patches/blender-mcp",
        "blender-mcp"
      ],
      "env": {
        "DISABLE_TELEMETRY": "true"
      }
    }
  }
}
```

After editing client configs, restart the AI client to reload them.

## 2. Addon (Blender 4.5 LTS — Windows in our setup)

In PowerShell on the Windows machine that runs Blender:

```powershell
$dst = "$env:APPDATA\Blender Foundation\Blender\4.5\scripts\addons"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/dodontommy/darkfantasy/main/patches/blender-mcp/addon.py" `
  -OutFile "$dst\addon.py"
```

Then in Blender 4.5: `Edit → Preferences → Add-ons` → search "MCP" →
**disable** if previously enabled, then **enable** again so the new file
loads. In the BlenderMCP sidebar (`N` key), click "Connect to MCP server".

You will see a new **Host** field above the Port field. Default `127.0.0.1`
keeps localhost-only behavior.

### Linux / macOS addon install

```bash
mkdir -p ~/.config/blender/4.5/scripts/addons
cp /home/dodontommy/darkfantasy/patches/blender-mcp/addon.py \
   ~/.config/blender/4.5/scripts/addons/addon.py
```

```bash
mkdir -p "$HOME/Library/Application Support/Blender/4.5/scripts/addons"
cp .../patches/blender-mcp/addon.py \
   "$HOME/Library/Application Support/Blender/4.5/scripts/addons/addon.py"
```

## 3. Cross-host bridge (Windows Blender ↔ Linux MCP server)

If Blender is on Windows and the MCP server is on Linux, you need a TCP
bridge. Easiest: SSH reverse tunnel from Windows.

```powershell
ssh -N -R 9876:127.0.0.1:9876 dodontommy@100.68.127.104
```

**Use `127.0.0.1` explicitly, not `localhost`.** On Windows, `localhost`
often resolves to `::1` (IPv6) first, but the addon binds IPv4 only —
the SSH client opens the wrong socket and traffic silently fails.

Verify from Linux:

```bash
nc -z localhost 9876 && echo bridge up
python3 -c "
import json, socket
s = socket.socket(); s.settimeout(8); s.connect(('localhost', 9876))
s.sendall(json.dumps({'type':'get_polyhaven_status','params':{}}).encode())
print(s.recv(4096)[:200])
"
```

If you get JSON back, the bridge is fully alive. If you get 0 bytes, the
addon side is unreachable — usually the IPv4 trap above, or the Blender
addon hasn't been re-enabled after the patch install, or there are stacked
SSH tunnels racing for the bind on the Linux side.

## 4. Updating

Re-pull the addon with the same `Invoke-WebRequest` command, then
disable+enable the addon in Blender to reload the file.

The MCP server auto-rebuilds whenever `pyproject.toml` version bumps; if
you only edited `.py` files without bumping version, run:

```bash
uvx --refresh --from /home/dodontommy/darkfantasy/patches/blender-mcp blender-mcp
```

## Troubleshooting

| Symptom                                              | Likely cause                          | Fix                                      |
|------------------------------------------------------|---------------------------------------|------------------------------------------|
| `nc -z` succeeds but raw probe gets 0 bytes          | IPv4/IPv6 trap on Windows             | Use `127.0.0.1` in the `ssh -R` command  |
| "Screenshot file was not created"                    | Old addon installed; new server needs new addon | Re-pull `addon.py`, disable+enable in Blender |
| Multiple SSH tunnel windows open                     | Race for Linux:9876 bind              | Close all; open ONE                       |
| Bridge dies after a while                            | Idle timeout                          | Add `ServerAliveInterval 60` to ssh      |
| `Authentication failed (Request ID...)` from copilot | Copilot CLI session expired           | Run `copilot` interactively, `/login`    |
