---
name: blender-cli-asset-builder
description: Use to write or run deterministic .py scripts that drive headless Blender (`blender --background --python`) to produce .blend artifacts and renders. Encodes the project CLI invariant, script structure, GPU enable, and sanity-check conventions. Invoke for any tracked-source geometry, rig, material, or render work.
---

# Blender CLI Asset Builder

## When to invoke
- Writing a new `scripts/<step>.py` or `scripts/parts/<part>.py`.
- Modifying an existing script (e.g. `scripts/create_dark_fantasy_lady_blockout.py`).
- Promoting a cursor-mcp `## Promotion` block into a tracked script.
- Running any deterministic Blender step from the shell.
- Setting up a `run.sh` wrapper around the CLI invariant.
- Writing the Rigify generation script, hair grooming script, material recipe registry, or hero render driver.

## Role
The hands of the pipeline. Owns the contract that **`scripts/*.py` are the source of truth and `.blend` files in `outputs/` are regenerable build artifacts** (`orchestrator/README.md` § Premises). Every script must be re-runnable cold on a fresh checkout and produce the same `.blend`.

The skill encodes the headless-Blender CLI invariant, the script-structure conventions exemplified by `scripts/create_dark_fantasy_lady_blockout.py`, the GPU-enable snippet (necessary because `--factory-startup` wipes user prefs), and the sanity-check helpers that catch silent breakage.

## The CLI invariant (mandatory)
Every invocation:

```bash
blender --background \
        --factory-startup \
        --enable-autoexec \
        --python-exit-code 2 \
        --python scripts/<step>.py
```

Each flag exists for a reason. Do not drop any.

| Flag | Why |
|---|---|
| `--background` | No GUI. Required for cron/CI/server. |
| `--factory-startup` | Skip `userpref.blend` and `startup.blend`. Without it, whichever addons a developer enabled locally silently load on the build server. Determinism dies. |
| `--enable-autoexec` | `--factory-startup` wipes the autoexec preference back to its default ("ask"); in `--background` "ask" is treated as deny, so any rig with drivers (Rigify-generated rigs do) refuses to evaluate. This flag re-enables. |
| `--python-exit-code 2` | Default is **0** — a Python crash exits success. CI passes green on a `KeyError`. We use **2** to distinguish from Blender's own `1` (couldn't start) and shell's generic non-zero. |
| `--python <script>` | The script. |

For loading an existing `.blend` *and* running a script, order matters: `blender -b file.blend --python step.py`. CLI args evaluate in order; a `-o` set before the file load is overwritten by the file's own settings. See `docs/research/headless-blender-2026.md` § 2.1.

Add-ons that are bundled (rigify, io_scene_fbx, io_scene_gltf2, node_wrangler) can be enabled either via `--addons rigify,io_scene_fbx,io_scene_gltf2` or in-script via `bpy.ops.preferences.addon_enable(module=...)`. We prefer **in-script** so the dependency is visible in the diff.

## Script structure conventions
Anchor: `scripts/create_dark_fantasy_lady_blockout.py` is the exemplar. Every script follows this shape.

```python
import math
from pathlib import Path

import bpy
from mathutils import Vector


# Paths derived from __file__ — never hard-coded absolutes, never CWD-relative.
ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "outputs"
RENDER_DIR = OUT_DIR / "renders" / "nocturne_matriarch"
BLEND_PATH = OUT_DIR / "<step>.blend"
RENDER_PATH = RENDER_DIR / "<step>.png"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def mat(name, color, metallic=0.0, roughness=0.45, emission=None, strength=0.0):
    """Single material factory. Never duplicate this; import from a registry
    if the recipe needs to be shared across scripts."""
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if emission and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emission
            bsdf.inputs["Emission Strength"].default_value = strength
    return material


def build_<part>():
    """Each build_X function returns a list of objects it created. main()
    aggregates them for collection assignment and orphan checking."""
    objects = []
    # ... primitive adds, modifier stacks ...
    return objects


def setup_scene():
    """Render engine, samples, color management, world, lights, camera.
    Cycles + OPTIX + AgX is the project default."""
    ...


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    clear_scene()
    enable_gpu()
    objects = build_<part>()
    setup_scene()
    assert_no_orphans()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    bpy.context.scene.render.filepath = str(RENDER_PATH)
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
```

Rules:

- `pathlib.Path` from `__file__`. Never `os.getcwd()`, never absolute strings.
- `mat()` factory exists once. Material recipes (the dict of `(name, color, metallic, roughness, ...)` tuples) live in **one** place — `scripts/parts/materials.py` — and every script imports from there. Do not redefine the same material in two scripts.
- `build_<part>()` returns a list of objects. `main()` aggregates them, links to a named Collection, and unlinks from the scene's default collection.
- Object naming: **lowercase with spaces, scoped prefix**. `left pauldron spike`, `high raven collar`, `crimson chest focus`. Not `LeftPauldronSpike`, not `pauldron_l`. (`orchestrator/README.md` § Conventions.)
- `if __name__ == "__main__": main()` always.
- Render output goes to `outputs/renders/<character>/<step>.png`. `<character>` for this project is `nocturne_matriarch`.

## Modular parts
For anything bigger than a one-shot blockout, split into:

```
scripts/
├── parts/
│   ├── materials.py         # PBR recipes registered as a single dict
│   ├── body.py              # build_body() returns base mesh
│   ├── pauldrons.py         # build_pauldrons() returns [left, right]
│   ├── gorget.py
│   ├── bodice.py
│   ├── skirt.py
│   ├── cape.py
│   ├── gauntlets.py
│   ├── boots.py
│   ├── hair.py              # build_hair() with curve hair + helper bones
│   └── rig.py               # build_rig() Rigify metarig + generate
├── create_<step>.py         # composes parts into a single .blend
├── render_hero_shot.py      # loads composed .blend, sets lights/camera, renders
└── ai_gen/
    └── rodin_gen2.py        # direct Rodin Gen-2 API call (bypasses MCP wrapper)
```

