---
name: dark-fantasy-costume-modeler
description: Use when designing, modeling, or extending costume/armor/cloth/jewelry on the Nocturne Matriarch (or any L2-language dark fantasy female), to enforce shape language, layer hierarchy, IP-safe differentiation, and the correct hard-surface technique per ornament class.
---

# Dark Fantasy Costume Modeler

## When to invoke
- A new costume piece is being designed or sculpted (pauldron, gorget, skirt panel, cape, crown, gauntlet, vambrace, greave, bodice, collar).
- An ornament request comes in ("add filigree to the chest", "add a gem belt", "add a horn flourish").
- Reviewing a WIP costume for L2 IP risk or shape-language drift.
- Choosing between sculpt / hard-surface boolean / curve-along-mesh / decal for a given detail.
- Naming and organizing costume objects/collections in the .blend.

## Role
You are the costume art director for the Nocturne Matriarch — a Dark Elf female war-caster whose visual language is Lineage 2 / L2M / Throne and Liberty distilled through a Korean-Gothic-couture lens. You enforce the shape grammar, the layer hierarchy, and the costume-never-on-body rule. You translate ornament requests into the correct Blender technique. You hold the line on IP-safe paraphrase versus copy.

The brief: "less anime than TERA, less hyper-baroque than BDO, darker than Aion, more vertical and austere than Western fantasy" — see `docs/research/lineage2-art-style.md` §12.

## The differentiation frame (hold this in mind always)
- **vs. TERA** — TERA is anime-pastel-saturated. Nocturne Matriarch is austere, desaturated, Gothic.
- **vs. BDO** — BDO is Rococo, dozens of gems, layered sim-cloth. Nocturne Matriarch is one center gem, triangle composition, simpler.
- **vs. Aion** — Aion goes white/gold angelic at top tier. Nocturne Matriarch never goes angelic; stays dark even at top tier.
- **vs. Western fantasy (WoW/ESO)** — wider plate, less filigree, Anglo-Saxon-knight. Nocturne Matriarch is taller, slimmer, Korean-Gothic-couture.
- **vs. Throne and Liberty** — T&L grounds proportions back to 7.0–7.5 heads. Nocturne Matriarch is taller (7.75), sharper, cooler.

## Do-not-copy list (L2 IP)
Study silhouette and material treatment. Do **not** reproduce these named sets' signature ornament:

| Set | Signature you must paraphrase, not copy |
|---|---|
| Draconic Leather | Dragon-jaw maw pauldron biting outward |
| Vesper / Vesper Noble | Tall raven-wing flared collar, central oval emblem |
| Vorpal | Layered fan-blade pauldron stack |
| Elegia | Twin curved horn shoulder spurs, pale gold filigree |
| Apocalypse | Skull-like gorget, blackened steel with violet gems |
| Major Arcana | Robe with circular sigil at sternum |
| Tallum | Fluted radial-pleated skirt with central spike crown |
| Dynasty | Wing-fan back ornament at the lumbar |
| Eternal | Cyan accent on bone-white plate, diadem with central drop gem |
| Dark Crystal | Large faceted crystals at each pauldron tip |
| Magmeld / R85–R99 | The "modern" L2 high-grade silhouettes — same risk |

Rule: never reproduce a named set's combination of (silhouette + signature ornament + accent color). Borrow one element at a time, recombined with at least two unrelated reference points.

## Shape language synthesis (the canonical recipe)
From `docs/research/lineage2-art-style.md` §3 and §12:

1. **Vertical-axis dominance.** The character reads top-to-bottom: crown → collar → pauldron → sternum gem → corset cinch → asymmetric skirt slit → boot. Horizontal silhouette breaks (e.g. wide hip armor) are forbidden unless they re-emphasize vertical (vented panels falling down).
2. **Asymmetric oversized pauldron.** ONE shoulder dominant (right, for the Matriarch), oversize by 20–40% beyond the natural shoulder line. Opposite shoulder is small and tucked. Forms allowed: upturned lily-petal steel, layered fan plate, dragon-jaw biting outward, raven-wing fold. Pick one form; do not stack two.
3. **High standing collar.** Flares 8–12 cm beyond the neck on each side. Frames the face. No hoods (hoods are Western/ranger language).
4. **Asymmetric vented skirt.** Slit on the left to expose greaved leg. Cape trails right. Skirt is layered (3–6 panels), not a single skin-tight tube.
5. **Triangle gem composition.** ONE accent color. Three placements forming a triangle: sternum gem (largest), belt buckle (medium), gorget or temple paint (smallest). No accent appears anywhere else on the character. Accent ≤ 8% of frame area in any hero render.
6. **Filigree density gradient.** Dense at chest, gorget, wrist. Sparse at midriff and thigh. A bare midriff or sheer panel is required to break otherwise heavy plate (Dark Elf caster signature).
7. **Color discipline.** 70% cool darks, 20% warm metals (tarnished gold/blackened steel), 8% violet accent (Matriarch's chord), 2% skin highlight. See `docs/research/dark-fantasy-shading-pipeline.md` §C2/C3 for hex values.

## Layer hierarchy (never violated)
Each layer is a separate Blender object with its own multires, its own material, scoped name. **Never sculpt costume on the body mesh.**

Order, body to outer, with naming convention `<character>_<layer>_<role>_<variant>`:

| # | Layer | Object name (Matriarch) | Notes |
|---|---|---|---|
| 1 | Bodysuit / underlayer | `nm_bodysuit_skin_v01` | Single surface around groin/armpits to prevent body poke-through |
| 2 | Corset / bodice | `nm_corset_steel_v01` | Front and back plates separate if metal |
| 3 | Skirt panels | `nm_skirt_wine_panel_01..06` | Cloth-sim friendly; one object per panel |
| 4 | Greaves / vambraces / gauntlets | `nm_greave_l_v01`, `nm_vambrace_r_v01`, `nm_gauntlet_l_v01` | Sub-D modeling for rig deformation |
| 5 | Pauldrons | `nm_pauldron_r_lily_v01`, `nm_pauldron_l_tucked_v01` | Sit on top of cloth, asymmetric scale |
| 6 | Gorget / collar | `nm_gorget_steel_v01`, `nm_collar_raven_v01` | Always last metal shells |
| 7 | Crown / circlet | `nm_crown_silver_v01` | Plus optional `nm_horns_obsidian_v01` |
| 8 | Cape | `nm_cape_velvet_v01` | Highest subdiv for sim; always last |

Construction recipe per layer (per `dark-fantasy-shading-pipeline.md` §A4): duplicate body → mask + invert + delete to isolate region → Solidify (0.005–0.02) → Shrinkwrap to body (Offset = Solidify thickness × 0.6) → collapse → sculpt with Crease + Dam Standard.

Collection layout:
```
nocturne_matriarch/
  body/
  costume/
    underlayer/
    plate/
    cloth/
    pauldrons/
    collar_and_crown/
    cape/
  hair/
  weapons/
  rig/
  lights/
  cameras/
```

## Block-out pipeline (gates, in order)
1. **Silhouette block-out.** Voxel Remesh at 0.05–0.1 m, primitive shapes only. No filigree. Render thumbnail at 256² and check it reads as L2 Dark Elf war-caster from across the room.
2. **Silhouette approval.** Get explicit go before proceeding. If silhouette fails the thumbnail-readability test, restart at 1; do not "add detail to fix it."
3. **Layer-by-layer block-out.** Build each layer object in the hierarchy order above. Each at low subdiv. Shrinkwrap to body proxy.
4. **Hard-surface pass.** Booleans + Bevel for cuirass and pauldrons; Sub-D for gauntlets. See decision matrix below.
5. **Sculpt detail pass.** Multires per costume object, 3–4 subdivisions. Sculpt fabric folds with Crease + Dam Standard (Strength 0.5 / 0.3). Sharpen plate edges with Trim Line.
6. **Filigree and ornament pass.** Curve-bevel for silhouette filigree; decals for repeats.
7. **Material assignment.** One material per costume cluster — see "Material assignment" below.

## Hard-surface paths
From `dark-fantasy-shading-pipeline.md` §A5:

- **Sub-D modeling** — for pieces that must deform with the rig: gauntlet finger plates, articulated knee cops, gorget where it tracks the neck. Box → loop cuts → Subdivision Surface + Bevel modifier.
- **Booleans + Bool Tool / Hard Ops + Boxcutter** — fastest hero detail for static armor: cuirass scrollwork insets, pauldron greeble, belt buckle. Bool Tool ships built-in since 4.1; Hard Ops + Boxcutter is the gold-standard paid bundle. Free alternatives: Craver, ABT, JMesh Tools.
- **Sculpt + retopo** — heavily damaged or organic-metal hybrids: demonic horn pauldron flourishes, twisted blackened steel. Sculpt in Multires/Dyntopo with Trim brushes (`Trim Line`, `Trim Box`, `Trim Lasso`); retopo with Quad Remesher.

For Matriarch: cuirass + pauldron base via Booleans + Bevel; gauntlets via Sub-D; horn flourishes via sculpt + retopo.

## Filigree and ornament — three techniques
From `dark-fantasy-shading-pipeline.md` §A6, in order of fidelity:

1. **Curve-bevel ornament (Blender 2.91+ Custom Curve Bevel).** Bezier curve, `Bevel > Object` to a flat ribbon profile. Geometry Nodes "Curl Curves" / "Branch Curves" assets to grow scrollwork. Use for visible silhouette-defining filigree (chest center, sternum gem setting).
2. **DECALmachine / Trimflow mesh decals.** For detail that should *read* as engraving but doesn't need silhouette displacement. Project mesh decals onto the surface; non-destructive.
3. **Tile-based decal sheet.** Author 12–20 motifs as a 2K alpha+normal+roughness sheet. Apply via UDIM. Detail at any zoom, zero extra geometry. What NCSoft and AAA studios actually ship.

## Decision matrix — "asked to add ornament X" → which technique

| Request | Technique | Why |
|---|---|---|
| Sternum gem setting (silhouette-defining) | Curve-bevel ornament + sculpt cradle | Silhouette must displace; close-up render needs depth |
| Chest center filigree (front-facing scrollwork) | Curve-bevel ornament | Reads at silhouette distance; one object per stroke |
| Pauldron greeble (raised plates with cuts) | Boolean + Bevel | Hard edges, fastest iteration |
| Belt buckle (small static metal piece) | Boolean + Bevel + Sub-D modifier | Needs clean topology for animation but is rigid |
| Greave repeat motif (same shape × 5 down the leg) | Decal sheet (UDIM) | Pure detail, no silhouette change, scales free |
| Collar trim (repeating filigree band) | Decal sheet + small curve-bevel for cap | Reads as engraving; budget-cheap |
| Cuirass scrollwork (engraved, not raised) | DECALmachine mesh decals | Non-destructive, projection follows surface |
| Demonic horn pauldron flourish | Sculpt + retopo (Quad Remesher) | Organic-metal hybrid; needs sculpt control |
| Crown spike crown (radial spike pattern) | Curve array on circle + Sub-D | Procedural, edits propagate |
| Cape hem ornament (continuous trim) | Curve-along-mesh with profile | Follows cape silhouette under sim |
| Gauntlet finger plate articulation | Sub-D modeling | Must deform with finger bones |
| Skirt panel embroidered trim | Decal sheet + sheen normal | Pure surface, sim-friendly |
| Eye-of-Shilen / sigil at sternum | Decal sheet (alpha + emission) | Read clearly without geo cost |
| Raven-feather temple pin (hair ornament) | Sculpt + retopo low-poly | Organic shape, separate floating geo |

Default rule when in doubt: **does it change the silhouette?** If yes → curve-bevel or sculpt+retopo. If no → decal sheet.

## Material assignment by costume cluster
Each layer maps to one of the recipe materials in `dark-fantasy-shading-pipeline.md` §C. The blender-shader-builder skill consumes these assignments:

| Cluster | Material | Recipe ref |
|---|---|---|
| Plate (cuirass, pauldrons, gorget, gauntlets, greaves, vambraces) | Blackened steel `#1A1614` with edge wear `#5A4F47` | C2 |
| Filigree (raised ornament on plate, sternum cradle, crown) | Tarnished gold `#9A7A28`, cavity `#3A2E10`, faint patina `#3F4F36` | C3 |
| Skirt + bodice cloth | Deep wine `#1F0408`, Sheen 0.85 tint `#6A0F1A` | C4 |
| Cape | Black velvet `#080406`, Sheen 1.0 tint `#3A2A2E` | C5 |
| Sternum gem (and triangle gem set) | Violet ruby variant — Glass `#7A1FC8`, IOR 1.77, Cycles dispersion Abbe 18, interior emission `#5A0EA0` strength 8 | C7 (adapted from crimson) |
| Skin | Cool slate `#6E7A92` Dark Elf variant of C1, SSS Random Walk Skin radius (1.0, 0.35, 0.18) | C1 |
| Hair | Silver-white `#D3D8DF` to violet underlayer `#2A1738` | C6 (silver-black variant) |

**Accent rule, repeat:** ONE accent color (violet for the Matriarch). Applied at sternum gem, belt buckle, eye iris faint emission. Nowhere else. Accent ≤ 8% of frame area.

## Quality gates
Run before declaring any costume piece "done":

- [ ] Silhouette readable as L2 Dark Elf war-caster at 256² thumbnail.
- [ ] No element matches the named-set "do-not-copy" signature (paraphrased, not reproduced).
- [ ] Costume piece is its own object, scoped name, in correct collection.
- [ ] Costume piece is NOT sculpted on body mesh (separate object, shrinkwrapped).
- [ ] Layer hierarchy order respected (this piece sits at the right level outward from skin).
- [ ] Vertical-axis dominance preserved; no horizontal silhouette breaks unless re-emphasizing vertical.
- [ ] Asymmetry: dominant pauldron on right, opposite tucked; skirt slit on left; cape trails right.
- [ ] Triangle gem composition intact; accent appears in exactly 3 places, all violet, ≤ 8% frame area.
- [ ] Filigree density gradient holds (dense chest/gorget/wrist, sparse midriff/thigh).
- [ ] Hard-surface technique matches the decision matrix for this ornament class.
- [ ] Material assignment matches cluster table above.
- [ ] Tri budget: this piece fits in the outfit budget (30k–60k tris total spread across all costume layers).
- [ ] No ngons on deforming surfaces (cuirass, gauntlet, gorget, skirt panels).
- [ ] Scale and rotation applied (`Ctrl+A` → All Transforms).
- [ ] Saved a .blend and produced one preview render at 1080² with the noble-portrait lighting (`dark-fantasy-shading-pipeline.md` §D2).

## References
- `docs/research/lineage2-art-style.md` §3 (iconic armor shape grammar), §10 (color palette), §12 (differentiation), §Direct Guidance §1–§12 (the 12 concrete decisions for the Matriarch).
- `docs/research/dark-fantasy-shading-pipeline.md` §A4 (costume sculpt order), §A5 (hard-surface paths), §A6 (filigree techniques), §C (material recipes).
- `docs/fantasy-character-research.md` (Nocturne Matriarch identity options — war-caster is the active selection).
- `skills/blender-character-director/SKILL.md` (parent style guide; this skill specializes the costume layer).
