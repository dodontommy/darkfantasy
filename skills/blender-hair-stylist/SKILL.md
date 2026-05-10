---
name: blender-hair-stylist
description: Groom long flowing dark-fantasy hair in Blender 4.x — curves-based for hero stills, hair cards for animation, particle never. Invoke for hair generation, density, clumping, curl, length, guides, and hybrid strand→card baking.
---

# Blender Hair Stylist

## When to invoke
- Adding hair to the Nocturne Matriarch (or any hero character) where the placeholder is currently a `cone` or `sheet` mesh.
- Choosing between curves-based strands, baked hair cards, or particles for a given delivery target.
- Setting up the Geometry Nodes hair stack: Generate → Interpolate → Clump → Curl → Noise → Trim.
- Authoring guide curves (sculpt-mode Comb / Length / Pinch / Smooth / Add / Density).
- Diagnosing "strands explode at modifier evaluation" or "scalp pokes through when the camera moves".
- Pre-baking hair sim before a headless render (sim does not run in `--background` event-loop-free).

## Role
Encodes the hair workflow from `docs/research/dark-fantasy-shading-pipeline.md` Part B and the headless caveats from `docs/research/headless-blender-2026.md` §9. This skill covers grooming — placement, density, length, clumping, curl, noise — NOT shading. Shading lives in `blender-shader-builder` (Principled Hair BSDF, root-to-tip ColorRamp, anti-chalky discipline).

The persona is a character TD who already knows that particle hair is legacy in Blender 4.x, that the curves-based system has been the right answer since 3.5, and that long flowing dark-fantasy hair is built mass-first (4–6 primary locks) before strand-detail-last (never start with 10 k strands and try to "comb them into shape").

## Procedure

### 1. Decision matrix

| Target | Use | Notes |
|---|---|---|
| Still render, ArtStation portfolio shot, hero close-up | **Curves-based Hair object** (Blender 3.5+, polished 4.x) | True strands. Sculptable at 100 k+ strands. The 26 hair node groups in Essentials/Hair are the canonical building blocks. |
| Animation, turntable, game export, real-time engine | **Hair cards** baked from curves via Hair Tool 4 (Bartosz Styperek, requires Blender 4.2+; we are on 4.5 LTS) | Procedural Hair System modifier + Deformer nodes; per-card UV automation; integrated baker; jiggle bones. |
| Hybrid hero pipeline | Master strands as curves; bake to cards on demand | Same guide curves drive both. Sculpt guides once, fork from there. |
| Anything new | **Never particles.** | Legacy; curves system supersedes. |

For Nocturne Matriarch: curves-based for hero stills (Cycles), Hair Tool 4 baked cards if/when an animation pass is requested. Both share the guide curves.

### 2. Curves-based hair — practical setup (Blender 4.5)

1. `Object > Hair Curves > Empty Hair`. Parent to the scalp mesh. Assign vertex group `scalp_density` on the scalp.
2. In the hair object's Geometry Nodes modifier stack (Properties → Modifiers → Add Modifier → Geometry Nodes), append node groups from the Essentials asset library in this order. All 26 hair groups live under Generation / Deformation / Guides / Utility / Read / Write.
   - **Generate Hair Curves** — Density 1500 strands/m², Length driven by guides.
   - **Interpolate Hair Curves** — Guides 30, Neighbours 4, Noise 0.1.
   - **Hair Clump** — Clumping 0.6 in scalp regions, 0.2 at tips.
   - **Hair Curl** — Amplitude 0.01, Frequency 4 for waves; leave 0 for straight L2-style hair.
   - **Hair Noise** — Amplitude 0.005, Scale 50.
   - **Trim Curves** + **Set Curve Radius** — Taper from 0.0008 m at root to 0.00015 m at tip.
3. Sculpt the guide curves in Hair Sculpt mode using **Comb**, **Length**, **Pinch**, **Smooth**, **Add**, **Density**. Guides are the input to Generate / Interpolate; child strands fan out from them.

### 3. Append the Essentials hair node library from script

The library lives at `<blender>/<ver>/datafiles/assets/geometry_nodes/procedural_hair_node_assets.blend` (path documented in `docs/research/headless-blender-2026.md` §9).

