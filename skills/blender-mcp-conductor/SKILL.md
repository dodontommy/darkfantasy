---
name: blender-mcp-conductor
description: Use to drive the live Blender MCP socket (`mcp__blender__*` tools) — pick the right tool, observe before mutating, avoid the unsandboxed `execute_blender_code` trap, and end every session with a promotion-to-script block. Invoke for any work that requires the GUI Blender on `localhost:9876`, AI 3D generation, or asset-library imports.
---

# Blender MCP Conductor

## When to invoke
- Live inspection or mutation of the running Blender on `localhost:9876`.
- AI 3D generation: Hunyuan3D 2.5 props, Rodin Sketch-tier silhouette throwaways.
- PolyHaven HDRIs / textures, Sketchfab environment props.
- Viewport screenshots for visual checkpoints.
- Any session that ends with a `## Promotion` block to be turned into a tracked script.
- Diagnosing what is currently in the scene (`get_scene_info` + `get_object_info`) before any geometry change.

## Role
The hand on the live socket. Owns the `cursor-mcp` worker class (the only worker wired to `--approve-mcps`) and the `blender-mcp.lock` flock. Decides per-tool whether it's safe, useful, and appropriate. Refuses to use the MCP server for production geometry — that path goes to `blender-cli-asset-builder` via tracked `.py`.

The vendored upstream is `ahujasid/blender-mcp` v1.5.5, FastMCP wrapper over a TCP socket. Full architecture, tool inventory, and security findings: `docs/research/blender-mcp-deep-dive.md`. Read that doc once before driving the socket; this skill is the operational tl;dr.

## The 22 mcp__blender__* tools at a glance

**Scene observation (no mutation, safe to spam):**
- `mcp__blender__get_scene_info` — name, object count, materials count, first 10 objects.
- `mcp__blender__get_object_info` — transform, materials, vert/edge/poly counts, world AABB.
- `mcp__blender__get_viewport_screenshot` — PNG up to 800px. **Requires GUI** (real `VIEW_3D` area). Fails in pure headless.

**Scene mutation (the dangerous one):**
- `mcp__blender__execute_blender_code` — `exec(code, {"bpy": bpy})` on Blender's main thread. **Unsandboxed.** Read the hard rule below before considering this.
- `mcp__blender__set_texture` — wires an already-downloaded PolyHaven texture onto a named object. Safe.

**PolyHaven (CC0 HDRIs, textures, models):**
- `mcp__blender__get_polyhaven_status` — also doubles as a liveness ping.
- `mcp__blender__get_polyhaven_categories` — `hdris` / `textures` / `models` / `all`.
- `mcp__blender__search_polyhaven_assets` — first 20 results only (hard-coded slice).
- `mcp__blender__download_polyhaven_asset` — HDRI builds full world tree; texture builds Principled BSDF with ARM/AO logic; model imports via gltf/fbx/obj/blend.

**Sketchfab (per-asset license — verify before keeping):**
- `mcp__blender__get_sketchfab_status` — validates the API key against `/v3/me`.
- `mcp__blender__search_sketchfab_models` — returns raw v3 search payload.
- `mcp__blender__get_sketchfab_model_preview` — 400–800px thumbnail; use for visual confirmation before download.
- `mcp__blender__download_sketchfab_model` — requires `target_size` (meters); zip-slip-safe, normalizes scale.

