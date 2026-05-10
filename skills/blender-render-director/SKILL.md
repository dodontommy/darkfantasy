---
name: blender-render-director
description: Set up Blender 4.x renders — engine choice (Cycles+OPTIX vs EEVEE-Next), 3-point noble portrait lighting, AgX color management, 70mm camera framing, compositor stack. Invoke when authoring or fixing render setup in build scripts.
---

# Blender Render Director

## When to invoke
- New render script needs engine, lighting, camera, color management, and compositor wired up.
- Existing render reads as flat / waxy skin / blown highlights / muddy blacks / desaturated reds.
- Headless run needs OPTIX explicitly enabled (because `--factory-startup` wipes prefs).
- Composing a "noble portrait" hero shot for the Nocturne Matriarch or any successor character.
- Verifying samples / denoise / filepath discipline before a long render.

## Role
Encodes Part D of `docs/research/dark-fantasy-shading-pipeline.md`, the headless render specifics from `docs/research/headless-blender-2026.md` §5, and the Lineage-2 noble-pose framing from `docs/research/lineage2-art-style.md`. Persona: a render lead who already knows Filmic crushes the wine and crimson palette toward yellow (Notorious Six failure) and refuses to ship anything but AgX Punchy on this project; who bakes the OPTIX device enable into every render script because `--factory-startup` is non-negotiable for CI.

## Procedure

### 1. Engine decision matrix

| Need | Engine | Why |
|---|---|---|
| Hero portrait, final still, anything skin-critical | **Cycles + OPTIX** + denoise | Random Walk Skin SSS, Principled Hair BSDF dispersion, gem caustics. EEVEE-Next still cannot match. |
| Look-dev iteration on the GUI workstation | **EEVEE-Next** | Fast; 4.5's raytraced shadows + light linking close ~70% of the prior gap. |
| Asset thumbnails / matcap previews | Workbench (`-E BLENDER_WORKBENCH`) | Cheap, deterministic. |
| Character preview | **Never Workbench** for character review | Loses every shading nuance the project depends on. |
| Headless server, no display | Cycles + OPTIX (always works) OR EEVEE-Next via EGL on 4.2+ | OPTIX/CUDA need only NVIDIA driver, no X. |

For Nocturne Matriarch outputs/renders/: Cycles + OPTIX, 32 samples for previews, 256 samples for finals (per §5 quality gate; brief calls 1024 for absolute hero stills).

### 2. The OPTIX enable snippet (mandatory in every render script)

`--factory-startup` ignores user prefs, so the OPTIX device list is empty by default. Enabling devices via `--cycles-device OPTIX` after `--` is not enough — `cprefs.devices` must be populated and `.use=True`. Bake this into every script:

```python
import bpy

def enable_optix(prefer="OPTIX"):
    cprefs = bpy.context.preferences.addons["cycles"].preferences
    cprefs.compute_device_type = prefer        # "OPTIX" | "CUDA" | "HIP" | "ONEAPI" | "METAL"
    cprefs.get_devices()                        # required after changing compute_device_type
    enabled = 0
    for d in cprefs.devices:
        d.use = (d.type in {"OPTIX", "CUDA", "HIP", "ONEAPI", "METAL"})
        enabled += int(d.use)
    if enabled == 0:
        raise RuntimeError(f"No {prefer} devices available — refusing to fall back to CPU silently.")
    bpy.context.scene.render.engine    = "CYCLES"
    bpy.context.scene.cycles.device    = "GPU"
    bpy.context.scene.cycles.use_denoising = True
    bpy.context.scene.cycles.denoiser  = "OPTIX"
    return enabled
```

Fail loud if no GPU is available. A silent CPU fallback at 256 samples on a 4K hero render is the kind of mistake that wastes a whole CI cycle.

### 3. Noble portrait lighting recipe

Three lights plus a tiny gem practical plus a near-black world. From `dark-fantasy-shading-pipeline.md` D2; energies tuned for an 1.8 m subject at 1.2–2.5 m camera distance.

