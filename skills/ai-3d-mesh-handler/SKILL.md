---
name: ai-3d-mesh-handler
description: Use when importing, scaling, axis-fixing, and recording provenance/license for any AI-generated 3D mesh (Rodin Gen-2, Hunyuan3D 2.5, Tripo, TRELLIS, Meshy, PolyHaven, Sketchfab) before retopo or use in the Nocturne Matriarch pipeline.
---

# AI 3D Mesh Handler

## When to invoke
- An AI mesh has just been generated or downloaded (.glb, .gltf, .obj, .fbx, .ply).
- Output of `mcp__blender__import_generated_asset` or `mcp__blender__import_generated_asset_hunyuan` lands in the scene.
- A direct-API Rodin Gen-2 call returns a URL (bypassing the gimped MCP wrapper — see below).
- Any Sketchfab download via `mcp__blender__download_sketchfab_model`.
- Before any retopo, baking, or "use in deliverable" step touches an AI mesh.
- A teammate asks "can we use this in a render?" — run the license-tracking gate first.

## Role
You are the AI-mesh intake clerk. Every AI mesh that enters the project goes through you first. You enforce: tool-correct selection, standard import-fix (scale/rotation/origin/rename/provenance), retopo decision, and license-tracking manifest entry. No AI mesh appears in a deliverable without a row in `outputs/ai_gen/MANIFEST.csv` that you wrote.

## Tool selection matrix
From `docs/research/ai-3d-generation-2026.md` (full doc) and `docs/research/blender-mcp-deep-dive.md` (gimped-Rodin caveat):

| Asset class | Primary tool | Why | How |
|---|---|---|---|
| Hero body base mesh | **Rodin Gen-2 direct API** (`hyperhuman.deemos.com/api/v2/rodin`) — NOT the MCP wrapper | The vendored MCP at `vendor/blender-mcp` v1.5.5 hardcodes `tier="Sketch"` + `mesh_mode="Raw"` (Gen-1 path). For body base you need `tier="Detail"` or higher, `T_Pose=true`, `topology="quad"`, `face_limit=18000`. See `blender-mcp-deep-dive.md` §174–211. | Direct HTTP POST with API key from `~/.config/hyper3d/api_key`; poll `/status`; download `.glb`. |
| Armor pieces / weapons / props (single static objects) | **Hunyuan3D 2.5** via MCP (`mcp__blender__generate_hunyuan3d_model`) | Sharper edges, fewer floating fragments than Rodin Sketch tier. PBR with physics-grounded materials. | OFFICIAL_API mode (Tencent Cloud) or LOCAL_API mode against self-hosted server. |
| Variant retexture of an existing mesh | **Meshy 6 Retexture** | Built for re-skinning; cheap iteration. | Web export to .glb. |
| Decomposed armor (pauldrons + gauntlets + breastplate as separate meshes) | **StdGEN** (CVPR 2025, self-hosted) | Only tool that returns per-part separated meshes from one input image. | Local GPU run; clone from `github.com/hyz317/StdGEN`. |
| Environment / HDRIs / props (CC0) | **PolyHaven** via MCP (`mcp__blender__download_polyhaven_asset`) | CC0, no attribution, fully commercial. | MCP tools. |
| Stock 3D models (variable license) | **Sketchfab** via MCP (`mcp__blender__download_sketchfab_model`) | Curated; per-asset license check required. | MCP tools. |
| IP-defensible self-hosted base mesh | **TRELLIS.2 (4B, MIT)** | Cleanest open-source posture in this whole space; ~24GB VRAM. | Local GPU run; HF `microsoft/TRELLIS.2-4B`. |
| Concept-sheet → 3D | **CSM AI Object/Character-Sheet-to-3D** | Genuinely differentiated for orthographic concept sheets. | Hosted, free trial. |
| Sub-second preview blockout | **Stable Fast 3D** (Stability) | ~0.5s, clean UVs, illumination-disentangled. | Self-hosted; preview only. |
| Fast hosted all-rounder | **Tripo 3.0/3.1** | Best end-to-end (gen + auto-rig) hosted pipeline. | Tripo Blender add-on or Python SDK. |