```python
import os, bpy

datafiles = bpy.utils.system_resource("DATAFILES")
hair_lib  = os.path.join(datafiles, "assets", "geometry_nodes",
                         "procedural_hair_node_assets.blend")

with bpy.data.libraries.load(hair_lib, link=False) as (src, dst):
    dst.node_groups = [
        "Generate Hair Curves",
        "Interpolate Hair Curves",
        "Hair Clump",
        "Hair Curl",
        "Hair Noise",
        "Trim Curves",
        "Set Hair Curve Profile",
        "Frizz Hair Curves",
    ]

scalp = bpy.data.objects["Scalp"]
curves = bpy.data.hair_curves.new("Hair")
hair_ob = bpy.data.objects.new("Hair", curves)
bpy.context.scene.collection.objects.link(hair_ob)
hair_ob.parent = scalp

m = hair_ob.modifiers.new("Generate", "NODES")
m.node_group = bpy.data.node_groups["Generate Hair Curves"]
# Socket identifiers are unstable across hair-lib revisions. Inspect and key by name:
for item in m.node_group.interface.items_tree:
    if item.item_type == "SOCKET" and item.in_out == "INPUT":
        if item.name == "Surface":  m[item.identifier] = scalp
        if item.name == "Density":  m[item.identifier] = 5000
        if item.name == "Length":   m[item.identifier] = 0.20
```

Do not key sockets by ordinal `Input_2` — those break across point releases. Walk `interface.items_tree` and match by name.

### 4. Mass-first long flowing hair — first-pass recipe (Nocturne Matriarch)

Target silhouette: 60–90 cm length, parted centre or off-centre, two front tendrils framing the face, bulk swept behind shoulders, optional single twisted braid. Hair mass should equal or exceed the silhouette mass of the head — that is the "elegant noble" cue.

8-step procedure:

1. **Cap mesh.** Build a low-poly skull-cap mesh under the hair (duplicate scalp region of head, solidify 2 mm). Tint to root colour `#2A2222` (matches the bone-white hair root in `blender-shader-builder` C6). This hides scalp gaps and removes the #1 cause of "hair looks fake at glancing angles".
2. **Six guide locks, hand-drawn.** Add an Empty Hair, parent to cap. In Hair Sculpt mode, use **Add** brush (radius 0.05) to drop 6 primary guides: 2 front tendrils (left/right of face), 2 side masses (over ears), 2 back masses (centre-back parting). Length 0.7 m.
3. **Comb pass.** Use **Comb** brush, strength 0.5, to flow the back masses behind the shoulders and the front tendrils forward and down across the collarbone.
4. **Length variation.** **Length** brush, alternating shorten/lengthen, ±0.1 m on the back masses to break up flat-cut silhouette.
5. **Generate stack.** Add modifier stack from §2: Generate (Density 8000–12000 strands/m² for hero close-up; 1500 for medium shot), Interpolate (Guides 30, Neighbours 4, Noise 0.1).
6. **Clump.** Hair Clump 0.6 root → 0.2 tip. Adds the "wet-look" lock definition essential for dark fantasy long hair.
7. **Curl OR straight.** For Nocturne Matriarch: Curl 0 (straight, L2-style). For wavier variants: Amplitude 0.01, Frequency 4.
8. **Noise + Taper.** Hair Noise Amplitude 0.005 Scale 50; Trim Curves + Set Curve Radius taper 0.0008 → 0.00015.

After this 8-step pass, scrub camera around — silhouette should read mass-first. Only then layer in micro-detail (Frizz Hair Curves, additional sculpt-mode density paints).

### 5. Hair Tool 4 — strand-to-card bake (when you need cards)

Hair Tool 4 by Bartosz Styperek requires Blender 4.2+; we are on 4.5 LTS so available. Workflow:

1. Author hero strands per §4.
2. Add Hair Tool's Procedural Hair System modifier on the hair curves object.
3. Configure card density (typically 30–80 cards for a long Lineage-2-style hairstyle per `docs/research/lineage2-art-style.md` §6 — L2M raised this from the 6–10 of Prelude).
4. Bake textures: Hair Tool's integrated baker channel-packs strand → card (alpha + tangent + ID + flow). Per-card UVs are auto-laid.
5. Generate jiggle bones via Hair Tool's preview — gives 2–4 helper bones per major strand group, matching the L2M secondary-motion convention.
6. Replace shader: drop Principled Hair BSDF (curves-only), use Principled BSDF with `Anisotropic = 0.8` and rotation driven by the baked tangent map. Alpha Hashed in EEVEE-Next, Alpha Clip + AA in Cycles. (Shader recipe lives in `blender-shader-builder` §5 hair-cards paragraph.)

