---
name: blender-shader-builder
description: Author PBR shaders for Nocturne Matriarch in Blender 4.x using Principled BSDF v2 — skin, blackened steel, tarnished gold, wine cloth, bone-white hair, crimson gem. Invoke when adding or fixing materials in scripts/ or via MCP.
---

# Blender Shader Builder

## When to invoke
- New material needed in a build script and you need correct Blender 4.x Principled BSDF v2 inputs (no more `Specular`, only `IOR` + `IOR Level`).
- An existing material reads as plastic, chalky, or chrome instead of "blackened steel / oxidised gold / wine velvet".
- White hair renders chalky, gem renders flat, skin renders waxy.
- Adding cavity/edge-wear masks, sheen layers, coat layers, Random-Walk-Skin SSS.
- Wiring a material into the existing `mat()` helper in `scripts/create_dark_fantasy_lady_blockout.py`.

## Role
Encodes the Nocturne Matriarch shader stack from `docs/research/dark-fantasy-shading-pipeline.md` Part C. All recipes target Blender 4.2+ Principled BSDF v2 (the v2 overhaul shipped in 4.0). Vocabulary changes from 3.x habit:

- `Specular` input is gone — use `IOR` + `IOR Level` (default 0.5 = old Specular 0.5).
- `Subsurface Method` includes `RANDOM_WALK_SKIN` — mixes diffuse + specular transmission entry, retains surface detail. Use for skin.
- `Sheen` is now the Microfiber LTC model (Zeltner/Burley/Chiang) — replaces old Velvet/Ashikhmin. New inputs: `Sheen Weight`, `Sheen Roughness`, `Sheen Tint`.
- `Coat` is a true layered lobe — `Coat Weight`, `Coat Roughness`, `Coat IOR`, `Coat Tint`, `Coat Normal`.

This skill provides the persona of a look-dev TD who already knows AgX is the default view transform since 4.0, knows the "subtract 0.5 / multiply 8 / clamp" pointiness amplifier, and knows that white hair without a gradient looks like wig fibre.

## Procedure

### 0. Match the existing `mat()` API

`scripts/create_dark_fantasy_lady_blockout.py` exposes:

```python
def mat(name, color, metallic=0.0, roughness=0.45, emission=None, strength=0.0):
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
```

When extending: keep `mat(name, color, metallic, roughness, ...)` as the base call and add an `enrich_*` post-processing function per material that walks the node tree to add SSS / Sheen / Coat / cavity / edge nodes. Do NOT break the existing positional signature — the blockout script depends on it.

Hex-to-RGBA helper (Blender expects linear RGBA tuples in the 0–1 range; `default_value` does sRGB→linear behind the scenes for `Base Color` since 4.0):

```python
def hex_rgba(h, a=1.0):
    h = h.lstrip("#")
    return (int(h[0:2],16)/255, int(h[2:4],16)/255, int(h[4:6],16)/255, a)
```

### 1. Pale ivory skin (Random Walk Skin SSS)

Hex base `#E8D2C0`. RGBA `(0.91, 0.82, 0.75, 1.0)`. SSS radius ratio `(1.0, 0.35, 0.18)` (Caucasian convention). `Subsurface Scale = 0.012` for an 1.8 m character.

```python
def enrich_skin(m):
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.subsurface_method = "RANDOM_WALK_SKIN"
    bsdf.inputs["Subsurface Weight"].default_value  = 1.0
    bsdf.inputs["Subsurface Radius"].default_value  = (1.0, 0.35, 0.18)
    bsdf.inputs["Subsurface Scale"].default_value   = 0.012
    bsdf.inputs["Subsurface IOR"].default_value     = 1.4
    bsdf.inputs["Subsurface Anisotropy"].default_value = 0.0
    bsdf.inputs["IOR"].default_value                = 1.45
    bsdf.inputs["Coat Weight"].default_value        = 0.05
    bsdf.inputs["Coat Roughness"].default_value     = 0.25
    bsdf.inputs["Coat IOR"].default_value           = 1.45
    bsdf.inputs["Sheen Weight"].default_value       = 0.15
    bsdf.inputs["Sheen Roughness"].default_value    = 0.4
    bsdf.inputs["Sheen Tint"].default_value         = hex_rgba("FFE6D6")
    bsdf.inputs["Roughness"].default_value          = 0.45
```

Lip variant: drive `Base Color` to `#B86870`, raise `Roughness` to 0.35, raise `Coat Weight` to 0.1.

### 2. Blackened steel (`#1A1614` → `#5A4F47` cavity / edge reveal)

Recipe: edge-wear mask from Pointiness amplified `(p − 0.5) × 8` clamped, optional Bevel cleanup, Voronoi breakup. Cavity mask from `ShaderNodeAmbientOcclusion` (Inside ON, Distance 0.05). Mix base colour A→B with edge mask, modulate Roughness with edge AND cavity.

`Metallic = 1.0`, `IOR Level = 0.6`, base Roughness 0.42 lifted to 0.28 on edges, +0.15 in cavities. Brushed-metal anisotropic noise (scale 800, detail 2) into Bump 0.05.