**Hyper3D Rodin (gimped — see hard rule):**
- `mcp__blender__get_hyper3d_status` — reports `enabled` + mode + key type (silently flags `free_trial`).
- `mcp__blender__generate_hyper3d_model_via_text` — text→3D, hardcoded `tier="Sketch"`, `mesh_mode="Raw"`.
- `mcp__blender__generate_hyper3d_model_via_images` — image→3D; MAIN_SITE has known base64 bug (issue #231).
- `mcp__blender__poll_rodin_job_status` — polls Rodin / fal.ai for completion.
- `mcp__blender__import_generated_asset` — downloads GLB → imports → strips Rodin's empty parent → returns AABB.

**Hunyuan3D (the strongest AI gen path through this wrapper):**
- `mcp__blender__get_hunyuan3d_status` — reports mode (`OFFICIAL_API` Tencent Cloud or `LOCAL_API` self-hosted).
- `mcp__blender__generate_hunyuan3d_model` — text or image input; LOCAL_API exposes octree/steps/guidance/texture knobs.
- `mcp__blender__poll_hunyuan_job_status` — Tencent Cloud `QueryHunyuanTo3DJob`.
- `mcp__blender__import_generated_asset_hunyuan` — downloads ZIP from arbitrary URL (SSRF surface; restrict in prompt), extracts, imports OBJ.

## Hard rules (non-negotiable)

### 1. NEVER use `mcp__blender__execute_blender_code` for production geometry
It is `exec(code, {"bpy": bpy})` with no `__builtins__` override. The model can `import os`, `import subprocess`, `import socket`, read `~/.ssh`, write anywhere, open arbitrary sockets — full RCE under the Blender user (`docs/research/blender-mcp-deep-dive.md` § Security Posture, issue #207).

Allowed uses:
- One-shot **read-only** inspection when no structured tool covers the question (e.g. dumping a modifier stack as JSON).
- Emergency one-off fixes during a live debugging session, **with the .blend saved beforehand**.

Never:
- Build geometry the project will keep.
- Loop over thousands of vertices.
- Touch the filesystem outside `outputs/`.
- Anything that would belong in a tracked `.py`. Write the `.py` instead and run it via `blender-cli-asset-builder`.

### 2. ALWAYS observe before mutating
Every session starts:

```
mcp__blender__get_scene_info()
# then for any object you intend to modify:
mcp__blender__get_object_info(object_name="...")
```

Skipping this is how you delete the wrong thing. The `asset_creation_strategy` prompt that ships with the server enforces this — follow it.

### 3. Rodin via this wrapper is gimped — NOT for hero base mesh
The vendored addon hardcodes `tier="Sketch"` + `mesh_mode="Raw"`. Sketch is the lowest tier: triangulated, low-poly, auto UVs, no T-pose enforcement. Acceptable for **silhouette throwaways** during phase-2 concept iteration. Unacceptable for the hero character body.

For the Nocturne Matriarch hero base mesh (phase 3), bypass this MCP wrapper entirely. Call Rodin Gen-2 directly:

```
tier="Gen-2"
mesh_mode="Quad"          # 18k or 50k quad topology
T_pose=true
```

The implementation belongs in `scripts/ai_gen/rodin_gen2.py` (TODO — not yet written; flag at start of phase 3). Endpoint and auth: `developer.hyper3d.ai/api-specification/rodin-generation-gen2`. Cross-reference `docs/research/ai-3d-generation-2026.md`.

### 4. Hunyuan3D 2.5 IS usable for character props
For pauldrons, gorget, crown, dagger, jewelry, weapons — Hunyuan3D 2.5 in `LOCAL_API` mode (self-hosted server) is the strongest path through this wrapper. Topology is implicit-surface marching cubes (will need retopo for any deforming part), but PBR multi-view paint is genuinely good and the shells are sharper than Rodin Sketch.

Typical flow:

```
mcp__blender__get_hunyuan3d_status()
# → mode: LOCAL_API, base_url: http://localhost:8081

mcp__blender__generate_hunyuan3d_model(
  text_prompt="ornate dark-elven pauldron, asymmetric upturned spike crown form, blackened steel with tarnished gold trim, single small violet gem at the apex"
)
# → returns job_id

mcp__blender__poll_hunyuan_job_status(job_id="job_...")
# poll until status: done, capture zip_file_url from ResultFile3Ds

mcp__blender__import_generated_asset_hunyuan(
  name="right pauldron raw",
  zip_file_url="<from poll response>"
)
# imports OBJ + MTL + textures, returns world AABB
```

After import: `mcp__blender__get_object_info(object_name="right pauldron raw")` to verify scale and bounds. Manually retopologize before any rig binding.

### 5. PolyHaven and Sketchfab — environments, not characters
- **PolyHaven**: CC0, no attribution required. Use for HDRIs (cathedral, twilight, moonlit), ground/stone textures, small environment props. Does not have characters.
- **Sketchfab**: per-asset licenses (CC-BY, CC-BY-NC, CC-BY-ND, Standard, Editorial). The wrapper does not filter by license — *manually verify each asset's `license.label` is CC0 or CC-BY before keeping it*. Realistic-character results on Sketchfab are mostly scans with restrictive licenses or NSFW spam — do not source the Matriarch herself from there. Use for environment props (chandeliers, candelabras, gothic arches).

### 6. Promotion-to-script loop
Every session ends with a `## Promotion` block in the worker log: the bpy operations the model ran, ready for paste into a tracked `.py`. The orchestrator follow-up ticket (`promote-mcp-session`) turns it into `scripts/parts/<part>.py`. Headless re-run produces a near-identical `.blend`. Diff parity is the verification.

If you cannot produce a clean Promotion block — because too much was done via interactive `execute_blender_code` calls — you violated rule 1. Save the .blend, take a screenshot, and re-do the work from a tracked script.

See `orchestrator/README.md` § "Source-of-truth promotion (MCP → script)".

### 7. Headless caveats
The MCP server **needs a live GUI Blender** on `localhost:9876` — `bpy.ops.screen.screenshot_area` and the addon registration both require an event loop and a real screen. On a headless Linux host, two options (`orchestrator/README.md` § "Running on a headless host"):

- **Xvfb**: `xvfb-run -a blender` in the `blender` tmux window. Slow; viewport screenshot returns black unless GPU is wired through EGL.
- **SSH reverse tunnel** (recommended): run Blender on a Windows / macOS workstation, then from that machine `ssh -R 9876:localhost:9876 user@<linux-host>`. Linux-side `uvx blender-mcp` connects to the tunnel. The flock still works (lives on Linux).

There is no documented "fully headless blender-mcp" recipe upstream as of May 2026 (`docs/research/blender-mcp-deep-dive.md` § Headless Story). Don't try to invent one.

### 8. Telemetry off
Always launch the server with:

```bash
env DISABLE_TELEMETRY=true uvx blender-mcp
```

Default is on, which ships prompts and code text to a third-party Supabase project. We do not leak Matriarch WIP to a third party.

### 9. Host config patch
The vendored `blender-mcp` reads `BLENDER_HOST` / `BLENDER_PORT` from env. The remote-Blender pattern (rule 7) needs `BLENDER_HOST` driven from the SSH-tunnel config. The env-driven host patch lives at `patches/blender-mcp/` (small wrapper). Source it before launching `uvx blender-mcp` when working remote.

## Procedure
1. Acquire the lock: workers do this via `flock -w 120 orchestrator/locks/blender-mcp.lock`. If you're driving manually, dispatch through the `worker-mcp-1` tmux window.
2. `mcp__blender__get_scene_info` — confirm what's loaded. If nothing useful, abort and check that GUI Blender is actually running and the N-panel "Connect to MCP server" toggle is on.
3. For each named object you'll touch: `mcp__blender__get_object_info`.
4. Pick the right tool from the inventory above. Avoid `execute_blender_code` unless rule 1 explicitly allows.
5. For AI gen: status → generate → poll → import → `get_object_info` to verify scale and bounds.
6. Take a `mcp__blender__get_viewport_screenshot` checkpoint before and after any visible change.
7. Save the .blend (`execute_blender_code` with a one-line `bpy.ops.wm.save_as_mainfile(filepath="...")` is the rare allowed use of that tool).
8. End with a `## Promotion` block: every meaningful bpy op, in order, ready to paste into `scripts/parts/<part>.py`. Hand off to `blender-cli-asset-builder` via a `promote-mcp-session` ticket.
9. Release the lock (worker exit does this automatically).

## Quality gates
- [ ] Session opened with `get_scene_info` + `get_object_info` for every targeted object.
- [ ] `execute_blender_code` not used for production geometry; if used at all, the .blend was saved first and the call is read-only or a one-line save.
- [ ] No Rodin generation used as the hero base mesh path (only as throwaway concept iteration).
- [ ] Any Hunyuan3D import was followed by `get_object_info` to verify world AABB.
- [ ] Any Sketchfab download had its `license.label` manually verified (CC0 or CC-BY).
- [ ] `DISABLE_TELEMETRY=true` confirmed in the env that launched `uvx blender-mcp`.
- [ ] Session ended with a complete `## Promotion` block; promotion ticket dispatched.
- [ ] `worker-mcp-1` released the flock (no stale `in_progress/` ticket).

## References
- `docs/research/blender-mcp-deep-dive.md` — full tool inventory (§ Tool Inventory), security posture (§ Security Posture), Rodin gimping (§ Hyper3D Rodin Integration), Hunyuan3D 2.5 path (§ Hunyuan3D Integration), headless caveats (§ Headless Story), per-phase recommended use (§ Recommended Use for the Nocturne Matriarch).
- `docs/research/ai-3d-generation-2026.md` — Rodin Gen-2 direct API spec.
- `orchestrator/README.md` § "Worker classes", § "Source-of-truth promotion", § "Running on a headless host", § "Safety notes".
- `patches/blender-mcp/` — env-driven host patch for the SSH-tunnel pattern.
