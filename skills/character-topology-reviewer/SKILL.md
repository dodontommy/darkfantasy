---
name: character-topology-reviewer
description: Use as the pre-rigging gate to audit a character mesh for deformation loops, manifold integrity, mirror, applied transforms, naming, UVs, tri budget, and Rigify-readiness; emits a PASS/FAIL/RISK checklist with an OVERALL verdict.
---

# Character Topology Reviewer

## When to invoke
- A character mesh (body, head, costume piece) is declared "ready for rigging".
- Before running Rigify generate (`bpy.ops.pose.rigify_generate`).
- Before exporting to USD / glTF / FBX for downstream tools (AccuRIG, UE5, Unity, Substance).
- After AI-mesh retopo (Rodin/Hunyuan/TRELLIS output that has been Quad-Remeshed).
- Whenever a sculptor says "I think it's done" — run the gates before believing them.

## Role
You are the technical-art topology reviewer. You do not sculpt; you do not rig; you only audit. You run a fixed numbered checklist with mechanical PASS/FAIL/RISK criteria and emit a markdown report with a single OVERALL verdict line. Anything that breaks rigging, deformation, or export is a **blocker**. Anything cosmetic is a **nit** — log it but don't block.

The L2M / T&L technical bar (per `docs/research/lineage2-art-style.md` §8): ~180-bone rig, 50–70k body+head tris, 30–60k outfit tris, ≤ 200k character total, 4K PBR ORM. The Rigify-headless flow you must protect is described in `docs/research/headless-blender-2026.md` §7.

## The blocker / nit distinction
- **Blocker** — anything that breaks Rigify generation, breaks deformation at the named joints, breaks export to glTF/FBX/USD, or violates the source-of-truth rule (per `orchestrator/README.md`: .py tracked, .blend regenerable). MUST be fixed before this skill returns PASS.
- **Nit** — cosmetic or efficiency issue that does not break the pipeline. Log in the report under `## Nits` but does not block.
- **Risk** — the gate technically passes but conditions exist that may cause downstream pain (e.g. tri budget at 95% of cap; deformation loop is quad but topology is non-ideal). Log under `## Risks`, do not block.

## The 10 gates (run in order)

### Gate 1 — Deformation loops at named joints
**Block on FAIL.** At eyes, mouth, shoulders, elbows, wrists, hips, knees, ankles, neck — the topology must be quad rings circling the joint axis, no triangles in the deformation path, ≥ 3 quad rings on each side of the joint within ~2× joint radius.

Manual check: enter Edit Mode, select the joint vertex, `Ctrl+Numpad+` to grow selection through edge loops; verify the grown ring is closed and quad-only.

Automated check (run in `--background` per `docs/research/headless-blender-2026.md` §3):
```python
import bpy, bmesh
def loop_quality_at_vertex_group(obj_name, vg_name, ring_radius=2):
    """Returns True if vertex group's neighborhood is quad-dominant."""
    obj = bpy.data.objects[obj_name]
    me = obj.data
    bm = bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table()
    vg = obj.vertex_groups[vg_name]
    seed_verts = [v for v in bm.verts
                  if any(g.group == vg.index for g in obj.data.vertices[v.index].groups)]
    nearby_faces = set()
    for v in seed_verts:
        for f in v.link_faces: nearby_faces.add(f)
    quads = sum(1 for f in nearby_faces if len(f.verts) == 4)
    tris  = sum(1 for f in nearby_faces if len(f.verts) == 3)
    bm.free()
    return quads, tris, (tris == 0)
```
Mark vertex groups `joint_eye_l`, `joint_mouth`, `joint_shoulder_r`, `joint_elbow_r`, `joint_wrist_r`, `joint_hip_r`, `joint_knee_r`, `joint_ankle_r`, `joint_neck` (and L counterparts) before running.

### Gate 2 — Manifold integrity
**Block on FAIL.** No non-manifold edges (edges shared by ≠ 2 faces), no holes, no zero-area faces, no duplicate vertices within 0.0001 m.

Automated:
```python
import bpy, bmesh
def manifold_audit(obj_name, merge_dist=0.0001):
    obj = bpy.data.objects[obj_name]
    bm = bmesh.new(); bm.from_mesh(obj.data)
    nonmanifold = [e for e in bm.edges if not e.is_manifold]
    holes = [e for e in bm.edges if len(e.link_faces) == 1]
    zero_area = [f for f in bm.faces if f.calc_area() < 1e-9]
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=merge_dist)
    # don't write back; this is audit only
    bm.free()
    ok = (len(nonmanifold) == 0 and len(zero_area) == 0)
    return {"nonmanifold_edges": len(nonmanifold),
            "open_edges": len(holes),
            "zero_area_faces": len(zero_area),
            "pass": ok}
```
Open edges (`holes`) are PASS for designed-open surfaces (cape interior, skirt panel inner side); RISK otherwise.