| Light | Type | Position (relative to subject at origin) | Color | Energy | Notes |
|---|---|---|---|---|---|
| Key | Area 60×60 cm | Camera-left, 35° above eye, 1.2 m | 5200 K → `#FFE4C4` | 200 W | Soft skin shaping, slight warm. |
| Fill | Area 100×100 cm | Camera-right, eye level, 2.5 m | 6500 K → `#D6E4FF` | 25 W | Cool fill — pushes red shadows in skin. |
| Rim | Spot, 25° cone | Behind, opposite key, 30° above | 8000 K → `#A8C4FF` (cool steel) — Nocturne ceremonial; OR 3200 K → `#FFB070` (warm candle) — funereal/villainous | 600 W narrow | Defines hair edge and pauldron silhouette. |
| Practical | Tiny Area | Near the gem, 5 cm offset | matches gem hex `#FF1424` | 2 W | Sells the focal gem. |
| World | dim background | — | `#0A0810` solid OR HDRI at 0.05 strength | — | Near-black ambient. |

Project brief for Nocturne Matriarch uses a **crimson rim** (`#E60D14` accent at ~95 W) instead of the cool-steel rim — that is the existing blockout's choice (`scripts/create_dark_fantasy_lady_blockout.py` line 165) and matches the focus-gem palette. Documented as the "warm rim / cool key funereal variant" in D2 — both are valid; the crimson is the project default.

Combo rules:
- Cool rim + warm key = ceremonial (high-noble portrait).
- Warm/crimson rim + cool key = funereal/villainous (Nocturne Matriarch default).

### 4. AgX color management — mandatory

```python
def setup_color_management(scene):
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look           = "AgX - Punchy"
    scene.view_settings.exposure       = -0.4         # darker mood; tighten to -0.7 for funereal
    scene.view_settings.gamma          = 1.0
    scene.display_settings.display_device = "sRGB"
```

Why not Filmic: Filmic crushes saturated reds and blues toward yellow (the "Notorious Six" failure). The crimson focus gem `#FF1424` and the wine cloth sheen `#6A0F1A` both sit in the failure region; AgX preserves them. AgX has been the Blender default since 4.0 — anyone leaving the scene at `Filmic / Medium High Contrast` is using a pre-4.0 default and should be corrected.

For HDR delivery, AgX has Rec.2100-PQ and HLG variants (added 4.x).

### 5. Camera setup — 70mm noble framing

From `lineage2-art-style.md` (raised cheekbones + long neck + tapered jaw need a slightly low camera to push the noble silhouette) and the existing blockout's ortho preview at `ortho_scale=4.75`:

```python
def setup_camera_noble_portrait(scene, mode="perspective"):
    import math
    bpy.ops.object.camera_add(location=(0, -3.2, 1.55))
    cam = bpy.context.object
    cam.name = "noble portrait camera"
    if mode == "perspective":
        cam.data.type        = "PERSP"
        cam.data.lens        = 70                  # 70mm — flatters the face, compresses depth
        cam.data.sensor_width = 36
        cam.rotation_euler   = (math.radians(90 - 15), 0, 0)   # 15° below eye — "noble / dangerous"
    else:                                          # ortho preview, matches existing blockout
        cam.data.type        = "ORTHO"
        cam.data.ortho_scale = 4.75
        cam.rotation_euler   = (math.radians(90), 0, 0)
    scene.camera = cam
    return cam
```

Eye level z = 1.7 m (8 heads × ~0.21 m head). The 15° tilt below eye line is the L2-key-art "look up at the noble" pose. For ortho full-body preview keep `ortho_scale = 4.75` to match the existing blockout — comparing successive milestones requires an unchanged camera.

### 6. Render output structure

Never overwrite previous milestones. The orchestrator's review loop relies on diffable PNG history.

```
outputs/
  renders/
    <character>/
      00_blockout_front.png
      01_costume_pass_front.png
      02_hair_pass_front.png
      ...
      <step>_<view>.png            # always two-token: step + view
```

In script:

```python
RENDER_DIR  = ROOT / "outputs" / "renders" / character_slug
RENDER_PATH = RENDER_DIR / f"{step:02d}_{view}.png"
RENDER_DIR.mkdir(parents=True, exist_ok=True)
scene.render.filepath = str(RENDER_PATH)
```

Step numbers monotonically increase. Ask the user before reusing a number.