Cavity-from-pointiness snippet (reusable across all metals):

```python
def add_cavity_edge_masks(m):
    nt = m.node_tree
    geom    = nt.nodes.new("ShaderNodeNewGeometry")
    sub     = nt.nodes.new("ShaderNodeMath"); sub.operation="SUBTRACT"; sub.inputs[1].default_value=0.5
    mul     = nt.nodes.new("ShaderNodeMath"); mul.operation="MULTIPLY"; mul.inputs[1].default_value=8.0
    clamp   = nt.nodes.new("ShaderNodeMath"); clamp.operation="MINIMUM"; clamp.inputs[1].default_value=1.0
    edge_cr = nt.nodes.new("ShaderNodeValToRGB")
    edge_cr.color_ramp.elements[0].position = 0.0
    edge_cr.color_ramp.elements[1].position = 0.55
    nt.links.new(geom.outputs["Pointiness"], sub.inputs[0])
    nt.links.new(sub.outputs[0],  mul.inputs[0])
    nt.links.new(mul.outputs[0],  clamp.inputs[0])
    nt.links.new(clamp.outputs[0], edge_cr.inputs["Fac"])

    ao    = nt.nodes.new("ShaderNodeAmbientOcclusion")
    ao.inside = True
    ao.samples = 16
    ao.inputs["Distance"].default_value = 0.05
    cav_cr = nt.nodes.new("ShaderNodeValToRGB")
    cav_cr.color_ramp.elements[1].color = hex_rgba("2A2520")
    nt.links.new(ao.outputs["Color"], cav_cr.inputs["Fac"])
    return edge_cr, cav_cr   # plug into Mix Color Fac and Roughness modulator
```

### 3. Tarnished gold trim (`#9A7A28` body, `#3A2E10` cavity, `#3F4F36` patina hint)

ColorRamp on the cavity mask drives Base Color: 0.00 `#3A2E10` → 0.30 `#6E4F1A` → 0.70 `#9A7A28` → 1.00 `#C39A38`. Add patina `#3F4F36` only where AO < 0.15 (extra ColorRamp clamp into Mix-Add Fac 0.15). `Metallic = 1.0`. Roughness ColorRamp on cavity: 0.0 → 0.55 (cavities), 0.7 → 0.22 (raised). Optional `Anisotropic = 0.3` driven by tangent map for radial scrollwork. No Coat.

The trim should match the existing `mat("tarnished gold trim", (0.74, 0.52, 0.19, 1), metallic=1.0, roughness=0.34)` blockout call. After construction, run `enrich_gold(m)` to install the cavity gradient.

### 4. Deep wine cloth (`#1F0408` body, sheen tint `#6A0F1A`)

```
Base Color   = hex_rgba("1F0408")
Metallic     = 0.0
Roughness    = 0.85
IOR          = 1.45
Sheen Weight    = 0.85   # microfiber LTC; community testing matched ref at ~2.0 raw, 0.85 in Principled stack
Sheen Roughness = 0.30
Sheen Tint      = hex_rgba("6A0F1A")
Normal: tileable woven_normal_2K → Normal Map node, Strength 0.4
```

Black velvet cape variant: Base `#080406`, Sheen Tint `#3A2A2E` (cooler), Sheen Weight 1.0, normal Strength 0.6, no hem dirt.

Hem dirt vertex group (`hem_dirt`) drives Mix-RGB darken to `#0A0102` at 0.4 in Base Color path.

### 5. Bone-white hair — Principled Hair BSDF (NOT Principled BSDF)

Use `ShaderNodeBsdfHairPrincipled` with `parametrization = "COLOR"` (Direct Coloring). Never push base colour above `#F0EBE3` — that is the anti-chalky ceiling. Always include darker roots and per-strand jitter; let Sheen + Tint break specular.

```python
def build_hair_white(m):
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out  = nt.nodes.new("ShaderNodeOutputMaterial")
    hair = nt.nodes.new("ShaderNodeBsdfHairPrincipled")
    hair.parametrization = "COLOR"
    hair.inputs["Color"].default_value          = hex_rgba("F0EBE0")
    hair.inputs["Roughness"].default_value      = 0.30
    hair.inputs["Radial Roughness"].default_value = 0.55
    hair.inputs["Coat"].default_value           = 0.10
    hair.inputs["IOR"].default_value            = 1.55
    hair.inputs["Offset"].default_value         = 0.0523    # 3° in radians
    hair.inputs["Random Color"].default_value     = 0.08
    hair.inputs["Random Roughness"].default_value = 0.15

    info  = nt.nodes.new("ShaderNodeHairInfo")
    ramp  = nt.nodes.new("ShaderNodeValToRGB")
    cr    = ramp.color_ramp
    cr.elements[0].position = 0.0;  cr.elements[0].color = hex_rgba("2A2222")  # root: charcoal
    cr.elements.new(0.15).color = hex_rgba("6A6058")
    cr.elements.new(0.50).color = hex_rgba("BFB8AC")
    cr.elements[-1].position = 1.0; cr.elements[-1].color = hex_rgba("F0EBE0") # tip
    nt.links.new(info.outputs["Intercept"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], hair.inputs["Color"])
    nt.links.new(hair.outputs[0], out.inputs["Surface"])
```

