---
name: character-export-validator
description: Use to export the Nocturne Matriarch (or variant) to glTF / FBX / USD with full pre- and post-export validation. Invoke when a downstream consumer — three.js sandbox, Unity/Unreal, Houdini, USDZ/AR — needs a portable file, or when an export has failed validation and needs triage.
---

# Character Export Validator

## When to invoke
- Rig + shaders + sim are done, and the next ticket is "ship a `.glb` to the portfolio sandbox".
- A downstream tool (Houdini, Omniverse, Unity, Unreal, Mixamo, three.js) needs a non-Blender file.
- An export was attempted and failed validation (missing textures, wrong bone count, broken normals, file >50MB).
- USDZ / AR delivery needed.
- Auditing the AI-derived-content license trail before any external distribution.

## Role
Owns the boundary between the Blender source-of-truth and the outside world. Every external file we ship passes through this skill. The skill encodes the format decision matrix, the 10-point pre-export gate, the operator settings the project standardizes on, and the post-export validation loop. Refuses any export that would ship procedural-only materials, missing texture refs, or AI-derived geometry without a manifest row.

This skill does not author geometry, rigs, or shaders — it validates and exports what upstream skills produced. If the upstream output fails a gate, this skill kicks the ticket back to the responsible skill (`blender-rig-pose-director`, `blender-shader-builder`, etc.).

## Format decision matrix

Source: `docs/research/headless-blender-2026.md` §10.

| Format | Pick when | Avoid when | Notes |
|---|---|---|---|
| **glTF 2.0 (`.glb`)** | **Default.** Best PBR support, smallest file, web-friendly. Portfolio + most game engines + three.js / babylon.js sandboxes. | Target tool is FBX-only or needs USD-specific features. | Operator: `bpy.ops.export_scene.gltf`. Single binary container; embeds textures. |
| **FBX (`.fbx`)** | Target is Maya, Mixamo retargeting, older Unity workflows, Marmoset Toolbag. | Modern web/three.js work — glTF is strictly better there. | Operator: `bpy.ops.export_scene.fbx`. **Watch for normal/tangent corruption** — Blender's FBX exporter has a long history of flipping tangent space; always validate normals post-export. |
| **USD (`.usd`/`.usdc`/`.usdz`)** | Houdini, Omniverse, USDZ/AR delivery, VFX handoff. Native in Blender 4.x; preferred over FBX for VFX. | Web/realtime targets that don't yet support USD viewer. | Operator: `bpy.ops.wm.usd_export` (note the asymmetric operator path — not `export_scene.usd`). USDZ for AR uses `export_as_usdz=True`. |
| **OBJ / Alembic** | Static sculpt review (OBJ) or sim cache only (Alembic — already used for cape sim per `blender-rig-pose-director`). | Anything that needs animation, materials, or rig. | Not in scope for character export — included for completeness. |

## Pre-export gate (10-point checklist)

Every gate must pass before `bpy.ops.export_scene.*` is called. Numbered so failures can be cited by index in ticket reports.

1. **Scale applied.** All character objects have `object.scale == (1, 1, 1)`. Check:
   ```python
   for o in char_objects:
       assert tuple(o.scale) == (1.0, 1.0, 1.0), f"{o.name} scale not applied: {tuple(o.scale)}"
   ```
   Fix: `bpy.ops.object.transform_apply(scale=True)` on each.
2. **Rotation applied.** All meshes have `object.rotation_euler == (0, 0, 0)`. Rest pose binding depends on this — non-applied rotation breaks armature deform on import elsewhere. Fix: `bpy.ops.object.transform_apply(rotation=True)`.
3. **Origin at character world origin.** Between the feet at `z=0`. Verify `armature.location == Vector((0, 0, 0))`. The root bone in the rig is at `(0, 0, 0)` per `blender-rig-pose-director` gate 2.
4. **Single armature; no nested armatures.** `len([o for o in char_objects if o.type == 'ARMATURE']) == 1`. Nested armatures break every importer.
5. **All meshes parented to armature with Armature modifier** (NOT Child-Of constraint and NOT object-parent-only):
   ```python
   for m in mesh_objects:
       assert m.parent and m.parent.type == 'ARMATURE', f"{m.name} not parented to armature"
       assert any(mod.type == 'ARMATURE' for mod in m.modifiers), f"{m.name} missing Armature modifier"
   ```