Each `parts/<part>.py` exposes `build_<part>(materials: dict) -> list[bpy.types.Object]` and nothing else. No `main()` in parts files.

## GPU device enable (mandatory in scripts that render)
`--factory-startup` wipes user preferences, including the Cycles device list. Enable in script:

```python
def enable_gpu():
    prefs  = bpy.context.preferences
    cprefs = prefs.addons["cycles"].preferences
    cprefs.compute_device_type = "OPTIX"   # OPTIX > CUDA on NVIDIA
    cprefs.get_devices()                    # refresh after type change
    for d in cprefs.devices:
        d.use = (d.type in {"OPTIX", "CUDA"})
    bpy.context.scene.cycles.device     = "GPU"
    bpy.context.scene.render.engine     = "CYCLES"
    bpy.context.scene.cycles.samples    = 256
    bpy.context.scene.cycles.use_denoising = True
    bpy.context.scene.cycles.denoiser   = "OPTIX"
    # Fail loud if zero OPTIX devices were enabled (CI sanity)
    enabled = [d for d in cprefs.devices if d.use and d.type == "OPTIX"]
    assert enabled, "No OPTIX devices enabled — check NVIDIA driver / CUDA toolkit"
```

OPTIX and CUDA need only the NVIDIA driver — no X server. See `docs/research/headless-blender-2026.md` § 5.2 + § 11.2.

## Color management defaults
```python
s = bpy.context.scene
s.view_settings.view_transform = "AgX"          # 4.0+ default; better than Filmic for darks
s.view_settings.look           = "AgX - Base Contrast"
s.render.resolution_x = 2048
s.render.resolution_y = 2048
s.render.image_settings.file_format = "PNG"
```

The blockout exemplar still uses `Filmic` — fine for a throwaway preview, but production renders use AgX.

## Sanity-check helper
Every `main()` calls this before save:

```python
def assert_no_orphans():
    """Catch datablocks that were created but never linked to a collection.
    Silent orphans bloat the .blend and break diffability."""
    orphans = []
    for ob in bpy.data.objects:
        if not ob.users_collection:
            orphans.append(("object", ob.name))
    for me in bpy.data.meshes:
        if me.users == 0:
            orphans.append(("mesh", me.name))
    for ma in bpy.data.materials:
        if ma.users == 0:
            orphans.append(("material", ma.name))
    if orphans:
        raise RuntimeError(f"Orphan datablocks before save: {orphans}")
```

A failing assert returns Python exception → exit code 2 (because of `--python-exit-code 2`) → ticket goes to `failed/`. That's the desired loop.

## Run wrapper
Standard invocation, used by every shell-class ticket:

```bash
#!/usr/bin/env bash
# scripts/run.sh — single source for the CLI invariant
set -euo pipefail
SCRIPT="${1:?usage: run.sh <script.py> [extra args...]}"
shift
exec blender --background \
             --factory-startup \
             --enable-autoexec \
             --python-exit-code 2 \
             --python "$SCRIPT" \
             -- "$@"
```

Tickets call `scripts/run.sh scripts/create_dark_fantasy_lady_blockout.py`. Args after `--` reach the script via `sys.argv`.

## Procedure
1. Identify the deliverable (a `.blend` artifact, a render, or a promoted script).
2. Decide: standalone step file (`scripts/create_<step>.py`) or modular part (`scripts/parts/<part>.py`)?
3. Pull material recipes from `scripts/parts/materials.py` — never inline new ones unless adding to the registry.
4. Write the script following the structure above. `pathlib`, `mat()`, `build_X()`, `setup_scene()`, `assert_no_orphans()`, `main()`, `__main__` guard.
5. If rendering: include `enable_gpu()` and OPTIX denoiser.
6. Run via `scripts/run.sh <path>`. Verify exit code 0.
7. Inspect the produced `.blend` size and the render thumbnail. Confirm objects named correctly via `bpy.data.objects` dump if uncertain.
8. Commit the `.py`. The `.blend` and render go to `outputs/` (gitignored).

## Quality gates
- [ ] Script starts with `from pathlib import Path` + `ROOT = Path(__file__).resolve().parents[1]`.
- [ ] `if __name__ == "__main__": main()` present.
- [ ] No absolute paths hard-coded in the script body.
- [ ] All object names lowercase-with-spaces with scoped prefix.
- [ ] Material recipes imported from `scripts/parts/materials.py`, not inlined.
- [ ] `assert_no_orphans()` (or equivalent) called before save.
- [ ] `enable_gpu()` called before any render in scripts that render.
- [ ] Cold-run reproducibility: deleting `outputs/<step>.blend` and re-running `scripts/run.sh` produces a `.blend` byte-similar to the previous one (modulo timestamp differences in Blender's header).
- [ ] CLI exit code 0; non-zero halts the pipeline.

## References
- `docs/research/headless-blender-2026.md` § 2 (CLI surface), § 3 (bpy in `--background`), § 5 (rendering), § 11 (Linux specifics), § 13 (project workflow).
- `scripts/create_dark_fantasy_lady_blockout.py` — exemplar of `mat()` / `build_X()` / `setup_scene()` / `main()` shape.
- `orchestrator/README.md` § Conventions, § Source-of-truth promotion.
- `docs/fantasy-character-research.md` § "Character Production Pipeline" for which step a given script implements.