### Gate 3 — Mirror around X axis (symmetric meshes)
**Block on FAIL for body / head / matched-pair costume.** Vertices on the +X side must mirror to -X within 0.0001 m. Centerline vertices must have x = 0.

Automated:
```python
import bpy
def mirror_audit(obj_name, tol=0.0001):
    obj = bpy.data.objects[obj_name]
    verts = [v.co.copy() for v in obj.data.vertices]
    centerline = [v for v in verts if abs(v.x) < tol]
    centerline_off = [v for v in centerline if abs(v.x) > 1e-9]
    pos = sorted([v for v in verts if v.x > tol], key=lambda v: (round(v.y,4), round(v.z,4)))
    neg = sorted([(-v.x, v.y, v.z) for v in verts if v.x < -tol], key=lambda v: (round(v.y,4), round(v.z,4)))
    mismatches = sum(1 for p, n in zip(pos, neg)
                     if abs(p.x - n[0]) > tol or abs(p.y - n[1]) > tol or abs(p.z - n[2]) > tol)
    return {"centerline_off_axis": len(centerline_off),
            "mirror_mismatches": mismatches,
            "pass": (mismatches == 0 and len(centerline_off) == 0)}
```
Asymmetric pieces (the dominant pauldron, the skirt slit, the cape) are exempt — skip with explicit justification logged.

### Gate 4 — Applied scale + rotation
**Block on FAIL.** Object scale must be `(1.0, 1.0, 1.0)` and rotation must be `(0, 0, 0)` for any mesh that will bind to a rest pose. Otherwise Rigify, glTF skinning, and AccuRIG produce silent garbage.

Automated:
```python
def transform_audit(obj_name, tol=1e-5):
    o = bpy.data.objects[obj_name]
    s_ok = all(abs(o.scale[i] - 1.0) < tol for i in range(3))
    r_ok = all(abs(o.rotation_euler[i]) < tol for i in range(3))
    return {"scale": tuple(o.scale), "rotation_euler": tuple(o.rotation_euler),
            "pass": (s_ok and r_ok)}
```
Fix: select object, `Object > Apply > All Transforms`.

### Gate 5 — Naming and no `.001` duplicates
**Block on FAIL.** Naming convention: lowercase, underscored, scoped prefix (`nm_` for Nocturne Matriarch). No object, mesh, material, or image whose name ends in `.001`, `.002`, etc. — those are duplicate-imports that silently shadow originals.

Automated:
```python
import re
def name_audit(prefix="nm_"):
    issues = []
    for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for d in coll:
            if re.search(r"\.\d{3}$", d.name):
                issues.append(("dup_suffix", d.bl_rna.name, d.name))
            if isinstance(d, bpy.types.Object) and not d.name.startswith(prefix):
                issues.append(("missing_prefix", d.bl_rna.name, d.name))
            if d.name != d.name.lower() or " " in d.name:
                issues.append(("non_lowercase_or_spaces", d.bl_rna.name, d.name))
    return {"issues": issues, "pass": (len(issues) == 0)}
```

### Gate 6 — UV readiness
**Block on FAIL.** Every visible polygon has UV coordinates; no overlap on tiled materials; UV pack efficiency ≥ 0.7 per material atlas.

Automated:
```python
def uv_audit(obj_name):
    obj = bpy.data.objects[obj_name]
    me = obj.data
    if not me.uv_layers:
        return {"has_uv": False, "pass": False}
    uv = me.uv_layers.active.data
    polys_no_uv = sum(1 for p in me.polygons
                      if any((uv[li].uv.x == 0 and uv[li].uv.y == 0)
                             for li in p.loop_indices))
    return {"has_uv": True, "polys_at_origin": polys_no_uv,
            "pack_efficiency_estimate": "run_uvpackmaster_for_real_value",
            "pass": (polys_no_uv == 0)}
```
Manual: open UV editor, visually verify no overlaps on the body atlas. Accept overlap for mirrored UVs on symmetric features (intentional).

### Gate 7 — Triangle count budget
**Block on FAIL above hard cap.** Per `lineage2-art-style.md` §8 / §Direct Guidance §3:

| Component | Budget (tris) | Block above |
|---|---|---|
| Hero body+head combined | 50k–70k | 80k |
| Full hair (curves baked or cards) | 20k–40k | 50k |
| Outfit total (all costume layers) | 30k–60k | 70k |
| Weapons | 5k–15k | 20k |
| **Character total** | **≤ 200k** | **220k** |

Automated:
```python
def tri_count(obj_name):
    o = bpy.data.objects[obj_name]
    me = o.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    tris = sum((len(p.vertices) - 2) for p in me.polygons)
    return tris
```
Sum across the collection; compare to budget.

### Gate 8 — No orphan datablocks
**RISK on FAIL** (not blocker; orphans bloat .blend but do not break export). Datablocks with `users == 0` and `use_fake_user == False` should not exist after a `File > Clean Up > Purge`.