6. **Vertex group names match deform bone names exactly.** Any mismatch silently drops weight on export:
   ```python
   bone_names = {b.name for b in armature.data.bones if b.use_deform}
   for m in mesh_objects:
       for vg in m.vertex_groups:
           if vg.name not in bone_names and not vg.name.startswith("_"):
               raise AssertionError(f"{m.name}.{vg.name} has no matching deform bone")
   ```
7. **Material slots ordered consistently across LOD variants.** If shipping LOD0/LOD1/LOD2, slot 0 must be the same material across all three (skin, then armor, then cloth, then hair, then accessories — fixed order).
8. **UV map naming.** Primary UV named `"UVMap"` (default — do not rename). Secondary UV (if used for lightmap or detail) named `"Lightmap"`. Importers in Unity / Unreal expect this convention.
9. **Texture paths relative to .blend, packed if for distribution.** For `.glb` export, packing is automatic (single-file container). For `.fbx`/`.usd` export, run `bpy.ops.file.make_paths_relative()` then verify with:
   ```python
   for img in bpy.data.images:
       if img.source == 'FILE' and img.filepath.startswith("/"):
           raise AssertionError(f"Absolute texture path: {img.filepath}")
   ```
10. **No hidden geometry; no orphan datablocks.**
    - Hidden geometry exports invisibly into the file and inflates size: `assert all(not o.hide_render for o in char_objects)`.
    - Orphan datablocks: `bpy.ops.outliner.orphans_purge(do_local_ids=True, do_linked_ids=True, do_recursive=True)`.

If any gate fails, the export ticket is marked failed and returned to the responsible upstream skill — do not "fix and ship" here; the fix belongs in the tracked source script.

## Procedural shaders DO NOT survive export

Source: `docs/research/dark-fantasy-shading-pipeline.md` §C (all materials are procedural).

Every procedural material — Cycles AO node masks, bevel-node curvature, noise-driven dirt, Charlie Sheen velvet, the wine cloth weave normal — must be **baked to PBR maps before export**. Procedural shaders silently render flat-grey or pink-missing-texture in any non-Blender consumer.

Bake order per material slot:

| Map | Color space | Resolution (hero) | Resolution (secondary) |
|---|---|---|---|
| Base Color (albedo) | sRGB | 4K | 2K |
| Normal (tangent space) | Non-Color | 4K | 2K |
| Roughness | Non-Color | 4K | 2K |
| Metallic | Non-Color | 4K | 2K |
| ORM packed (Occlusion-Roughness-Metallic) | Non-Color | 4K | 2K |
| Emission (if material uses it) | sRGB | 2K | 1K |
| Thickness (skin SSS) | Non-Color | 2K | 1K |

ORM packing convention (per `docs/research/lineage2-art-style.md` §1.5 — L2M PBR ORM standard):
- R channel: Ambient Occlusion
- G channel: Roughness
- B channel: Metallic

Use Blender's bake → Combined or per-channel bakes via the standard "bake-to-image-texture" recipe. The `blender-shader-builder` skill owns the bake setup; this skill **only verifies bakes exist** before export:

```python
required_maps_per_material = {
    "matriarch_skin":         ["albedo", "normal", "orm", "thickness"],
    "matriarch_dark_steel":   ["albedo", "normal", "orm"],
    "matriarch_gold_filigree":["albedo", "normal", "orm"],
    "matriarch_wine_cloth":   ["albedo", "normal", "orm"],
    "matriarch_velvet_cape":  ["albedo", "normal", "orm"],
    "matriarch_hair":         ["albedo", "normal", "orm"],
    "matriarch_focus_gem":    ["albedo", "normal", "orm", "emission"],
}
texture_dir = Path(__file__).parent.parent / "outputs" / "textures" / "matriarch"
for mat, maps in required_maps_per_material.items():
    for m in maps:
        p = texture_dir / f"{mat}_{m}.png"
        assert p.exists(), f"Missing baked map: {p}"
```

## Standard glTF export script

The project's locked settings — paste into `scripts/parts/export_gltf.py`:

```python
import bpy
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "outputs" / "exports" / "matriarch.glb"
OUT.parent.mkdir(parents=True, exist_ok=True)

# Select only the character collection
char_collection = bpy.data.collections["matriarch"]
bpy.ops.object.select_all(action='DESELECT')
for o in char_collection.objects:
    o.select_set(True)

bpy.ops.export_scene.gltf(
    filepath=str(OUT),
    use_selection=True,
    export_format='GLB',
    export_apply=True,             # apply modifiers (sub-d, mirror, etc.)
    export_yup=True,               # Y-up for three.js / Unity / Unreal
    export_animations=True,        # ship the noble-primary pose animation track
    export_skins=True,             # rig + skinning
    export_morph=False,            # set True only if face shape keys are shipped
    export_materials='EXPORT',
    export_lights=False,           # lighting belongs to the consumer scene
    export_cameras=False,          # ditto
    export_image_format='AUTO',    # PNG for color, JPEG for opaque non-color where possible
    export_texcoords=True,
    export_normals=True,
    export_tangents=True,          # required for normal mapping
    export_attributes=False,
    export_draco_mesh_compression_enable=True,  # ~30-50% size reduction
    export_draco_mesh_compression_level=6,
)
print(f"Exported: {OUT} ({OUT.stat().st_size / 1024 / 1024:.2f} MB)")
```

## Standard FBX export script (when needed)

```python
bpy.ops.export_scene.fbx(
    filepath=str(OUT.with_suffix(".fbx")),
    use_selection=True,
    apply_unit_scale=True,
    apply_scale_options='FBX_SCALE_ALL',
    bake_space_transform=True,
    object_types={'ARMATURE', 'MESH'},
    use_mesh_modifiers=True,
    mesh_smooth_type='FACE',       # critical — OFF causes hard-edge corruption in Unity
    use_subsurf=False,
    use_armature_deform_only=True, # strip non-deform bones (saves ~50% on Rigify exports)
    add_leaf_bones=False,          # Mixamo expects this False; Unity tolerates either
    primary_bone_axis='Y',
    secondary_bone_axis='X',
    bake_anim=True,
    bake_anim_use_all_bones=True,
    bake_anim_force_startend_keying=True,
    path_mode='COPY',
    embed_textures=True,
)
```

## Standard USD export script (Houdini / Omniverse / USDZ)

```python
bpy.ops.wm.usd_export(
    filepath=str(OUT.with_suffix(".usdc")),
    selected_objects_only=True,
    export_animation=True,
    export_hair=True,
    export_uvmaps=True,
    export_normals=True,
    export_materials=True,
    use_instancing=True,
    export_textures=True,
    overwrite_textures=True,
    relative_paths=True,
    # USDZ for AR delivery:
    # export_as_usdz=True, filepath=...usdz
)
```

## Post-export validation loop

Three checks, ordered cheapest-first:

1. **Re-open in Blender (clean instance).** Confirms the file is structurally valid and the importer round-trips without error:
   ```bash
   blender --background --factory-startup --enable-autoexec --python-exit-code 2 \
     --python scripts/validate_export.py -- outputs/exports/matriarch.glb
   ```
   The validator script asserts: bone count matches expectation, mesh count matches, material count matches, no missing-texture warnings on import.
2. **Khronos glTF Validator** (web tool, also available as CLI `gltf-validator`). Run for every `.glb` export. Zero errors required; warnings reviewed and either fixed or documented in the ticket.
3. **three.js sandbox load test.** Drag-drop into https://threejs.org/editor or load via the project's `outputs/sandbox/` page. Confirms the file loads in <2s and renders correctly with the project's standard environment HDR.

```python
# scripts/validate_export.py — invoked by the shell post-export
import bpy, sys
glb = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)

armatures = [o for o in bpy.data.objects if o.type == 'ARMATURE']
assert len(armatures) == 1, f"Expected 1 armature, got {len(armatures)}"
deform = [b for b in armatures[0].data.bones if b.use_deform]
assert 160 <= len(deform) <= 200, f"Deform bone count out of envelope: {len(deform)}"

meshes = [o for o in bpy.data.objects if o.type == 'MESH']
assert len(meshes) >= 6, f"Expected ≥6 mesh objects (body, costume parts, hair), got {len(meshes)}"

mats = list(bpy.data.materials)
assert len(mats) >= 7, f"Expected ≥7 materials, got {len(mats)}"

for img in bpy.data.images:
    if img.source == 'FILE':
        assert img.has_data, f"Texture failed to load: {img.name}"

print(f"[OK] {glb} validated: {len(deform)} bones, {len(meshes)} meshes, {len(mats)} materials")
```

## License manifest update (AI-derived content)

Source: `docs/research/ai-3d-generation-2026.md` §IP/license.