**Hard rule for Matriarch hero body:** Rodin Gen-2 direct API. The MCP path is unsuitable.

## Standard import procedure
Apply this to every AI mesh, regardless of source. Encoded as one bpy snippet:

```python
import bpy, hashlib, datetime, pathlib

def ai_import_fix(filepath, source, model_version, prompt_or_image_hash,
                  seed=None, license_str="unknown", commercial_use="unknown",
                  rename_root=None):
    """
    Import an AI-generated mesh and apply the standard fix:
      - prefer .glb / .gltf for PBR; fall back to .obj / .fbx
      - apply scale + rotation
      - center origin to bottom of mesh (feet on ground for characters)
      - rename root with provenance prefix
      - add custom properties recording source / version / hash / seed / timestamp
    Returns the imported root object.
    """
    fp = pathlib.Path(filepath)
    before = set(bpy.data.objects)
    ext = fp.suffix.lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(fp))
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=str(fp))  # Blender 4.x
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(fp))
    elif ext == ".ply":
        bpy.ops.wm.ply_import(filepath=str(fp))
    else:
        raise ValueError(f"unsupported AI mesh format: {ext}")

    new_objs = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new_objs if o.type == 'MESH']
    if not meshes:
        raise RuntimeError("no mesh objects imported")
    # Pick the largest mesh as the root
    root = max(meshes, key=lambda o: sum(o.dimensions))

    # Apply transforms
    bpy.ops.object.select_all(action='DESELECT')
    for o in new_objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Center origin to bottom-center for characters (feet on ground)
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    # Lower origin to mesh-bottom in Z
    min_z = min((root.matrix_world @ v.co).z for v in root.data.vertices)
    root.location.z -= min_z
    bpy.ops.object.transform_apply(location=True)

    # Rename with provenance prefix
    new_name = rename_root or f"{source}_{model_version}_{fp.stem}"
    new_name = new_name.lower().replace(" ", "_")[:60]
    root.name = new_name
    if root.data: root.data.name = new_name + "_mesh"

    # Provenance custom properties
    ts = datetime.datetime.utcnow().isoformat() + "Z"
    root["ai_source"] = source
    root["ai_model_version"] = model_version
    root["ai_prompt_or_image_hash"] = prompt_or_image_hash
    root["ai_seed"] = seed if seed is not None else "n/a"
    root["ai_generated_at"] = ts
    root["ai_license"] = license_str
    root["ai_commercial_use"] = commercial_use
    root["ai_source_file"] = str(fp)

    return root
```

Call example for a Rodin Gen-2 body:
```python
ai_import_fix(
    filepath="/work/outputs/ai_gen/rodin_body_v1.glb",
    source="rodin",
    model_version="gen2_18k_quad_tpose",
    prompt_or_image_hash="sha256:7c3f...e21",
    seed=4271,
    license_str="hyper3d_commercial_paid",
    commercial_use="yes",
    rename_root="rodin_gen2_body_v1",
)
```

## Retopo decision
AI mesh is high-poly soup. **Never bake from it without retopo first.**

| Situation | Tool | Notes |
|---|---|---|
| Hard-surface props (weapon, gem setting, gauntlet shell) | **Quad Remesher (Exoside) v1.3.0** | $99 indie / $260 standard. Battle-tested. Run at target ~10k–25k quads. |
| Body retopo | **Quad Remesher** for first pass, target ~30k quads | Then manual cleanup with RetopoFlow on shoulders/hips for deformation loops. |
| Face / hands | **RetopoFlow 4.1.6** (manual, in-Blender) | Released April 2026; integrated into Edit Mode. Manual is non-negotiable here. |
| Best-in-class auto-retopo (2026) — if you have access | **Hunyuan3D-PolyGen 1.5** | Closed beta in Tencent's HY3D engine; gated. Inquire if needed. Autoregressive quad mesher with continuous edge loops. |
| ZBrush users | **ZRemesher** | Bundled; same author as Quad Remesher. |
| Crude blockout only | Blender built-in **Quadriflow** | Free; not animation-grade. |

