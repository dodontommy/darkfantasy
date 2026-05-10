---
name: blender-rig-pose-director
description: Use to rig the Nocturne Matriarch — Rigify metarig setup, IK/FK, finger rigs, cape/skirt secondary motion, and the canonical noble-contrapposto pose. Invoke when the body+costume mesh is sealed and the next phase is armature, weighting, or pose-keying.
---

# Blender Rig & Pose Director

## When to invoke
- Body + costume topology is finalized (post-retopo, post-`character-topology-reviewer`) and a rig does not yet exist.
- A ticket asks for skinning, weight painting, IK setup, or pose-key authoring.
- Cape or skirt needs secondary motion (sim, bone chain, or hybrid).
- A render/export ticket is blocked because the armature is missing the noble-contrapposto pose.
- Choosing between Rigify, Auto-Rig Pro, and AccuRIG 2 for a new character variant.

## Role
Owns everything from "the mesh is sealed" to "the armature is bind-posed, weighted, posed, and ready for sim-bake or render". Delegates geometry edits back to the asset-builder skills; delegates final shader bakes back to `blender-shader-builder`. Encodes the L2 noble-fidelity bar (~180 deform bones, severe contrapposto, weapon/spell-focus hand) and the headless-Rigify recipe.

This skill owns rig taste. The pose is half the silhouette — wrong pose, dead character. The Matriarch is *not* in T-pose for any deliverable; she is in a 3/4-low-angle severe-contrapposto noble stance from the moment frame 1 exists.

## Rig generator decision matrix

Source: `docs/research/dark-fantasy-shading-pipeline.md` §E1.

| Generator | Pick when | Avoid when |
|---|---|---|
| **Rigify** (bundled, free) | Hero portfolio/render work, full IK/FK, custom cape pulls, bulletproof headless via `bpy.ops.pose.rigify_generate()`. **Default for the Matriarch.** | Need direct Mixamo/Unity FBX skeleton compatibility without retargeting. |
| **Auto-Rig Pro** (paid, Blender Market) | Game-engine export is the goal — its FBX exporter writes Mixamo-compatible bone names and a clean Unity hierarchy. | One-off Blender renders; Rigify covers it for free. |
| **AccuRIG 2** (Reallusion, free, standalone) | Fast initial weighting on AI-generated bodies (Hunyuan3D/Rodin output). Round-trip via FBX into Blender, then retarget. **AccuRIG 2 > Mixamo as of 2026** — Mixamo has not shipped meaningful updates and its rig still maxes at ~65 bones with no fingers. | Hero work where you need cape pulls, custom face controls, or anything beyond a body rig. |