### 7. Compositor stack

Minimum stack per D4. Bloom only on emissions, slight chromatic aberration, vignette, subtle split toning.

```
Render Layers
  → Glare         (Bloom; Threshold 1.0, Size 7, Mix 0.0)        # blooms gem + rim glints only
  → Lens Distortion (Distortion 0.0, Dispersion 0.015)            # cheap chromatic aberration in 4.x
  → Mix RGB       (Multiply, vignette mask: radial gradient,
                   inner radius 0.55, outer 1.05, soft falloff)
  → Color Balance (Lift slightly cool #E0E8FF, Gamma 1.0,
                   Gain slight warm #FFF4E0)
  → File Output
```

Blender 5.0 has a native **Chromatic Aberration node** — when the project moves to 5.0, replace the Lens Distortion trick with `ChromaticAberration: Amount 0.6, Type Spectral`. We are on 4.5 LTS, so use the Lens Distortion workaround.

Optional finishing: faint film-grain Noise (scale 1.0 in screen space, multiply 0.03), square LUT pass with subtle teal-and-gold split toning.

### 8. Setup-it-all snippet

A single callable that sets engine + GPU + lights + camera + color management + compositor for the standard noble portrait. Drop into any render script.

```python
def setup_noble_portrait_render(scene, *, samples=256, mode="perspective", rim_variant="crimson"):
    """
    rim_variant: "crimson" (Nocturne default), "cool_steel" (ceremonial), "warm_candle" (intimate).
    """
    import math

    enable_optix("OPTIX")
    scene.cycles.samples            = samples
    scene.cycles.adaptive_threshold = 0.01
    scene.cycles.time_limit         = 600          # safety net, seconds per frame
    scene.render.resolution_x       = 1400
    scene.render.resolution_y       = 1800
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_depth = "16"

    setup_color_management(scene)
    if scene.world is None:
        scene.world = bpy.data.worlds.new("noble portrait world")
    scene.world.color = (0.040, 0.032, 0.040)      # ~#0A0810 linear-ish

    # KEY
    bpy.ops.object.light_add(type="AREA", location=(-2.4, -3.5, 4.2))
    key = bpy.context.object; key.name = "key — large softbox"
    key.data.energy = 200; key.data.size = 0.6
    key.data.color  = (1.0, 0.894, 0.768)          # 5200 K #FFE4C4

    # FILL
    bpy.ops.object.light_add(type="AREA", location=(2.6, -3.0, 1.7))
    fill = bpy.context.object; fill.name = "fill — cool"
    fill.data.energy = 25; fill.data.size = 1.0
    fill.data.color  = (0.839, 0.894, 1.0)         # 6500 K #D6E4FF

    # RIM
    bpy.ops.object.light_add(type="SPOT", location=(1.8, 1.6, 2.7))
    rim = bpy.context.object; rim.name = f"rim — {rim_variant}"
    rim.data.spot_size = math.radians(25)
    if rim_variant == "crimson":                   # Nocturne Matriarch default
        rim.data.energy = 95
        rim.data.color  = (0.9, 0.05, 0.04)        # #E60D14 accent
    elif rim_variant == "cool_steel":
        rim.data.energy = 600
        rim.data.color  = (0.659, 0.768, 1.0)      # 8000 K #A8C4FF
    elif rim_variant == "warm_candle":
        rim.data.energy = 600
        rim.data.color  = (1.0, 0.690, 0.439)      # 3200 K #FFB070

    # GEM PRACTICAL
    bpy.ops.object.light_add(type="AREA", location=(0, -0.30, 2.62))
    gem_l = bpy.context.object; gem_l.name = "practical — gem"
    gem_l.data.energy = 2; gem_l.data.size = 0.05
    gem_l.data.color  = (1.0, 0.078, 0.141)        # gem #FF1424

    setup_camera_noble_portrait(scene, mode=mode)
    setup_compositor(scene)
    return scene


def setup_compositor(scene):
    scene.use_nodes = True
    tree = scene.node_tree
    tree.nodes.clear()
    rl  = tree.nodes.new("CompositorNodeRLayers")
    glr = tree.nodes.new("CompositorNodeGlare")
    glr.glare_type = "BLOOM" if hasattr(glr, "glare_type") else "FOG_GLOW"
    glr.threshold  = 1.0
    glr.size       = 7
    glr.mix        = 0.0
    lens = tree.nodes.new("CompositorNodeLensdist")
    lens.inputs["Distortion"].default_value = 0.0
    lens.inputs["Dispersion"].default_value = 0.015
    out = tree.nodes.new("CompositorNodeComposite")
    tree.links.new(rl.outputs["Image"], glr.inputs["Image"])
    tree.links.new(glr.outputs["Image"], lens.inputs["Image"])
    tree.links.new(lens.outputs["Image"], out.inputs["Image"])
    # Vignette + Color Balance left as a manual pass; keep this snippet minimal
    # so the compositor can be inspected in the GUI before adding split toning.
```