Decision rule: AI mesh → Quad Remesher pass → manual RetopoFlow on face and hands → topology audit (run `character-topology-reviewer` skill) → bake high-to-low.

## License manifest
Maintain `outputs/ai_gen/MANIFEST.csv` at the project root. Required columns:

```
file,source,model_version,prompt_or_image_hash,seed,license,commercial_use,generated_at
```

Append-only. One row per AI mesh entering the project. Example rows:

```
rodin_gen2_body_v1.glb,rodin,gen2_18k_quad_tpose,sha256:7c3f...e21,4271,hyper3d_commercial_paid,yes,2026-05-10T14:22:01Z
hunyuan_pauldron_r_v01.glb,hunyuan3d,2.1_apache,sha256:b912...01a,seed_8821,apache_2.0_eu_uk_kr_excluded,yes_outside_eu_uk_kr,2026-05-10T15:10:44Z
trellis2_horn_v01.glb,trellis2,4B_mit,sha256:f01a...77c,seed_44,MIT,yes,2026-05-10T15:48:11Z
sketchfab_chain_link.glb,sketchfab,uid_a87b3,n/a,n/a,CC-BY-4.0_attr_required,yes_with_attribution,2026-05-10T16:05:12Z
polyhaven_anvil_2k.gltf,polyhaven,2024_anvil_01,n/a,n/a,CC0,yes,2026-05-10T16:09:55Z
```

Helper script (run once per import):
```python
import csv, pathlib, datetime
def manifest_append(row, manifest_path="outputs/ai_gen/MANIFEST.csv"):
    p = pathlib.Path(manifest_path); p.parent.mkdir(parents=True, exist_ok=True)
    new_file = not p.exists()
    with p.open("a", newline="") as f:
        w = csv.writer(f)
        if new_file:
            w.writerow(["file","source","model_version","prompt_or_image_hash",
                        "seed","license","commercial_use","generated_at"])
        w.writerow(row)
```

**No row in MANIFEST.csv → mesh is not allowed in any deliverable.** This is a hard gate.

## IP / license posture (May 2026)
From `docs/research/ai-3d-generation-2026.md` "IP, license, and dataset hygiene in 2026":

- **US Copyright Office.** Pure-AI output with no human creative contribution beyond a prompt is **not copyrightable**. Supreme Court denied cert in Thaler appeal **March 2, 2026**. AI-assisted works *can* be protected for the human-authored parts. Document your sculpt cleanup, retopo, texture composition with screenshots and version history to establish authorship.
- **EU AI Act training-data transparency.** Enforcement begins **August 2, 2026**. Every general-purpose AI model provider must publish a public training-dataset summary using the Commission's mandatory template. Penalties up to **€15M or 3% of global revenue**.
- **Tool-specific posture:**
  - **Rodin Gen-2 (Hyper3D)** — full commercial rights stated for output on all tiers (including Free). Training-data disclosure thin. Treat outputs as commercial-usable; do not assume the tool indemnifies you.
  - **Hunyuan3D 2.1** — Apache 2.0 weights, but the official model card **explicitly excludes use in EU, UK, South Korea** due to regulatory exposure. If you operate in those jurisdictions, do not ship Hunyuan2.1 outputs.
  - **TRELLIS / TRELLIS.2** — MIT, cleanest open posture. Research-paper-disclosed dataset (~500K objects).
  - **Tripo / Meshy / Luma / CSM** — commercial rights with paid plan; no public dataset disclosure.
  - **Stable Fast 3D** — Stability Community License with revenue cap; verify current terms.
  - **Adobe Firefly textures** — IP-indemnified for enterprise; cleanest commercial posture.
  - **Sketchfab downloads** — per-asset license (CC-BY default; also CC-BY-NC, CC-BY-ND, CC-BY-SA, Standard Sketchfab, Editorial). Always check; CC-BY requires attribution in shipped product.
  - **PolyHaven** — CC0, no attribution required, fully commercial.

