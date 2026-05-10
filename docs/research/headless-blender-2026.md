# Headless Blender for Character Modeling, May 2026

A technical reference for driving Blender from the CLI (`--background --python ...`) on a Linux server with no display, with notes on the GUI-only escape hatches we still need (MCP socket, sculpt brush input, asset preview generation).

This document is current to **Blender 5.0** (released 2025-11-18) and **Blender 4.5 LTS** (released 2025-07-15). Where the project is currently pinned to **4.0.2**, the differences are flagged inline.

---

## 1. Release-state matrix as of May 2026

| Version | Released | LTS? | Status May 2026 | Why we care |
|---|---|---|---|---|
| 4.0 | 2023-11-14 | no | EOL | Principled BSDF v2, Light Linking, Bone Collections introduced. Our pinned baseline (`/usr/bin/blender` is 4.0.2). |
| 4.1 | 2024-03-26 | no | EOL | Nested bone collections, hair node tools, geometry nodes for hair maturing. |
| 4.2 LTS | 2024-07-16 | yes | supported through Jul 2026 | EEVEE-Next default, Extension platform replaces legacy add-on installer, headless EEVEE via EGL on Linux. |
| 4.3 | 2024-11-19 | no | EOL | Grease Pencil 3 rewrite (irrelevant to us), Geometry Nodes for hair improvements. |
| 4.4 | 2025-03-18 | no | EOL | "Winter of Quality" stability pass, Action Slots (animation data refactor), CPU compositor rewrite, Vulkan backend usable. |
| 4.5 LTS | 2025-07-15 | yes | **current LTS, supported through Jul 2027** | Vulkan reaches parity with OpenGL, faster trim/sculpt, brush asset duplication, deferred texture loading. |
| 5.0 | 2025-11-18 | no | current stable | Major bump with breaking Python API changes (legacy Action API removed, PointCache.compression removed, Image.bindcode removed, file-output-node slots renamed, mathutils default to float32). |
| 5.1 | shipped early 2026 | no | corrective releases ongoing | Mostly bugfix continuation of 5.0. |

For a headless character pipeline that needs a stable bpy surface for **2 years** with no surprise breakage, **4.5 LTS is the correct target**. 5.0 is fine for greenfield projects but its legacy-Action-API removal and float32 mathutils change will silently break code written against 4.x.

---

## 2. The CLI surface

### 2.1 Flags relevant to headless work

These are the flags actually used in scripted character pipelines. Authoritative reference: `blender --help` on the installed binary, plus the [Command Line Arguments](https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html) page.

```
-b, --background              Run without UI. Required for any cron/CI/server use.
-P, --python <file>           Run a Python script file after startup.
--python-expr <expr>          Run a one-liner Python expression.
--python-text <name>          Run a TEXT datablock from inside the .blend.
--python-exit-code <N>        On uncaught Python exception, exit with code N
                              (default 0 — yes, by default a script crash is
                              silent. Always set this in CI: --python-exit-code 1).
--python-use-system-env       Honour PYTHONPATH and PYTHONHOME from the shell
                              (off by default; bpy uses bundled python).
--addons a,b,c                Comma-separated add-ons to enable for this run.
--factory-startup             Skip startup.blend and userpref.blend. Required for
                              deterministic builds — otherwise local user prefs
                              leak into the run.
--enable-autoexec / -y        Allow drivers and embedded scripts in .blend files
                              to run. Required if you load assets that ship with
                              drivers (most rigs do).
--disable-autoexec / -Y       Refuse to run embedded scripts (default since
                              2.91 for "untrusted" .blends).
-E, --engine {CYCLES|BLENDER_EEVEE_NEXT|BLENDER_WORKBENCH}
                              Override the engine in the .blend.
                              (4.2+: 'BLENDER_EEVEE' is the legacy 4.1 engine,
                              'BLENDER_EEVEE_NEXT' is the new one. 4.5+ alias
                              both to 'BLENDER_EEVEE_NEXT'. 5.0 drops the old
                              EEVEE entirely.)
-o, --render-output <path>    Output prefix; '#' becomes frame-number padding.
-F, --render-format <fmt>     PNG / JPEG / OPEN_EXR / FFMPEG / etc.
-x, --use-extension {0|1}     Auto-append file extension.
-f, --render-frame N          Render single frame (also: '+5', '-5', '1,5,10', '1..5').
-a, --render-anim              Render the full frame range from the .blend.
-s, -e, -j                    Frame start, end, step.
-S, --scene <name>            Pick a non-active Scene from the .blend.
-t, --threads N               CPU thread cap (0 = all).
--gpu-backend {opengl|vulkan|metal|none}
                              Pick the viewport/GPU module backend (4.4+; in 4.0
                              this flag does not exist — opengl is hardcoded).
--cycles-device {CPU,CUDA,OPTIX,HIP,ONEAPI,METAL[+CPU]}
                              Cycles compute device. Goes AFTER a '--' separator,
                              e.g. 'blender -b ... -- --cycles-device OPTIX'.
--debug                       General debug mode; preserves stdin for python.
--debug-cycles                Cycles-internal logging.
--debug-gpu                   GPU module logging (very verbose).
--log <pattern>               Enable log categories, supports * and ^ negation.
--log-level N                 -1 = everything; otherwise verbosity.
--log-file <path>             Tee logs to file in addition to stderr.
--env-system-scripts <path>   Override BLENDER_SYSTEM_SCRIPTS for this run.
--app-template <name>         Pick an alternate startup template.
--command extension <subcmd>  4.2+: install/list/sync/remove extensions from CLI.
```