Call from a build script:

```python
if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    clear_scene()
    build_character()
    add_ground()
    setup_noble_portrait_render(bpy.context.scene, samples=256, mode="perspective", rim_variant="crimson")
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    bpy.context.scene.render.filepath = str(RENDER_PATH)
    bpy.ops.render.render(write_still=True)
```

### 9. Headless invocation

Per `docs/research/headless-blender-2026.md` §2 / §13:

```bash
$BLENDER_BIN --background --factory-startup --enable-autoexec \
    --python-exit-code 2 \
    --addons io_scene_fbx,io_scene_gltf2,node_wrangler \
    --python scripts/render_noble_portrait.py
```

Argument-order rule: file must come before `-o` / `-F` flags or scene settings overwrite them. For pure-script render the `-o`/`-F` flags are unnecessary because `setup_noble_portrait_render` sets everything in code.

`--python-exit-code 2` is mandatory — without it, a Python crash in the render script returns 0 and the orchestrator marks the ticket green.

## Quality gates

- [ ] `scene.render.engine == "CYCLES"`, `scene.cycles.device == "GPU"`.
- [ ] `enable_optix("OPTIX")` returned ≥ 1; no silent CPU fallback.
- [ ] `scene.cycles.samples` ≥ 32 for previews, ≥ 256 for finals (1024 for absolute hero stills).
- [ ] `scene.cycles.use_denoising = True`, `scene.cycles.denoiser = "OPTIX"`.
- [ ] `scene.view_settings.view_transform == "AgX"`, `look == "AgX - Punchy"`, `exposure == -0.4` (or -0.7 for funereal).
- [ ] World colour ≈ `#0A0810` (not white, not pure black).
- [ ] Three lights present (key / fill / rim) plus optional gem practical; rim variant matches shot intent.
- [ ] Camera lens 70 mm OR ortho_scale 4.75; tilt 15° below eye line for hero portrait.
- [ ] Render path under `outputs/renders/<character>/<step>_<view>.png`; no overwriting previous milestone.
- [ ] Compositor: bloom on emissions, lens distortion dispersion 0.015, vignette mask present.
- [ ] No fireflies in dark areas after denoise — if present, raise `cycles.adaptive_threshold` floor or sample count.
- [ ] If headless: `--python-exit-code 2` set on the CLI invocation.

## References

- `docs/research/dark-fantasy-shading-pipeline.md` Part D (D1 engine matrix, D2 noble-portrait lighting, D3 AgX color management, D4 compositor stack) — primary source for every Kelvin temperature, hex code, and node value above.
- `docs/research/headless-blender-2026.md` §5 (Cycles GPU enable, EEVEE-Next on EGL, sample/denoise presets), §2 (CLI flags, `--python-exit-code` discipline), §13 (recommended pipeline pattern for this project).
- `docs/research/lineage2-art-style.md` §7 (noble face framing rationale: high cheekbones + long neck want a slightly low camera angle), §1.6 (Throne and Liberty 70mm-equivalent key-art conventions).
- `scripts/create_dark_fantasy_lady_blockout.py` lines 146–173 — existing `setup_scene` to migrate; keep `ortho_scale = 4.75` for the preview camera so milestone diffs stay valid.
- `skills/blender-shader-builder/SKILL.md` §8 — colour management is set there too; this skill is the authoritative call site.