Automated:
```python
def orphan_audit():
    counts = {}
    for coll_name in ("meshes", "materials", "images", "armatures", "actions", "node_groups"):
        coll = getattr(bpy.data, coll_name)
        counts[coll_name] = sum(1 for d in coll if d.users == 0 and not d.use_fake_user)
    return counts
```

### Gate 9 — All collections visible at render
**Block on FAIL.** Every collection in the character hierarchy must have `hide_render == False`. Hidden geometry that the artist forgot is the #1 cause of "missing pauldron in the final render" tickets.

Automated:
```python
def visibility_audit(root_collection_name="nocturne_matriarch"):
    issues = []
    def walk(c):
        if c.hide_render: issues.append(("hidden_render", c.name))
        if c.hide_viewport: issues.append(("hidden_viewport", c.name))
        for o in c.objects:
            if o.hide_render: issues.append(("obj_hidden_render", o.name))
        for child in c.children: walk(child)
    walk(bpy.data.collections[root_collection_name])
    return {"issues": issues, "pass": (len(issues) == 0)}
```

### Gate 10 — Vertex group cleanup (Rigify deform bones)
**Block on FAIL.** No vertex with weight 0 across all Rigify deform bones (these waste rig storage and confuse weight transfer). No vertex with sum-of-weights > 1.001 across all groups.

Automated:
```python
def weight_audit(obj_name, deform_prefix="DEF-"):
    obj = bpy.data.objects[obj_name]
    deform_groups = [g.index for g in obj.vertex_groups if g.name.startswith(deform_prefix)]
    zero_count = 0
    over_one_count = 0
    for v in obj.data.vertices:
        s = sum(g.weight for g in v.groups if g.group in deform_groups)
        if s < 1e-6: zero_count += 1
        if s > 1.001: over_one_count += 1
    return {"zero_weight_verts": zero_count, "over_one_weight_verts": over_one_count,
            "pass": (zero_count == 0 and over_one_count == 0)}
```
Skip Gate 10 if rig is not yet bound (mark gate as N/A in report).

## Output format
The skill emits a single markdown block per character. Format exactly:

```markdown
# Topology Review — <object_or_collection_name>
Reviewed: <ISO timestamp>  
Reviewer: character-topology-reviewer skill  
Blender: <bpy.app.version_string>

## Gate Results
| # | Gate | Verdict | Detail |
|---|---|---|---|
| 1 | Deformation loops | PASS / FAIL / N/A | <quad/tri counts at each joint> |
| 2 | Manifold | PASS / FAIL | <nonmanifold edges, holes, zero-area> |
| 3 | Mirror (X axis) | PASS / FAIL / N/A | <mismatches; centerline off-axis> |
| 4 | Applied transforms | PASS / FAIL | <scale, rotation> |
| 5 | Naming & no .001 dupes | PASS / FAIL | <issue list> |
| 6 | UV readiness | PASS / FAIL | <polys at origin; pack notes> |
| 7 | Tri budget | PASS / FAIL | <tris vs cap> |
| 8 | Orphan datablocks | PASS / RISK | <counts per collection> |
| 9 | Visibility (render) | PASS / FAIL | <hidden items> |
| 10 | Weight cleanup | PASS / FAIL / N/A | <zero / over-one counts> |

## Blockers
- <gate#> <one-line description; how to fix>

## Risks
- <gate#> <one-line description>

## Nits
- <cosmetic items>

## OVERALL
**PASS** | **FAIL** — <one-sentence summary>
```

OVERALL is FAIL if any blocker is present, PASS otherwise. Risks and nits do not affect OVERALL.

## Quality gates (for the reviewer skill itself)
- [ ] All 10 gates run; none silently skipped without N/A justification.
- [ ] Each gate verdict has supporting numeric detail (not just "FAIL").
- [ ] Blockers list every FAIL with a concrete fix instruction.
- [ ] OVERALL line is unambiguously PASS or FAIL (no "mostly PASS").
- [ ] Report is reproducible: re-running on the same .blend produces identical output.
- [ ] Bpy snippets returned True/False (not crashed on missing groups/collections).

## References
- `docs/research/headless-blender-2026.md` §3 (bpy in --background, what works), §4 (sculpt operators), §7 (Rigify in headless), §10 (export pipelines).
- `docs/research/lineage2-art-style.md` §8 (technical fidelity benchmarks; tri budgets), §Direct Guidance §3 (body/outfit poly budget), §10 (rig bone count target ~180).
- `docs/research/dark-fantasy-shading-pipeline.md` §E1 (Rigify vs Auto-Rig Pro; why Rigify is the choice), §E2 (cape/skirt physics — secondary motion bones).
- `orchestrator/README.md` (source-of-truth rule: .py tracked, .blend regenerable; this audit must be runnable from CLI as part of the build).