Two argument-ordering rules trip everyone up:

1. **CLI args are evaluated in order.** `blender -o /tmp/x_### -F PNG file.blend -a` does not render anything because output and format were set before the file was loaded and overwritten by the file's own settings. Correct order: `blender -b file.blend -o /tmp/x_### -F PNG -a`.
2. **Anything after `--` is passed to your script** via `sys.argv`. Cycles device flags are an exception — they are parsed by Blender itself but live after `--` for historical reasons.

### 2.2 Exit codes

Blender's own exit codes are essentially `0` for success and `1` for "couldn't even start." A Python uncaught exception **does not change the exit code unless `--python-exit-code` is set**. CI scripts must always include `--python-exit-code 1` (or higher), or hidden script failures will pass green.

### 2.3 Determinism

For reproducible character builds, every CLI invocation should pin:

```
blender --factory-startup --enable-autoexec --python-exit-code 2 \
        --background path/to/seed.blend \
        --python build_step.py -- --seed 42 --out /work/out
```

`--factory-startup` is non-negotiable for CI. Without it, `~/.config/blender/4.5/config/userpref.blend` (Linux path; see §11) gets read, and any addon a developer enabled locally will silently load on the build server.

---

## 3. bpy in `--background`: what works, what doesn't

Blender's Python API runs almost entirely in `--background`, with a handful of well-known holes.

### 3.1 What does work headlessly

- All of `bpy.data.*` (data-block CRUD).
- All modifiers (add, configure, `object.modifier_apply`).
- Cycles render including GPU.
- Geometry Nodes graphs evaluation and modifier application.
- Mesh edits via `bmesh`.
- Sculpt **operators** that don't depend on a 3D-View region (voxel remesh, multires subdivide, mask-by-color etc. — they need an active object in OBJECT or SCULPT mode).
- Add-on enable/disable.
- USD / glTF / FBX / OBJ / Alembic import and export.
- Asset library traversal via `bpy.types.AssetRepresentation` and `bpy.context.preferences.filepaths.asset_libraries`.

### 3.2 What does **not** work or is fragile

- Modal operators (anything with `INVOKE_DEFAULT`): brush strokes, transform with mouse drag, knife tool. They abort because there is no event loop.
- Operators that `poll()` for an `area.type == 'VIEW_3D'`: many sculpt brush strokes, some grease-pencil ops, some add-mesh primitives placed via gizmos.
- EEVEE rendering on Linux **before 4.2** without an X server. (4.2+ uses EGL on Linux and works headlessly out of the box. 4.0.2 still requires `xvfb-run`.)
- `bpy.context.window`, `bpy.context.screen`, `bpy.context.area` are all `None` in `--background`. Anything that walks `window_manager.windows` will iterate an empty collection.
- `gpu.types.GPUOffScreen` requires a live GL context — it works in `--background` if the build initialised one (4.2+ on EGL), but the older "draw the viewport into an offscreen" pattern is brittle.
- Asset previews: thumbnails are normally generated by the GUI's preview worker. In `--background`, you must regenerate via `bpy.ops.ed.lib_id_generate_preview()` (see §8) and the call only works after the data-block is selected.

### 3.3 `bpy.context.temp_override` (3.2+)

Since Blender 3.2, the dict-passed `bpy.ops.foo({"area": area, ...}, ...)` form is deprecated. Use the context manager:

```python
import bpy

def find_area(window, area_type):
    for a in window.screen.areas:
        if a.type == area_type:
            return a
    return None

# In headless mode, window_manager.windows is empty, so this loop is skipped.
# To force an area to exist, you can spawn a temporary one:
with bpy.context.temp_override(
    window=bpy.context.window_manager.windows[0] if bpy.context.window_manager.windows else None,
    area=find_area(bpy.context.window_manager.windows[0], 'VIEW_3D')
        if bpy.context.window_manager.windows else None,
    region=None,
    active_object=bpy.data.objects['Body'],
    selected_objects=[bpy.data.objects['Body']],
    selected_editable_objects=[bpy.data.objects['Body']],
):
    bpy.ops.object.voxel_remesh()
```