Silver-black variant: invert ramp — `#0A0808` root → `#1A1A1F` mid → `#7A7A82` tip; `Radial Roughness = 0.45` for sharper specular.

For hair **cards** (animation/game export), drop Principled Hair BSDF; use Principled BSDF with `Anisotropic = 0.8`, anisotropic rotation driven by a tangent map baked from strands; Alpha Hashed in EEVEE-Next, Alpha Clip + AA in Cycles.

### 6. Crimson focus gem (Glass + interior emission, dispersion via Cycles)

Outer faceted shell:
- Glass BSDF, Color `#FF1424`, Roughness 0.0, IOR 1.77 (ruby).
- Mix with Glossy BSDF, Color `#FFB0B0`, Roughness 0.05 via Layer Weight Fresnel (IOR 1.77).
- Enable Cycles dispersion on the material; Abbe = 18 (ruby).
- Render: `Light Paths > Max Transmission Bounces = 32`, `Filter Glossy = 1.0`.

Interior mesh (smaller copy at scale 0.85): Emission `#C8000E` strength 8.0, mixed with Transparent BSDF using Layer Weight Facing 0.5 — pushes glow to interior facets.

Emerald variant: Glass `#14C840`, Glossy `#C8FFD0`, Emission `#007A20`, Abbe 22.

### 7. Universal procedural breakup (apply to every metal and cloth)

```
Voronoi (F1, scale 350, randomness 1.0)  → ColorRamp 0.0–0.15 black → DAMAGE_MASK
Noise   (scale 50, detail 8, distortion 0.5) → ColorRamp 0.4–0.6 → GRIME_MASK
```

`DAMAGE_MASK` → mix into Base Color (push toward darker), Bump 0.02.
`GRIME_MASK` → mix into Roughness (+0.15 in occluded zones), Base Color warm dark wash `#1A1208` at 0.2.

Per the project brief the canonical "grime" Voronoi scale is 80 and Noise scale is 25 — those are the silhouette-readable coarse layers; the values above (350 / 50) are the high-frequency micro-layers. Use both stacked when the camera is closer than 1 m.

### 8. Color management — AgX, NOT Filmic

Set globally per scene:

```python
s = bpy.context.scene
s.view_settings.view_transform = "AgX"
s.view_settings.look           = "AgX - Punchy"
s.view_settings.exposure       = -0.4
s.view_settings.gamma          = 1.0
```

Filmic crushes the wine `#6A0F1A` sheen and the crimson gem `#FF1424` toward yellow (Notorious Six failure). AgX preserves them. Mandatory for this project.

### 9. Texture image color spaces (when painted maps arrive)

| Map | `image.colorspace_settings.name` |
|---|---|
| Diffuse / Base Color | `sRGB` |
| Normal map | `Non-Color` |
| Roughness | `Non-Color` |
| Metallic | `Non-Color` |
| AO | `Non-Color` |
| Emission Color | `sRGB` |
| Mask / data | `Non-Color` |

Wrong colorspace on a normal map is the #1 cause of "shading looks slightly broken but I can't tell why".

## Quality gates

- [ ] Every material has a unique `bpy.data.materials` name; no two objects share a material accidentally.
- [ ] No purple "missing texture" indicators in the rendered viewport.
- [ ] Skin uses `RANDOM_WALK_SKIN`, not `RANDOM_WALK` or `BURLEY`.
- [ ] Hair uses `ShaderNodeBsdfHairPrincipled` with a root-to-tip ColorRamp; base colour ≤ `#F0EBE3`.
- [ ] All metals have `Metallic = 1.0` AND a cavity mask AND an edge-wear mask.
- [ ] Wine cloth + cape have non-zero Sheen Weight with a tint distinct from base colour.
- [ ] Gem has a separate interior emission mesh (not a single-shader fake).
- [ ] Scene `view_transform == "AgX"`, `look == "AgX - Punchy"`, `exposure == -0.4`.
- [ ] All non-color textures use `Non-Color` colorspace.
- [ ] `mat()` signature in `scripts/create_dark_fantasy_lady_blockout.py` still accepts the original positional args; enrichments are additive.

## References

- `docs/research/dark-fantasy-shading-pipeline.md` Part C (sections C1 skin, C2 steel, C3 gold, C4 wine cloth, C5 cape, C6 hair, C7 gem, C8 breakup) — primary source for every hex code, ColorRamp position, and node value above.
- `docs/research/dark-fantasy-shading-pipeline.md` D3 — AgX color management rationale.
- `scripts/create_dark_fantasy_lady_blockout.py` lines 20–31 — existing `mat()` helper signature to preserve.
- `docs/fantasy-character-research.md` — Nocturne Matriarch palette brief (pale ivory skin, bone-white hair, blackened steel, tarnished gold, deep wine cloth, crimson gem).
- `docs/research/lineage2-art-style.md` §5 — L2 material discipline: gold ≤ 8% surface area, gems suggest light not bloom out.
