# Installing the patched blender-mcp addon

This addon is required on whichever Blender process will host the MCP socket
(GUI Blender — typically on a workstation, often Windows).

## Windows (Blender 4.5 LTS)

In PowerShell:

```powershell
$dst = "$env:APPDATA\Blender Foundation\Blender\4.5\scripts\addons"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/dodontommy/darkfantasy/main/patches/blender-mcp/addon.py" `
  -OutFile "$dst\addon.py"
```

Then in Blender 4.5: `Edit → Preferences → Add-ons` → search "MCP" → enable
**Interface: Blender MCP**.

## Linux

```bash
mkdir -p ~/.config/blender/4.5/scripts/addons
cp /home/dodontommy/darkfantasy/patches/blender-mcp/addon.py \
   ~/.config/blender/4.5/scripts/addons/addon.py
```

(For 4.0 substitute `4.0`.)

## macOS

```bash
mkdir -p "$HOME/Library/Application Support/Blender/4.5/scripts/addons"
cp .../patches/blender-mcp/addon.py \
   "$HOME/Library/Application Support/Blender/4.5/scripts/addons/addon.py"
```

## What changes vs. upstream

A new **Host** field appears above the Port field in the BlenderMCP sidebar.
- Default `127.0.0.1` keeps original behavior (localhost only).
- Set to `0.0.0.0` to accept LAN connections (combine with `socat` on the
  MCP-server side or with Tailscale for zero-config LAN).

You can also seed the host/port via environment variables before launching
Blender — useful for non-interactive setups:

```bash
BLENDER_MCP_HOST=0.0.0.0 BLENDER_MCP_PORT=9876 blender
```

## Updating

Re-run the install command. The addon is a single file; copy overwrites.

## Connection patterns supported

| Pattern                      | Addon Host  | Server target              | Notes                                      |
|------------------------------|-------------|----------------------------|--------------------------------------------|
| Local same-machine (default) | `127.0.0.1` | `localhost`                | No setup. Works out of the box.            |
| SSH reverse tunnel           | `127.0.0.1` | `localhost` (tunneled)     | `ssh -R 9876:localhost:9876` from addon host. No addon patch needed for this — included for completeness. |
| Tailscale + socat on server  | `0.0.0.0`   | `localhost` (socat-bridged)| `socat TCP-LISTEN:9876,bind=127.0.0.1,fork TCP:<TAILSCALE_IP_OF_ADDON_HOST>:9876` on the server side. |
| Direct LAN (insecure)        | `0.0.0.0`   | `<addon_host_ip>:9876`     | Requires patching the MCP server too — not done yet. |