### 6. Headless caveat — sim must be cached before `--background` render

Hair sim and any cloth-driven secondary motion need a live event loop to bake. In `--background` runs (per `docs/research/headless-blender-2026.md` §3.2 and §9):

- Pre-bake the sim on the GUI workstation (Blender 4.5 with display), save the .blend.
- Or apply the Geometry Nodes hair modifier to mesh after grooming: `bpy.ops.object.modifier_apply` (works headlessly because GN evaluation does not need an event loop).
- For cloth-driven hair, export to Alembic (`bpy.ops.wm.alembic_export`) on the GUI side, re-import as cached on the headless render side.

Do not try to bake hair sim from `blender --background --python` — it will silently produce empty cache and the render comes out with hair in rest pose.

### 7. Density / length / radius cheatsheet

| Shot | Density (strands/m²) | Length (m) | Root radius (m) | Tip radius (m) |
|---|---|---|---|---|
| Hero close-up portrait | 10000–15000 | 0.7–0.9 | 0.0008 | 0.00015 |
| 3/4 medium | 5000–8000 | 0.7–0.9 | 0.0008 | 0.00020 |
| Full body | 1500–3000 | 0.7–0.9 | 0.0010 | 0.00025 |
| Game export (cards) | n/a — bake from the hero strands | 0.7–0.9 | n/a | n/a |

Strand count budget for Nocturne Matriarch hero stills: ~120 k total (per the recipe stack at the end of `dark-fantasy-shading-pipeline.md`).

### 8. Common failure modes and fixes

| Symptom | Cause | Fix |
|---|---|---|
| Hair looks like wig fibre / chalky | Base colour above `#F0EBE3` and no per-strand random | Drop base to `#F0EBE0`, add Random Color 0.08, Random Roughness 0.15 (see `blender-shader-builder` §5). |
| Strands explode through scalp | No cap mesh, or scalp poly normals flipped | Add cap mesh tinted root colour; verify `mesh.flip_normals` not needed. |
| Hair flat-cut silhouette | Single guide length, no Length-brush variation | §4 step 4 — alternate Length brush ±0.1 m. |
| Strands frizz outward at tips | Hair Noise amplitude too high, or no Trim Curves taper | Drop Noise to 0.005; ensure Trim taper to 0.00015 m. |
| Sim not visible in headless render | Sim never baked because `--background` has no event loop | §6 — bake on GUI side or apply modifier to mesh / Alembic export. |
| Cards bake at low quality | Strand source too sparse; baker samples each strand | Re-bake from the 10 k+ strand hero, not the 1.5 k far-shot version. |

## Quality gates

- [ ] Cap mesh present under hair, tinted to root colour, no scalp visible at glancing angle.
- [ ] 6 named guide curves, hand-combed, length variation applied.
- [ ] Generate / Interpolate / Clump / Curl / Noise / Trim modifier order is exactly that, top to bottom.
- [ ] Density matches shot tier (per §7 cheatsheet).
- [ ] Root radius ~5× tip radius for taper.
- [ ] If headless render planned: hair sim baked OR modifier applied OR Alembic cached BEFORE handoff.
- [ ] If hair cards: jiggle bones generated, anisotropic shader used, alpha mode Hashed/Clip set per engine.
- [ ] Strand count budget logged in scene metadata so render samples can be tuned.

## References

- `docs/research/dark-fantasy-shading-pipeline.md` Part B (B1 strategy decision matrix, B2 curves setup, B3 long flowing dark-fantasy hair) — primary source for densities, modifier stack, the cap-mesh + dark-roots discipline.
- `docs/research/headless-blender-2026.md` §9 — `procedural_hair_node_assets.blend` path, Hair Tool 4 / Blender version compatibility, `interface.items_tree` socket-by-name pattern.
- `docs/research/headless-blender-2026.md` §3.2, §4.3 — what does NOT work in `--background`: brush strokes, Dyntopo, hair sim event loop.
- `docs/research/lineage2-art-style.md` §6 — L2 / L2M hair card counts (6–10 Prelude, 30–80 L2M), bone-driven secondary motion convention, Dark Elf colour palette.
- `skills/blender-shader-builder/SKILL.md` §5 — Principled Hair BSDF recipe (root-to-tip ColorRamp, anti-chalky discipline) — this skill stops at grooming; shading is delegated there.