In `--background` you usually don't have a window at all, so the safer pattern is to override only the data members the operator needs:

```python
ob = bpy.data.objects['Body']
with bpy.context.temp_override(active_object=ob, object=ob,
                               selected_objects=[ob],
                               selected_editable_objects=[ob]):
    bpy.ops.object.voxel_remesh()
```

The rule: read the operator's source (or `bpy.ops.object.voxel_remesh.poll()`) and override exactly the members its `poll` requires. If it needs `area.type == 'VIEW_3D'`, you cannot run it `--background`; you need a parallel data-API path. A growing community workaround is the third-party `ContextWizard` helper, which auto-fills required context keys.

---

## 4. Headless sculpting

### 4.1 Voxel remesh

```python
ob = bpy.data.objects['Body']
ob.data.remesh_voxel_size = 0.005   # 5 mm at world scale
ob.data.remesh_voxel_adaptivity = 0.0
ob.data.use_remesh_fix_poles = True
ob.data.use_remesh_preserve_volume = True

with bpy.context.temp_override(active_object=ob, object=ob,
                               selected_objects=[ob],
                               selected_editable_objects=[ob]):
    bpy.ops.object.voxel_remesh()
```

`bpy.ops.object.voxel_remesh()` works in `--background`. It blows away vertex groups, shape keys, UV maps and all custom data layers — capture them first if needed. (The Remesh **modifier** preserves the original mesh and is the safer choice when you want non-destructive remesh in a script-driven pipeline; use `RemeshModifier` with `mode='VOXEL'` and `voxel_size`.) In 4.5+ the trim solver gained a 'manifold' fast path; voxel remesh itself is unchanged.

### 4.2 Multires

Multires can be added and subdivided headlessly:

```python
md = ob.modifiers.new("MR", type='MULTIRES')
with bpy.context.temp_override(active_object=ob, object=ob):
    for _ in range(4):
        bpy.ops.object.multires_subdivide(modifier="MR", mode='CATMULL_CLARK')
```

Sculpting **strokes** on multires require a 3D-View region and a brush event stream — they cannot be driven from `--background`. Instead, drive deformation from displacement textures: `bpy.ops.object.multires_external_save()` / `multires_reshape_apply()` and texture-based displacement modifiers can be set up in script.

### 4.3 Dyntopo

Dyntopo lives entirely in sculpt mode and depends on a brush stroke event stream — it has no useful headless surface. Use voxel remesh instead.

---

## 5. Headless rendering

### 5.1 Cycles vs EEVEE

| Need | Use |
|---|---|
| GPU path tracing on a no-display Linux server | **Cycles** with OPTIX or CUDA. Works completely headlessly. |
| Real-time look-dev / cheap turntables | EEVEE-Next on Blender 4.2+ via EGL. On 4.0.2 you need `xvfb-run`. |
| Quick asset thumbnails / matcap previews | Workbench (`-E BLENDER_WORKBENCH`). Cheap, deterministic. |

### 5.2 Configuring Cycles GPU from Python

The flag `--cycles-device OPTIX` after `--` is sufficient *if* the user pref already has OPTIX devices enabled. In `--factory-startup` runs (which we always want), you must enable devices in script:

```python
import bpy

prefs  = bpy.context.preferences
cprefs = prefs.addons["cycles"].preferences
cprefs.compute_device_type = "OPTIX"   # or "CUDA", "HIP", "ONEAPI", "METAL"

# Refresh device list — required after changing compute_device_type
cprefs.get_devices()

# Enable every GPU device, leave CPU off (or include it for OPTIX+CPU hybrid)
for d in cprefs.devices:
    d.use = (d.type in {"OPTIX", "CUDA", "HIP", "ONEAPI", "METAL"})

bpy.context.scene.cycles.device = "GPU"
bpy.context.scene.render.engine  = "CYCLES"
bpy.context.scene.cycles.samples = 256
bpy.context.scene.cycles.use_denoising = True
bpy.context.scene.cycles.denoiser = "OPTIX"      # needs OPTIX device
```