**Recommendation for the Nocturne Matriarch:** Rigify body + custom shape-key face panel (subtle noble expressions read better than Rigify's bone face for this character). Add finger metarig for the clawed gauntlets. Expect ~180 deform bones after generation: ~60 body + 30 face shape-key drivers (counted as bones for budget) + 8 cape + 12 skirt + 12 hair + 8 pauldron secondaries.

## Rigify metarig customization for the Matriarch

Source: `docs/research/lineage2-art-style.md` § "Direct Guidance" (proportions) + `docs/research/headless-blender-2026.md` §7.

Customizations applied to `bpy.ops.object.armature_human_metarig_add()` output:

1. **Proportion lock to 7.8 heads.** Scale the metarig so head-bone length × 7.8 = total height from heel to crown. Adjust `spine`, `spine.001..006`, and leg chain proportionally.
2. **Narrow shoulders.** Move `shoulder.L` / `shoulder.R` head positions inward so the shoulder-tip-to-shoulder-tip distance equals 1.7 × head-width (Korean-Gothic-couture silhouette).
3. **Add finger metarig** for clawed gauntlets — the default human metarig already includes `f_index/middle/ring/pinky` plus `thumb` chains, but verify all 4 phalanges per finger are present (3 phalanx bones + palm). Generate clawed pose-shape later via pose-mode rotation, not topology.
4. **Eye bones** — keep the default `eye.L` / `eye.R`; they drive look-at via the `eyes` controller, useful for portrait-render eye contact.
5. **Pelvis cock prep** — leave `hips` neutral in the metarig; the contrapposto rotation is applied at the generated rig, not baked into bind pose.

## Headless Rigify generation

Full recipe — paste into `scripts/parts/rig_generate.py`:

```python
import bpy
from mathutils import Vector

# 0. Clean slate, factory startup assumed (--factory-startup)
bpy.ops.preferences.addon_enable(module="rigify")

# 1. Add human metarig
bpy.ops.object.armature_human_metarig_add()
metarig = bpy.context.object
metarig.name = "matriarch_metarig"

# 2. Lock 7.8-head proportion. Head bone length is the unit.
arm = metarig.data
bpy.ops.object.mode_set(mode='EDIT')
head_bone = arm.edit_bones["spine.006"]  # the head bone in the human metarig
head_len = (head_bone.tail - head_bone.head).length
target_total = head_len * 7.8
heel = arm.edit_bones["heel.02.L"].head.z
crown = arm.edit_bones["spine.006"].tail.z
scale = target_total / (crown - heel)
for eb in arm.edit_bones:
    eb.head *= scale
    eb.tail *= scale

# 3. Narrow shoulders to 1.7 head-widths.
head_width = head_len * 0.7  # rough head-width estimate
target_shoulder_span = 1.7 * head_width
for side in ("L", "R"):
    sb = arm.edit_bones[f"shoulder.{side}"]
    sign = 1 if side == "L" else -1
    sb.head.x = sign * (target_shoulder_span / 2 - 0.05)

bpy.ops.object.mode_set(mode='OBJECT')

# 4. Generate the rig
with bpy.context.temp_override(active_object=metarig, object=metarig,
                               selected_objects=[metarig],
                               selected_editable_objects=[metarig]):
    bpy.ops.pose.rigify_generate()

rig = bpy.data.objects["rig"]
rig.name = "matriarch_rig"

# 5. Verify deform bone count is in the ~180 envelope (body+face+secondaries
#    will be added later; expect ~120 from the base human rigify generation).
deform_bones = [b for b in rig.data.bones if b.use_deform]
assert 100 <= len(deform_bones) <= 140, f"Unexpected deform bone count: {len(deform_bones)}"
print(f"Rigify generated {len(deform_bones)} deform bones (body+face+fingers).")
```

Notes from `docs/research/headless-blender-2026.md` §7:
- `rigify_generate` runs in `--background` because all its operators have data-API paths.
- In 4.1+ the generated rig uses **bone collections** — use `armature.collections_all["FK"].is_visible = True`, not the removed `armature.layers[]`.
- Custom shape bones live in `~/Library/Bone Shapes` by default; for the Matriarch keep that naming so the rig UI panel renders correctly.

## Cape physics — baked Cycles cloth

Source: `docs/research/dark-fantasy-shading-pipeline.md` §E2.

Cape = ceremonial heavy fabric. Settings for the cloth modifier on the cape mesh:

| Setting | Value |
|---|---|
| Mass | 0.6 kg |
| Tension | 25 |
| Compression | 25 |
| Shear | 15 |
| Bending | 5 (high — keeps stiff folds, prevents jitter) |
| Air Damping | 1.2–1.5 |
| Stiffness (Internal Springs) | 5 |
| Pinning vertex group | `cape_pin` — shoulder/collar attachment loop |
| Collision object | low-poly body proxy (~2k tris of the body, hidden from render) |

Bake to alembic for headless render so the sim is deterministic and parallel-safe across render workers:

```python
# After cape sim is set up
bpy.ops.object.select_all(action='DESELECT')
cape = bpy.data.objects["cape"]
cape.select_set(True)
bpy.context.view_layer.objects.active = cape

# Bake cloth cache
override = {"scene": bpy.context.scene,
            "active_object": cape,
            "point_cache": cape.modifiers["Cloth"].point_cache}
with bpy.context.temp_override(**override):
    bpy.ops.ptcache.bake(bake=True)

# Export to alembic for headless re-import
bpy.ops.wm.alembic_export(
    filepath="//outputs/sim/cape.abc",
    selected=True,
    start=1, end=120,
    sh_open=0.0, sh_close=0.5,
    apply_subdiv=True,
)
```

## Skirt physics — bone chain + low-poly-cloth-as-bone-target

Skirt = 6 panels per the costume order in `docs/research/dark-fantasy-shading-pipeline.md` §A4. Each panel gets a 5–8 bone chain, parented to the hip bone.

Three options, ranked:

1. **Bone Dynamics Pro** (paid, Blender Market) — drives bone rotations from spring/damper params; clean UI; deterministic. **Recommended if budget allows.**
2. **Goo Physics** (paid, Superhive) — purpose-built for cape/skirt secondary motion, stylized "anime" feel. Pick if the look needs more swing than realism.
3. **Free DIY: low-poly-cloth-as-bone-target trick.** Sim a 6×8 vertex grid per panel with the cloth modifier (cheap, real-time bakeable), then add a Copy Location constraint on each chain bone targeting its nearest cloth vertex. This gives cinematic movement at game-rig cost.

Snippet for the DIY trick:

```python
# For each skirt panel: create low-poly cloth proxy, bind bone chain to it
import bpy

panel_names = [f"skirt_panel_{i:02d}" for i in range(6)]
chain_lengths = {n: 6 for n in panel_names}  # 6 bones per panel chain

for panel in panel_names:
    proxy = bpy.data.objects[f"{panel}_cloth_proxy"]  # 6×8 grid, cloth-simmed
    rig = bpy.data.objects["matriarch_rig"]
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='POSE')
    for i in range(chain_lengths[panel]):
        bone_name = f"{panel}_bone_{i:02d}"
        pb = rig.pose.bones[bone_name]
        # Snap to nearest proxy vertex via Copy Location
        c = pb.constraints.new(type='COPY_LOCATION')
        c.target = proxy
        c.subtarget = ""  # use whole-mesh nearest-vertex via vertex group
        c.influence = 0.85  # leave 15% bone authority
    bpy.ops.object.mode_set(mode='OBJECT')
```

## Noble contrapposto pose preset

Source: `docs/research/lineage2-art-style.md` §9.

The canonical pose for the Matriarch's hero render. Apply at frame 1 (frame 0 reserved for bind pose).

| Bone | Transform | Value |
|---|---|---|
| `hips` | Rotate Z | +8° (hip cock to character's left) |
| `shoulder.L` | Rotate Z | -3° (shoulder open) |
| `shoulder.R` | Rotate Z | +3° (shoulder open opposite) |
| `spine.001` | Rotate Z | -4° (counter-rotate to set the S-curve) |
| `spine.003` | Rotate Z | +2° (chest re-aligns toward camera) |
| `head` | Rotate Z | -2° (subtle head tilt toward dropped shoulder) |
| `head` | Rotate X | -3° (chin slightly down — severe noble) |
| `hand_ik.L` | Location | x=-0.4, y=-0.2, z=1.0 (chest-level focus position, weapon/spell-cast hand) |
| `hand_ik.L` | Damped Track constraint | target = `focus_empty` at (0, -0.3, 1.1) — the spell focus point |
| `hand_ik.R` | Location | x=0.35, y=-0.05, z=0.45 (relaxed at hip, light touch on weapon pommel) |
| `foot_ik.L` | Location | x=-0.18, y=0.05, z=0 |
| `foot_ik.R` | Location | x=0.22, y=-0.08, z=0 (back foot turned out 15°) |
| `eyes` | Location | y=-2.0 (eye contact with camera, ~2m forward) |

Snippet:

```python
import bpy
from math import radians

rig = bpy.data.objects["matriarch_rig"]
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE')

scene = bpy.context.scene
scene.frame_set(0)
# Bind pose at frame 0 — keyframe identity transforms on every controller
for pb in rig.pose.bones:
    pb.keyframe_insert("location", frame=0)
    pb.keyframe_insert("rotation_euler", frame=0)
    pb.keyframe_insert("rotation_quaternion", frame=0)

scene.frame_set(1)

POSE = {
    "hips":       {"rotation_euler": (0, 0, radians(8))},
    "shoulder.L": {"rotation_euler": (0, 0, radians(-3))},
    "shoulder.R": {"rotation_euler": (0, 0, radians(3))},
    "spine.001":  {"rotation_euler": (0, 0, radians(-4))},
    "spine.003":  {"rotation_euler": (0, 0, radians(2))},
    "head":       {"rotation_euler": (radians(-3), 0, radians(-2))},
    "hand_ik.L":  {"location": (-0.4, -0.2, 1.0)},
    "hand_ik.R":  {"location": (0.35, -0.05, 0.45)},
    "foot_ik.L":  {"location": (-0.18, 0.05, 0)},
    "foot_ik.R":  {"location": (0.22, -0.08, 0)},
}

for bone, transforms in POSE.items():
    pb = rig.pose.bones[bone]
    for attr, val in transforms.items():
        setattr(pb, attr, val)
        pb.keyframe_insert(attr, frame=1)

# Add focus empty + damped track on the casting hand
focus = bpy.data.objects.get("focus_empty") or bpy.data.objects.new(
    "focus_empty", None)
focus.location = (0, -0.3, 1.1)
if focus.name not in bpy.context.scene.collection.objects:
    bpy.context.scene.collection.objects.link(focus)

hand_l = rig.pose.bones["hand_ik.L"]
if "noble_focus_track" not in hand_l.constraints:
    c = hand_l.constraints.new(type='DAMPED_TRACK')
    c.name = "noble_focus_track"
    c.target = focus
    c.track_axis = 'TRACK_NEGATIVE_Z'

bpy.ops.object.mode_set(mode='OBJECT')

# Markers for alternate poses
scene.timeline_markers.new("bind",          frame=0)
scene.timeline_markers.new("noble_primary", frame=1)
scene.timeline_markers.new("spell_cast",    frame=10)
scene.timeline_markers.new("blade_drawn",   frame=20)
scene.timeline_markers.new("crown_lift",    frame=30)
```

Pose key conventions:
- **Frame 0:** bind pose (identity). `.blend` saves with armature in pose-mode showing this.
- **Frame 1:** `noble_primary` — the canonical hero render pose.
- **Frame 10:** `spell_cast` — left hand raised, palm open, focus_empty at z=1.6.
- **Frame 20:** `blade_drawn` — right hand on pommel pulled outward, left hand at guard.
- **Frame 30:** `crown_lift` — both hands at temples, head tilted up 8°. (Variant for promo.)

Each marker has a corresponding render preset in `blender-render-director`.

## Camera framing for portrait render

Source: `docs/research/lineage2-art-style.md` §9.

Set the hero camera (also exposed by `blender-render-director`):

- Lens: **70mm** (within the 50–85mm L2 range; 70mm gives the cleanest noble-portrait compression).
- Camera height: **15° below eye line** — eye-line is `head` bone tail z; place camera at `head.z - tan(15°) × distance`.
- Camera distance: **2.5–3.0 m** from subject for full-body, 1.4 m for chest-up.
- Subject occupies central **60%** of frame; cape and hair break the rule-of-thirds.

```python
cam = bpy.data.objects["hero_cam"]
cam.data.lens = 70
# Place at eye line, then drop 15° angularly, then aim at sternum
import math
eye_z = rig.pose.bones["spine.006"].tail.z + rig.location.z
distance = 2.7
cam.location = (0, distance, eye_z - distance * math.tan(math.radians(15)))
# Track-to constraint on sternum empty
sternum = bpy.data.objects.get("sternum_empty")
tt = cam.constraints.get("hero_track") or cam.constraints.new(type='TRACK_TO')
tt.name = "hero_track"
tt.target = sternum
tt.track_axis = 'TRACK_NEGATIVE_Z'
tt.up_axis = 'UP_Y'
```

## Quality gates

Checklist — every gate must be green before this skill's ticket closes:

1. **No zero-weight verts on deform bones.** Run `bpy.ops.paint.weight_from_bones()` only as fallback; manual weight cleanup preferred. Verify with:
   ```python
   for v in mesh.data.vertices:
       total = sum(g.weight for g in v.groups if mesh.vertex_groups[g.group].name in deform_bone_names)
       assert total > 0.001, f"Vertex {v.index} has no deform weight"
   ```
2. **Root bone at world origin.** `rig.pose.bones["root"].head_local == Vector((0,0,0))`. The character's world origin is between the feet at z=0 (per `character-export-validator` rule 3).
3. **Bind pose is the saved state.** When the `.blend` is saved, the armature is in pose-mode with frame 0 active — anyone opening the file sees identity transforms, not the hero pose.
4. **Deform bone count in envelope.** 160–200 deform bones (~180 target). Anything outside means the metarig customization or the secondary-bone setup is wrong.
5. **All custom shape bones use `~/Library/Bone Shapes` naming convention.** Verify with `bpy.data.objects["WGT-*"]` — the rig UI panel breaks if these are renamed.
6. **Pose markers exist:** `bind`, `noble_primary`, `spell_cast`, `blade_drawn`, `crown_lift`.
7. **Cape sim baked to alembic** at `outputs/sim/cape.abc`. Headless renders re-import this — they do **not** re-sim.
8. **Skirt bone chains parented to hips, not to root.** Hip rotation must drive skirt; root drives the whole character.
9. **Promotion block emitted.** Per `orchestrator/README.md` § "Source-of-truth promotion" — every MCP rig session ends with a `## Promotion` block of the bpy operations, ready to paste into `scripts/parts/rig_generate.py`.

## References

- `docs/research/dark-fantasy-shading-pipeline.md` §E1 (rig matrix), §E2 (cape/skirt physics).
- `docs/research/headless-blender-2026.md` §7 (Rigify in headless), §3.3 (`temp_override`), §6.1 (addon enable).
- `docs/research/lineage2-art-style.md` § "Direct Guidance" (proportions, ~180 bones), §9 (severe contrapposto, 70mm at 15° below eye line).
- `orchestrator/README.md` § "Source-of-truth promotion".
- `scripts/create_dark_fantasy_lady_blockout.py` — exemplar for headless script structure (`__main__`, `pathlib.Path` from `__file__`, factory-startup-safe addon enables).
- Hand-off targets: `blender-shader-builder` (texture bake before export), `blender-render-director` (hero portrait render), `character-export-validator` (when handing rigged character to a downstream engine).