Any export that includes geometry derived from an AI generator (Hunyuan3D, Hyper3D Rodin, TRELLIS, CharacterGen, etc.) must reference the source row in `outputs/ai_gen/MANIFEST.csv`. The manifest is owned by the `ai-3d-mesh-handler` skill but read by this skill at export time.

Required CSV columns (per `ai-3d-mesh-handler`):
- `asset_id` — slug of the AI-generated input
- `generator` — `hunyuan3d-2.1` / `rodin-gen2` / `trellis.2-4b` / etc.
- `prompt` — the prompt or input image hash
- `license` — Apache-2.0 / commercial / CC-BY / etc.
- `jurisdiction_carveouts` — e.g. `EU,UK,KR` for Hunyuan3D 2.1
- `human_edit_evidence` — path to sculpt/retopo session log proving copyrightable authorship was added on top
- `export_refs` — comma-separated list of export file basenames that include this asset

This skill **appends to the `export_refs` column** for every AI-derived asset present in the export. If `human_edit_evidence` is empty for any referenced row, the export is **blocked** — per the `docs/research/ai-3d-generation-2026.md` recommendation, AI output must have a documented manual sculpt/texture pass to establish copyrightable authorship.

```python
import csv
from pathlib import Path

MANIFEST = REPO / "outputs" / "ai_gen" / "MANIFEST.csv"
ai_assets_in_export = ["matriarch_base_mesh"]  # populated by upstream tickets

rows = list(csv.DictReader(MANIFEST.open()))
for row in rows:
    if row["asset_id"] in ai_assets_in_export:
        if not row["human_edit_evidence"].strip():
            raise SystemExit(
                f"BLOCK: {row['asset_id']} lacks human_edit_evidence; cannot export."
            )
        existing = [s for s in row["export_refs"].split(",") if s.strip()]
        if OUT.name not in existing:
            existing.append(OUT.name)
            row["export_refs"] = ",".join(existing)

with MANIFEST.open("w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(rows)
```

## Quality gates

All gates must be green before the export ticket closes:

1. **File size:** `.glb` hero export `<` 50 MB. If larger, enable Draco compression (already in template) or drop to 2K secondary textures.
2. **Load time:** loads in `<` 2s in three.js sandbox on a baseline laptop (M-series MacBook Air or equivalent).
3. **Bone count match:** post-import deform bone count is within 160–200, matching the `blender-rig-pose-director` envelope.
4. **No missing texture warnings** on import in either Blender re-open or three.js sandbox.
5. **Khronos glTF Validator:** zero errors. Warnings reviewed and documented.
6. **Material count match:** post-import material count `>=` 7 (skin, dark steel, gold filigree, wine cloth, velvet cape, hair, focus gem).
7. **Tangents present** for any mesh that uses normal mapping (all of them, in this project).
8. **License manifest updated** for every AI-derived asset — `export_refs` column appended; `human_edit_evidence` non-empty for every referenced row.
9. **Output path matches convention:** `outputs/exports/<character>[_<variant>].<ext>`. Never `outputs/renders/`, never the repo root.
10. **Promotion block emitted.** Per `orchestrator/README.md` § "Source-of-truth promotion" — the export script lives at `scripts/parts/export_<format>.py`, not in MCP-only state.

## References

- `docs/research/headless-blender-2026.md` §10 (export operators), §3.1 (USD/glTF/FBX/OBJ/Alembic all headless-safe), §6.1 (addon enable for `io_scene_fbx`, `io_scene_gltf2`).
- `docs/research/lineage2-art-style.md` §1.5 (L2M PBR ORM standard), §8 (180-bone, 4K body, 4K outfit, 2K hair targets).
- `docs/research/ai-3d-generation-2026.md` § "IP, license, and dataset hygiene in 2026" — Hunyuan3D 2.1 EU/UK/KR carveout; recommended posture for Nocturne Matriarch.
- `docs/research/dark-fantasy-shading-pipeline.md` §C — every material in the project is procedural; ALL must be baked before export.
- `orchestrator/README.md` § "Source-of-truth promotion" and headless invariant (`--factory-startup --enable-autoexec --python-exit-code 2`).
- `scripts/create_dark_fantasy_lady_blockout.py` — exemplar headless script structure.
- Hand-off targets: `ai-3d-mesh-handler` (manifest owner), `blender-shader-builder` (texture bake), `blender-rig-pose-director` (rig bone-count contract).