OPTIX and CUDA need only the NVIDIA driver — **no X server required**. HIP (AMD) and METAL (Apple) similarly run headless. The known issue from 2024 (#125392) where Cycles 4.2 printed "OPTIX kernel reload" multiple times per frame in headless was fixed in 4.3.

### 5.3 EEVEE-Next headlessly

Since 4.2 the GPU subsystem on Linux can use **EGL** instead of GLX, so EEVEE works in `--background` on a server with **no X**, provided the GPU drivers expose EGL (NVIDIA proprietary, Mesa for AMD/Intel). On 4.0.2 you must still wrap the call:

```bash
xvfb-run -a -s "-screen 0 1280x720x24" \
    blender --background scene.blend -E BLENDER_EEVEE -f 1
```

In 4.5+ pass `--gpu-backend vulkan` for noticeably faster cold start (5x) and texture loading on Linux. Vulkan reached OpenGL parity in 4.5; before that it was experimental.

### 5.4 Workbench / GPU offscreen

For ultra-cheap orthographic turntables and matcap previews:

```bash
blender -b char.blend -E BLENDER_WORKBENCH \
        -o //thumbs/front_### -F PNG -f 1
```

For programmatic offscreen draws, the `gpu.types.GPUOffScreen` API exists but is brittle in `--background` because the offscreen is bound to a GL context that may not have been created. Stick with Workbench through the normal render path.

### 5.5 Sample / denoise / color management presets worth setting

```python
s = bpy.context.scene
s.render.resolution_x = 2048
s.render.resolution_y = 2048
s.render.resolution_percentage = 100
s.render.image_settings.file_format = 'OPEN_EXR_MULTILAYER'
s.render.image_settings.color_depth = '32'
s.render.image_settings.exr_codec  = 'ZIP'
s.view_settings.view_transform     = 'AgX'      # 4.0+ default; sRGB-LIN on 3.x
s.view_settings.look               = 'AgX - Base Contrast'
s.cycles.adaptive_threshold        = 0.01
s.cycles.time_limit                = 600        # safety net, seconds per frame
```

---

## 6. Add-on and extension management from CLI

### 6.1 Legacy add-on enable (works on all 4.x and 5.0)

```python
import bpy
for a in ("rigify", "io_scene_fbx", "io_scene_gltf2", "node_wrangler"):
    bpy.ops.preferences.addon_enable(module=a)
bpy.ops.wm.save_userpref()    # only needed if not using --factory-startup
```

In a `--factory-startup` run you must re-enable every time, or use `--addons rigify,io_scene_fbx,io_scene_gltf2` on the command line. `bpy.ops.preferences.addon_enable` does not need a window; it's safe in `--background`.

### 6.2 Extensions (4.2+)

The 4.2 extension platform replaced legacy add-ons for everything *not* shipped in core Blender. Bundled add-ons (rigify, io_scene_fbx, io_scene_gltf2, node_wrangler, mesh_extra_objects, etc.) remain regular `bpy.ops.preferences.addon_enable` callable. Anything from extensions.blender.org (or third-party repos) is now an "extension" with its own metadata and dependency resolution.

Install one from CLI:

```bash
blender --command extension install-file \
        --repo user_default \
        --enable \
        /tmp/my_extension-1.2.3.zip
```

Or sync from a remote repo, then enable:

```bash
blender --command extension sync
blender --command extension install --enable blender_org.node_wrangler
```

Once installed, extensions are loadable from script the same way as legacy add-ons (`bpy.ops.preferences.addon_enable(module='bl_ext.user_default.my_extension')`) — the module path is namespaced with `bl_ext.<repo>.`.

Important headless gotcha: the first time a user runs Blender 4.2+, it asks (interactively!) whether to enable the online repository. In `--background` this prompt is skipped, but online sync is then disabled by default — set `bpy.context.preferences.system.use_online_access = True` in script if you need extension sync to work in CI.

---

## 7. Rigify in headless

Rigify works fully from script. The flow:

```python
import bpy
bpy.ops.preferences.addon_enable(module="rigify")

# 1) Add the human metarig
bpy.ops.object.armature_human_metarig_add()
metarig = bpy.context.object
metarig.name = "MetaRig"

# 2) Customise bone positions and rigify_type (e.g. swap limbs.super_limb for
#    limbs.simple_tentacle, change face rig parameters per bone, etc.)
for bone in metarig.pose.bones:
    if bone.name == "spine.006":
        bone.rigify_parameters.connect_chain = True
    # ... project-specific tweaks ...

# 3) Generate
with bpy.context.temp_override(active_object=metarig, object=metarig,
                               selected_objects=[metarig],
                               selected_editable_objects=[metarig]):
    bpy.ops.pose.rigify_generate()

generated = bpy.data.objects["rig"]   # default name
```

`rigify_generate` runs in `--background` because all of its operators have data-API paths. The generation walks the metarig, instantiates rig classes, builds bones, parents, constraints, widgets and the rig UI panel script. In 4.1+, the generated rig uses **bone collections** (the modern replacement for armature layers); old `armature.layers[]` code is removed in 5.0. If we stay on 4.5 LTS we use `armature.collections_all["FK"].is_visible = True`.

---

## 8. Asset Browser from Python

The asset surface is fully scriptable since 3.0 and stable in 4.5.

### 8.1 Marking and unmarking assets

```python
import bpy
ob = bpy.data.objects["Hairpiece_01"]
ob.asset_mark()
ob.asset_data.catalog_id = "0a1b2c3d-...-uuid"   # from blender_assets.cats.txt
ob.asset_data.tags.new("dark_fantasy")
ob.asset_data.tags.new("hair")
ob.asset_data.description = "Long curly hair, dark."

# Generate a preview thumbnail (works headless if a render context is available)
with bpy.context.temp_override(id=ob):
    bpy.ops.ed.lib_id_generate_preview()
```

### 8.2 Linking and library overrides

```python
# Append a copy
bpy.ops.wm.append(
    filepath="//lib/characters.blend/Object/Body",
    directory="/abs/path/lib/characters.blend/Object/",
    filename="Body",
)

# Link + library override (the canonical way to assemble a character that
# inherits upstream rig fixes but lets you pose it locally)
with bpy.data.libraries.load("/abs/path/lib/characters.blend", link=True) as (src, dst):
    dst.collections = ["NocturneMatriarch"]

linked_coll = dst.collections[0]
override = linked_coll.override_hierarchy_create(
    bpy.context.scene,
    bpy.context.view_layer,
)
```

For costume layering, link the base body collection once, override it, then link each costume collection separately and parent under the override. `override_hierarchy_create` is the modern (3.2+) entrypoint that walks the hierarchy and creates overrides for armatures, meshes, and shape keys in one pass.

### 8.3 Asset library registration

```python
prefs = bpy.context.preferences
libs  = prefs.filepaths.asset_libraries

if "NocturneLib" not in libs:
    libs.new(name="NocturneLib", directory="/work/assets/nocturne")
```

Register before running any tool that scans the catalog, otherwise `bpy.context.window_manager.asset_path_dummy` will be empty.

---

## 9. Hair / curves from script

Blender ships a **Hair node group library** since 3.5 (matured in 4.0–4.3). It lives in `<blender>/4.5/datafiles/assets/geometry_nodes/procedural_hair_node_assets.blend`. To use one programmatically:

```python
import os, bpy

datafiles = bpy.utils.system_resource('DATAFILES')
hair_lib  = os.path.join(datafiles, "assets", "geometry_nodes",
                         "procedural_hair_node_assets.blend")

with bpy.data.libraries.load(hair_lib, link=False) as (src, dst):
    dst.node_groups = ["Generate Hair Curves",
                       "Frizz Hair Curves",
                       "Clump Hair Curves"]

# Add a Curves object as scalp child, then attach a Geometry Nodes modifier
scalp = bpy.data.objects["Scalp"]
curves = bpy.data.hair_curves.new("Hair")
hair_ob = bpy.data.objects.new("Hair", curves)
bpy.context.scene.collection.objects.link(hair_ob)
hair_ob.parent = scalp

m = hair_ob.modifiers.new("Generate", "NODES")
m.node_group = bpy.data.node_groups["Generate Hair Curves"]
m["Input_2"]  = scalp     # 'Surface' input (socket id depends on node group)
m["Input_3"]  = 5000      # 'Density'
m["Input_5"]  = 0.20      # 'Length'
```

Socket identifiers (`"Input_2"`) are unstable across hair-lib revisions — inspect `m.node_group.interface.items_tree` and key by name rather than ordinal where possible. From 4.0 onward, the new Geometry Nodes "Tools" category lets you author hair *grooming* operators that show up in Sculpt mode; these run on data and so are scriptable in `--background` as long as you trigger them through `node_group.execute`-style hooks rather than the Sculpt brush tool.

---

## 10. Export pipelines (USD, glTF, FBX)

All three exporters are bundled and headless-safe. Note the operator-name asymmetry (`wm.usd_export` but `export_scene.gltf` / `export_scene.fbx`):

```python
# USD — since 2.82, expanded heavily in 4.x; preferred for VFX/Houdini handoffs
bpy.ops.wm.usd_export(
    filepath="/out/nocturne.usdc",
    selected_objects_only=False,
    export_animation=True,
    export_hair=True,
    export_uvmaps=True,
    export_normals=True,
    export_materials=True,
    generate_preview_surface=True,
    export_textures=True,
    overwrite_textures=True,
    use_instancing=True,
    evaluation_mode='RENDER',
)

# glTF 2.0 — best for web/realtime/UE5 and for the AI client preview
bpy.ops.export_scene.gltf(
    filepath="/out/nocturne.glb",
    export_format='GLB',
    export_apply=True,           # apply modifiers
    export_skins=True,
    export_animations=True,
    export_morph=True,
    export_materials='EXPORT',
)

# FBX — game-engine compatibility, especially Unity
bpy.ops.export_scene.fbx(
    filepath="/out/nocturne.fbx",
    use_selection=False,
    apply_unit_scale=True,
    bake_space_transform=True,
    object_types={'ARMATURE', 'MESH'},
    add_leaf_bones=False,
    bake_anim=True,
)
```

`USDHook` (4.x) lets you register Python callbacks invoked during USD export — useful for injecting custom material translation. glTF in 4.x supports KHR_materials_pbrSpecularGlossiness, KHR_lights_punctual, draco compression and (4.4+) KHR_animation_pointer.

---

## 11. Linux-server specifics

### 11.1 Where Blender stores config

| Path | Contents |
|---|---|
| `~/.config/blender/<X.Y>/config/userpref.blend` | User preferences (addons, paths, theme). |
| `~/.config/blender/<X.Y>/config/startup.blend` | Default scene if you saved one with Ctrl-U. |
| `~/.config/blender/<X.Y>/scripts/addons/` | User-installed legacy add-ons. |
| `~/.config/blender/<X.Y>/extensions/user_default/` | User-installed extensions (4.2+). |
| `~/.cache/blender/<X.Y>/cache/` | Cycles kernel cache, denoiser cache. |

`<X.Y>` is the major.minor — `4.0`, `4.5`, `5.0`. Each version is isolated; upgrading from 4.0 to 4.5 does not migrate prefs unless you copy the directory yourself.

`--factory-startup` ignores `userpref.blend` and `startup.blend` entirely. It still reads the **Cycles kernel cache** in `~/.cache/blender`, which is the right behaviour (no need to recompile shaders every CI run).

For deterministic CI you can also redirect everything via env vars:

```bash
BLENDER_USER_CONFIG=/tmp/blender-config-$$ \
BLENDER_USER_SCRIPTS=/tmp/blender-scripts-$$ \
BLENDER_USER_EXTENSIONS=/tmp/blender-ext-$$ \
    blender --factory-startup -b ...
```

### 11.2 GPU rendering on a server with no X

- **Cycles + CUDA / OPTIX:** works headlessly. `nvidia-smi` must succeed, drivers ≥535 for OPTIX denoiser. No X needed at any point.
- **Cycles + HIP (AMD):** requires ROCm driver; no X.
- **Cycles + ONEAPI (Intel):** requires Intel oneAPI runtime; no X.
- **Cycles + METAL:** Apple-only; not relevant on Linux.
- **EEVEE-Next on 4.2+ Linux:** uses EGL, works without X if the driver exposes EGL (NVIDIA proprietary always does; Mesa-AMD does; Mesa-Intel does).
- **EEVEE on 4.0–4.1 Linux:** requires X. Use `xvfb-run -a` wrapper.
- **GPU module / `gpu.offscreen`:** same EGL requirement as EEVEE.

A common cargo-cult mistake is to install a full X server "just in case" — it isn't needed for Cycles, ever. For 4.2+ EEVEE on a node with NVIDIA proprietary drivers, neither X nor xvfb is needed.

### 11.3 Container patterns

- `nytimes/rd-blender-docker` — long-running community Cycles+EEVEE Docker images, GPU passthrough via `--gpus all`.
- `linuxserver/blender` — generic, includes a noVNC GUI for occasional interactive needs.
- `blenderkit/headless-blender` — minimal, geared at addon test runs.
- `blenderproc/blenderproc` — comes with EGL preconfigured.

The minimum Dockerfile for a headless 4.5 LTS node looks like:

```Dockerfile
FROM nvidia/cuda:12.4.1-base-ubuntu22.04
RUN apt-get update && apt-get install -y \
    libxkbcommon0 libxxf86vm1 libxfixes3 libxi6 libxrender1 libgl1 libegl1 \
    libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 \
    libxcb-shape0 libxcb-xfixes0 libsm6 \
    && rm -rf /var/lib/apt/lists/*
COPY blender-4.5.0-linux-x64/ /opt/blender/
ENV PATH=/opt/blender:$PATH
ENTRYPOINT ["blender", "--background", "--factory-startup", "--python-exit-code", "1"]
```

The libxkbcommon / libxcb deps are required even with `--background` — Blender's startup links against them and dlopens them up-front.

---

## 12. Third-party headless tooling worth knowing

- **BlenderProc** ([github](https://github.com/DLR-RM/BlenderProc)) — DLR's Python wrapper for synthetic data generation. Ships its own Blender, configures EGL, exposes a clean `blenderproc.python.api` so you don't touch raw bpy. Useful if we want labelled training renders of the character.
- **Infinigen** ([infinigen.org](https://infinigen.org)) — Princeton's procedural world generator. Runs Blender as a Python module; Infinigen-Sim (May 2025) adds articulated characters; Infinigen Indoors (June 2025) adds procedural interiors. Useful as a backdrop generator.
- **blendify** ([github](https://github.com/ptrvilya/blendify)) — thin Python rendering API around bpy, designed for ML researchers.
- **BlenderKit CLI** — script-driven asset download from BlenderKit's library; `blenderkit.upload`/`download` work in `--background`.
- **mb-lab / charmorph** — humanoid base-mesh generators. Both have `--background` modes that emit a configured base mesh + rig from a JSON spec — useful for the initial Nocturne body generation step before sculpting.

---

## 13. Recommended workflow for the Nocturne Matriarch project

The project is currently on 4.0.2. Concrete recommendations for our headless Linux server with optional GUI MCP:

1. **Upgrade to Blender 4.5 LTS now.** 4.0 is EOL, 5.0 has breaking Python changes (legacy Action API removed, mathutils float32, file-output slot rename) that we'd hit immediately. 4.5 LTS is supported through July 2027 and gives us free Vulkan, EEVEE-Next-on-EGL, brush asset improvements, and a 22% faster Clay Strips for any interactive sculpt sessions on a workstation.
2. **Pin the binary explicitly.** Replace whatever `/usr/bin/blender` is with a tarball install in `/opt/blender-4.5.x/blender` and a `BLENDER_BIN` env var. Distro packages are routinely behind and inconsistent across versions.
3. **Standard CLI invocation pattern** for every script step:

   ```bash
   $BLENDER_BIN --background --factory-startup --enable-autoexec \
       --python-exit-code 2 \
       --addons rigify,io_scene_fbx,io_scene_gltf2,node_wrangler \
       <input.blend> --python <step.py> -- <step args>
   ```

   Wrap that in a `scripts/blender_run.sh` so the whole pipeline calls `blender_run.sh build_step.py --seed 42 ...` and only one place owns the flags.
4. **Always set `--python-exit-code`** (we use 2 to distinguish from Blender's own 1 and from generic shell errors). Without it, a `KeyError` in your script returns 0 and CI passes green.
5. **Keep state out of `~/.config/blender/4.5/`** by combining `--factory-startup` with an in-script `bpy.ops.preferences.addon_enable` block. Optionally redirect with `BLENDER_USER_CONFIG=/tmp/...` for fully sandboxed runs.
6. **For Cycles GPU on this server**, hard-code OPTIX in script (not via `--cycles-device`) so it survives `--factory-startup`, and verify in CI by checking `len([d for d in cprefs.devices if d.use and d.type=='OPTIX']) > 0` and failing loud if zero.
7. **For visual review renders**, prefer Cycles 64-sample with OPTIX denoise rather than EEVEE — it's deterministic, doesn't need EGL, and on a single RTX-class card it's fast enough for character look-dev. Reserve EEVEE for the GUI/MCP workstation only.
8. **Structure the character as a linked + overridden hierarchy**: one `body.blend` with the base mesh + Rigify metarig + generated rig, one `costume_<n>.blend` per outfit, one `hair_<n>.blend` per hair set. The shot file links them and `override_hierarchy_create` creates the overrides. This makes `git`-friendly diffs (each .blend is a single concern) and lets a sculpt iteration on `body.blend` propagate.
9. **Asset browser registration** should be done by a one-shot `tools/setup_asset_libraries.py` that any new dev or any new build runs once — register `assets/nocturne/` as `NocturneLib` and let everything else discover from there.
10. **Use rigify and the bundled hair node library, not third-party ones.** Both ship with Blender, both work in `--background`, both are stable across 4.x. Hair Tool / HairLab style add-ons are convenient but introduce a dependency we don't need for one character.
11. **The MCP socket / GUI escape hatch.** A few operations genuinely require a live UI: dynamic sculpt brush strokes, manual asset thumbnail QC, real-time gizmo placement. Run a single GUI Blender 4.5 instance locally (or on a workstation), connect it via MCP, and reserve it for these explicit steps. Keep the headless pipeline authoritative — the MCP session edits a `.blend` that the headless build then consumes. Never let the GUI become the source of truth.
12. **Reproducibility checks.** After each headless step, dump a manifest (`bpy.data.objects`, modifier stacks, material datablocks, polygon counts) to JSON next to the `.blend` and diff it in CI. Cycles' `cycles.use_auto_tile = False` and a fixed `seed` should be set in the standard scene template so renders are bitwise reproducible across runs.

---

## Sources

- [Blender 5.1 Manual — Command Line Arguments](https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html) (the live reference; the `--help` output of your installed binary is the authoritative version-specific source)
- [Mastering the Blender CLI — RenderDay, 2024](https://renderday.com/blog/mastering-the-blender-cli)
- [Blender 5.1 Manual — Extensions Command Line Arguments](https://docs.blender.org/manual/en/latest/advanced/command_line/extension_arguments.html)
- [How to install extension from the command line? — devtalk.blender.org](https://devtalk.blender.org/t/how-to-install-extension-from-the-command-line/36520)
- [Blender 5.0 Release Notes — developer.blender.org](https://developer.blender.org/docs/release_notes/5.0/)
- [Blender 5.0 Python API — developer.blender.org](https://developer.blender.org/docs/release_notes/5.0/python_api/)
- [Blender 4.5 LTS Release Notes — developer.blender.org](https://developer.blender.org/docs/release_notes/4.5/)
- [Blender 4.5 LTS — EEVEE & Viewport](https://developer.blender.org/docs/release_notes/4.5/eevee/)
- [Blender 4.5 LTS — Sculpt, Paint, Texture](https://developer.blender.org/docs/release_notes/4.5/sculpt/)
- [Blender 4.5 LTS announcement — blender.org](https://www.blender.org/download/lts/4-5/)
- [Blender 4.5 LTS lands — Digital Production, Nov 2025](https://digitalproduction.com/2025/11/03/blender-4-5-lts-lands/)
- [Blender 4.5 LTS — 5 key features, CG Channel Jul 2025](https://www.cgchannel.com/2025/07/blender-4-5-lts-is-out-check-out-its-5-key-features/)
- [Blender 4.4 Release Notes](https://developer.blender.org/docs/release_notes/4.4/)
- [Blender 4.3 — Geometry Nodes](https://developer.blender.org/docs/release_notes/4.3/geometry_nodes/)
- [Blender 4.3 — Grease Pencil migration](https://developer.blender.org/docs/release_notes/4.3/grease_pencil_migration/)
- [Blender 4.0 — Shading & Texturing (Principled v2)](https://developer.blender.org/docs/release_notes/4.0/shading/)
- [Bone Collections — developer docs](https://developer.blender.org/docs/features/animation/armatures/bone_collections/)
- [Rigify Add-on API — developer docs](https://developer.blender.org/docs/features/animation/rigify/)
- [Cycles GPU Rendering Manual](https://docs.blender.org/manual/en/latest/render/cycles/gpu_rendering.html)
- [Headless rendering picking up GPUs — devtalk thread](https://devtalk.blender.org/t/headless-rendering-no-longer-automatically-picking-up-gpus/12176)
- [Context overriding in Blender 3.2 and later — Interplanety](https://b3d.interplanety.org/en/context-overriding-in-blender-3-2-and-later/)
- [bpy.ops Operators reference](https://docs.blender.org/api/current/bpy.ops.html)
- [CollectionLightLinking API](https://docs.blender.org/api/current/bpy.types.CollectionLightLinking.html)
- [Library Overrides Manual](https://docs.blender.org/manual/en/latest/files/linked_libraries/library_overrides.html)
- [Asset Browser from Python — HackMD blender-asset-browser](https://hackmd.io/@blender-asset-browser/S1bbhY0lO)
- [Procedural Hair Nodes — Blender Studio](https://studio.blender.org/blog/procedural-hair-nodes/)
- [Hair Nodes — Blender Manual](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/hair/index.html)
- [Headless EEVEE on a server — Hannes Zietsman, Medium](https://medium.com/@jjziets/how-to-rendering-blender-eevee-on-a-headless-system-d3054ced8ec)
- [EEVEE not working in Docker — Blender Artists 4.2.1 thread](https://blenderartists.org/t/belender-4-2-1-eevee-does-not-work-inside-docker/1551491)
- [BlenderProc — GitHub](https://github.com/DLR-RM/BlenderProc)
- [Infinigen — princeton-vl GitHub](https://github.com/princeton-vl/infinigen)
- [Infinigen-Sim 2025 paper](https://ui.adsabs.harvard.edu/abs/2025arXiv250510755J/abstract)
- [Phoronix — Blender 4.5 RC1 Vulkan support](https://www.phoronix.com/news/Blender-4.5-RC1)
- [LWN — Blender 4.5 brings big changes](https://lwn.net/Articles/1036262/)
- [GPU Off-Screen Buffer (gpu.offscreen) reference](https://docs.blender.org/api/current/gpu.html)