**Recommended posture for Nocturne Matriarch:** Self-hosted Hunyuan3D 2.1 OR licensed Hyper3D Rodin (commercial paid) → human sculpt + texture pass (establishes copyrightable authorship) → CC0 PolyHaven HDRIs and reference textures → Adobe Firefly for any text/heraldry generation. Document every manual step with timestamps in MANIFEST.csv-adjacent notes.

## Cleanup pipeline (per AI mesh)
Run in order:

1. **Import + fix** — `ai_import_fix()` snippet above.
2. **Audit polycount** — log `len(mesh.polygons)` and triangle count; flag if > 500k (TRELLIS.2 / Hunyuan can exceed 1M).
3. **Optional triangulate** — only if downstream tool requires it (UE5 import); otherwise skip — preserve quads where they exist.
4. **Retopo** — Quad Remesher → RetopoFlow per the decision table above.
5. **Bake high-to-low** — bake normal, AO, curvature, position from the original AI mesh onto the retopo. Use Cycles bake at 4K with 32 samples + cage.
6. **UV repack** — UVPackmaster 3 or Blender built-in pack. Target ≥ 0.7 packing efficiency.
7. **Texture transfer** — if Rodin / Hunyuan returned PBR maps, repack onto the new UVs (`bpy.ops.object.bake` with target image per channel: albedo, normal, roughness, metallic).
8. **Manifest entry** — `manifest_append()`.
9. **Run topology audit** — invoke `character-topology-reviewer` skill on the cleaned mesh; do not proceed until OVERALL = PASS.

## Quality gates
- [ ] Source file (.glb / .obj / .fbx) preserved at original path; never deleted, never overwritten.
- [ ] `ai_import_fix()` ran cleanly: scale = (1,1,1), rotation = (0,0,0), origin at mesh bottom.
- [ ] Root object renamed with provenance prefix; no `.001` suffix.
- [ ] All 8 custom properties (`ai_source`, `ai_model_version`, `ai_prompt_or_image_hash`, `ai_seed`, `ai_generated_at`, `ai_license`, `ai_commercial_use`, `ai_source_file`) populated on the root object.
- [ ] One row appended to `outputs/ai_gen/MANIFEST.csv` with all required columns.
- [ ] License field is one of: `CC0`, `CC-BY-*_attr_required`, `MIT`, `Apache_2.0_*`, `hyper3d_commercial_*`, `tripo_pro`, `meshy_paid`, `stability_community_*`, `adobe_firefly_indemnified` — or an explicit `unknown` flagged for legal review.
- [ ] If license has a jurisdictional carve-out (Hunyuan2.1 EU/UK/KR), `commercial_use` field reflects it (`yes_outside_eu_uk_kr`).
- [ ] Retopo decision logged: which tool, target tri count, who/what ran it.
- [ ] After retopo, `character-topology-reviewer` skill returned OVERALL = PASS.
- [ ] No AI mesh used in any rendered deliverable lacks a MANIFEST.csv row.
- [ ] Rodin path used for hero body was direct API (Gen-2 with `T_Pose=true`, `topology="quad"`, `face_limit≥18000`) — NOT the MCP wrapper's `tier="Sketch"` / `mesh_mode="Raw"` Gen-1 path.

## References
- `docs/research/ai-3d-generation-2026.md` (full doc): "At-a-glance comparison" table, "Best workflow for a high-fidelity dark fantasy character in 2026" §1–§10, "What you still cannot trust AI for in 2026", "Retopology after AI generation in 2026", "IP, license, and dataset hygiene in 2026", "Recommended pipeline for Nocturne Matriarch" §1–§9.
- `docs/research/blender-mcp-deep-dive.md`: Tool Inventory table for `generate_hyper3d_*` / `generate_hunyuan3d_*` / `import_generated_asset*`; §174–211 (Rodin Gen-1 vs Gen-2 gimped-wrapper detail); Sketchfab license gotcha §285–295.
- `MEMORY.md` → `project_blender_mcp_gimped_rodin.md` (vendored 1.5.5 hardcodes Rodin Gen-1 Sketch + Raw; hero base mesh needs direct Rodin Gen-2 API call).
- `skills/character-topology-reviewer/SKILL.md` (must PASS before any AI mesh proceeds to rigging or render).
