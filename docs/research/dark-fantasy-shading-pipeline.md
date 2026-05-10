# Dark Fantasy Character Pipeline in Blender 4.x

**Project codename:** Nocturne Matriarch
**Target style:** Lineage 2 / Lineage 2M / Throne and Liberty — elegant high fantasy with gothic ceremonial overtones, Korean MMO fidelity.
**Tooling baseline:** Blender 4.2 LTS through 4.5 (Hair Tool 4 minimum), Cycles for hero renders, EEVEE‑Next for look‑dev. Some notes flag features only present in Blender 5.0 (released Nov 2025) where they are obviously useful but not required.
**Document scope:** Sculpting forms, hair, shaders/materials, render setup, rigging. Each shader includes either a node graph description or a `bpy` snippet, with explicit RGB/hex values, and a final per‑material recipe stack.

---

## Part A — Sculpting & Forms

### A1. Base‑mesh to detail pipeline

Modern Blender 4.x sculpting separates cleanly into three regimes and the discipline is to know when to switch (Sofia Pahaoja's "Remesh + multires workflow" and the Packt *Sculpting the Blender Way* book both lay this out clearly).

1. **Blockout — Voxel Remesher.** Start from a sphere or a low‑poly base. Use Voxel Size 0.05–0.1 m (character height ≈ 1.8 m). After each major silhouette change, `Ctrl+R` re‑voxelises so topology is uniform. Rule of thumb: never reduce voxel size by more than 1.5× per pass or you'll get visible faceting.
2. **Mid‑range form — Dyntopo (situational).** Dynamic Topology has fallen out of favour as a primary workflow but is still excellent for additive work like ear cartilage, finger webs, decorative belt knots. Use Constant Detail at 8–12 px, never Relative; Relative breaks once you zoom.
3. **High‑frequency detail — Multires.** Once silhouette and primary forms are locked, retopologise (Quad Remesher / RetopoFlow / manual) to ~25–40 k tris for a hero character, then add a Multiresolution modifier and Subdivide 4 times for ~6 M faces of working surface for pores, fabric weave, micro‑scratches.

**Brush set for "elegant severe" female sculpt (in this order during the sculpt):**

| Stage | Brush | Settings |
|---|---|---|
| Big shape | Clay Strips | Strength 0.6, Normal Radius 0.5, accumulate ON for build‑up |
| Plane definition (cheekbones, clavicle, sternum, hip bone) | Flatten + Trim Line | Strength 0.4, Front Faces Only |
| Sharp creases (nasolabial, upper eyelid crease, corset seams) | Crease | Strength 0.5, Pinch 0.7 |
| Skin folds and sharp valleys | Dam Standard | Strength 0.3 |
| Soft volume push (lower lip, breast, calf) | Inflate | Strength 0.2 |
| Tendrils, hair tendrils blockout, fabric pulls | Snake Hook | Strength 0.6, Pinch 0.4 |
| Hard‑surface detail | Mask + Extract / Mask + Boolean (`Mesh > Mask > Extract Mask`) | mask blur 5–10 |

### A2. Severe / regal female face proportions

Lineage 2 noble characters and Throne & Liberty's Solisium portraits push real anatomy toward an idealised silhouette. Drawing from PencilKings' female face guide and the broader `21-draw.com` / `learntodrawfaces.com` references, the deltas from neutral realism are:

- **Cheekbones:** sit higher than the midline of the eye‑to‑chin distance — roughly at 0.40 down from brow line (vs 0.45 realistic). Lateral apex is wider than the corner of the eye by ~0.5 eye‑width. Plane between cheekbone and jaw is flatter and longer.
- **Jawline:** tapered, "heart" shape. Gonial angle (mandible corner) softened, mental protuberance narrow. Width at chin ≈ 0.6 of width at temples, vs 0.7 realistic.
- **Eye spacing:** classic "one eye between the eyes" but eyes are slightly larger (1.05× width of the gap) and the outer canthus is tilted up by 3–5°.
- **Brow:** thinner and arched higher than realistic; brow ridge less pronounced (a deliberately feminine cue).
- **Lips:** upper lip vermilion narrower than lower (1:1.3). Cupid's bow well defined. Mouth width = pupil‑to‑pupil distance × 0.95.
- **Neck:** long. From clavicle notch to chin = 1.25× the head's chin‑to‑hairline distance. This is a defining "noble silhouette" cue and should be exaggerated against your reference photos.
- **Nose:** narrow bridge, dorsal line straight or with a hint of dorsal hump. Tip refined, nostrils narrow.

Yansculpts' *Sculpting Stylized Character Busts* and FlippedNormals' *Female Game Character Creation* (Blender‑native) both use this "raised cheekbone, lifted outer canthus, narrow chin" recipe. ZBrushCentral threads on Lineage‑style busts converge on the same proportional set.

### A3. Noble silhouette — body

Aim for **7.75 heads tall** (8 feels heroic but loses the human regality; 7 is too "real" and thick). Heroic women in Lineage 2 art books sit between 7.5 and 8.

- Shoulder width: 1.6 head‑widths (vs 1.8 male).
- Waist: 0.7 of shoulder width.
- Hips: 0.95 of shoulder width.
- **Leg length:** crotch lands at 3.6 heads from top, not 4. Femur slightly elongated. This is the single biggest "MMO heroine" cheat.
- Hands: long, slender; middle finger length = 0.5 head height.
- Neck cylinder: diameter 0.45 of head width.

### A4. Costume sculpt order — costume as separate objects

Rule, never violated: **never sculpt costume on the body mesh.** Each garment is its own object, shrinkwrapped to the body, with its own multires. This keeps body alterations cheap and lets you swap costumes.

Layer order, body to outer:

1. Bodysuit / underlayer (single‑surface skin substitute around groin, armpits — prevents body poke‑through).
2. Corset / bodice (cuirass shell). Sculpt as separate front and back plates if metal.
3. Skirt panels (multiple layered panels for cloth simulation later).
4. Greaves, vambraces, gauntlets.
5. Pauldrons and gorget (always last metal shells — they sit on top of cloth).
6. High collar.
7. Crown / circlet.
8. Cape (its own object, always last; high subdiv for sim).

Each piece: duplicate body, isolate the surface region with mask + invert + delete, add Solidify (0.005–0.02), add Shrinkwrap targeting body (Offset = Solidify thickness × 0.6), then collapse and start sculpting fabric folds with Crease + Dam Standard.

### A5. Hard‑surface armor — three valid paths

For pauldrons, vambraces, gauntlets and gorget you choose by use‑case:

- **Sub‑D modeling (cleanest topology, animator‑friendly).** Box → loop cuts → Subdivision Surface + Bevel modifier. Use for pieces that need to deform with the rig (gauntlet finger plates, articulated knee cops).
- **Booleans + Hard Ops/Boxcutter (fastest hero detail).** masterxeon1001's Hard Ops + Boxcutter remains the gold standard in 2026. Free alternatives: **Bool Tool** (built‑in since 4.1), **Craver**, **ABT (Advanced Boolean Tool)**, **JMesh Tools**. Use for static armor: cuirass scrollwork insets, pauldron greeble.
- **Sculpt + retopo.** Heavily damaged or organic‑metal hybrids (think Throne & Liberty horned shoulder pieces) — sculpt in Multires/Dyntopo with Trim brushes (`Trim Line`, `Trim Box`, `Trim Lasso`) and retopologise with Quad Remesher.

For Nocturne Matriarch armor: cuirass and pauldrons via Booleans + Bevel; gauntlets via Sub‑D for rig deformation; demonic horn‑pauldron flourishes via sculpt + retopo.

### A6. Filigree and ornament

Three reliable techniques, in order of fidelity:

1. **Curve‑bevel ornament (Blender 2.91+ Custom Curve Bevel).** Create a Bezier curve, set `Bevel > Object` to a small profile (a flat ribbon). Use Geometry Nodes "Curl Curves" / "Branch Curves" assets to grow scrollwork. This is Gesa Pickbrenner's *All About Curves* method. Best for visible filigree on the cuirass front panel.
2. **DECALmachine / Trimflow.** For detail that should *read* as engraving but doesn't need silhouette displacement, project mesh decals or trim‑texture decals to the surface. Trimflow's "draw a curve, swap trim" keeps everything non‑destructive.
3. **Tile‑based decal sheet.** Author a 2K sheet of ornament motifs (12–20 pieces) as alpha+normal+roughness. Apply via UDIM or via decal projection. This is what NCSoft and AAA studios actually ship: detail at any zoom, zero extra geometry.

For Nocturne Matriarch: Curve‑bevel for the chest filigree (silhouette‑defining), decal sheet for repeated motifs on greaves and collar.

---

## Part B — Hair

### B1. Strategy decision

Blender 4.x gives three first‑class options:

- **Curves‑based Hair object (Blender 3.5+, polished in 4.x).** True strands. Hair Curves use the new `Curves` data‑block, sculptable interactively at 100 k+ strands thanks to localised brush calculations. The 4.x Essentials asset library ships **26 Hair node groups** in the Asset Browser under Deformation / Generation / Guides / Utility / Read / Write — drag‑and‑drop into the hair object's Geometry Nodes modifier stack.
- **Hair cards (Hair Tool 4 by Bartosz Styperek).** The community standard for game‑ready hair. Procedural Hair System modifier + Deformer nodes, per‑card UV automation, integrated baker that channel‑packs strand → card textures, generates jiggle bones with preview. Compatible with Blender 4.2+.
- **Particle hair (legacy).** Avoid for new work; the curves system fully supersedes it.

**Hybrid choice for Nocturne Matriarch:** strands for hero close‑up renders and ArtStation portfolio shots; baked hair cards for any rigged/animated/turntable presentation. Both share the same guide curves — sculpt guides once, then either render strands directly or feed those guides into Hair Tool 4 to generate cards.

### B2. Curves hair — practical setup

1. Add `Object > Hair Curves > Empty Hair`, parent to the scalp mesh, assign to a vertex group `scalp_density`.
2. In the Geometry Nodes modifier stack, add (in order, all from the Essentials asset library):
   - **Generate Hair Curves** — density 1500 strands/m², length driven by guides.
   - **Interpolate Hair Curves** — guides 30, neighbours 4, noise 0.1.
   - **Hair Clump** — clumping 0.6 in scalp regions, 0.2 at tips.
   - **Hair Curl** — for wave: amplitude 0.01, frequency 4. For straight L2‑style hair, leave at 0.
   - **Hair Noise** — amplitude 0.005, scale 50.
   - **Trim Curves / Set Curve Radius** — taper from 0.0008 m at root to 0.00015 m at tip.
3. Sculpt guides in Hair Sculpt mode with **Comb**, **Length**, **Pinch**, **Smooth**, **Add**, **Density**.

### B3. Long flowing hair, bone‑white / silver‑black

For the Lineage 2 silhouette: 60–90 cm length, parted centre or off‑centre, two front tendrils framing the face, bulk swept behind shoulders, a single twisted braid optional. Use a low‑poly *cap* mesh under the hair to hide scalp gaps; tint cap to roots colour.

Avoid the common "chalky white" failure: white hair without tonal variation reads as wig fibre. Always include darker roots, micro‑coloured noise (cool grey to warm cream), and crank anisotropic shine. Shader recipe is in C7.

---

## Part C — Shaders / Materials in Blender 4.x

All recipes assume Blender 4.2+ Principled BSDF (the "v2" overhaul shipped in 4.0). Key vocabulary changes from old habit:

- **Specular** input is gone; it is now **IOR** + **IOR Level**.
- **Subsurface Method** has a **Random Walk (Skin)** option that mixes diffuse + specular transmission entry, retains surface detail.
- **Sheen** has a new **Microfiber** model (default) — based on Zeltner/Burley/Chiang LTC paper — replacing the old Velvet/Ashikhmin model.
- **Coat** is a true layered lobe with its own Tint, IOR, Roughness and Normal.

### C1. Skin shader — Pale Ivory (Random Walk Skin)

Target hex: base **#E8D2C0** (pale ivory). SSS tint: **#D8634B** (pinkish‑red diffuse mean free path tint). Lip variant base **#B86870**.

**Node graph:**

```
[Image Texture: Diffuse]──┐
                          ├─→ [Mix RGB: Multiply, Fac 0.15, B = #F1D9C7]──→ Base Color
[ColorRamp on Pointiness] ┘                                                    │
                                                                              │
Subsurface Weight = 1.0
Subsurface Method = Random Walk (Skin)
Subsurface Radius = (1.0, 0.35, 0.18)   # red 1.0, green 0.35, blue 0.18 — scaled for 1.8 m character
Subsurface Scale = 0.012                # 12 mm — tune by camera distance
Subsurface IOR = 1.4
Subsurface Anisotropy = 0.0

Roughness:
  [Image: Roughness] ──→ [ColorRamp 0.35→0.55] ──→ Roughness
  Add a 4K Noise Texture (scale 800, detail 4) at 0.05 strength to break up T‑zone.

IOR = 1.45    # skin
IOR Level = 0.5

Coat Weight = 0.05    # tiny clearcoat for cheek/forehead oil sheen
Coat Roughness = 0.25
Coat IOR = 1.45

Sheen Weight = 0.15   # peach fuzz
Sheen Roughness = 0.4
Sheen Tint = #FFE6D6

Normal:
  [Image: Normal Map (pores, baked from sculpt 4K)] ──→ [Normal Map node, Strength 0.7] ──→ Normal
```

The radius triple `(1.0, 0.35, 0.18)` is the conventional Caucasian ratio; the literal scattering distance scales with `Subsurface Scale`. Per the Blender devtalk/docs: real diffuse mean free path on human skin is roughly R 3 / G 0.75 / B 0.4 mm — divide by 4π (≈ 12.56) to convert to Blender's Random Walk convention, giving R 0.24 / G 0.060 / B 0.032 at scale 1.0; we feed the ratio `(1, 0.35, 0.18)` and tune brightness with Scale at 0.012, which is equivalent.

**Procedural micro‑variation (no painted maps yet):**

```
[Voronoi: F1, scale 250] ──→ ColorRamp (0.45 → 0.6 white) ──→ multiply 0.05 → add to Base Color
[Noise: scale 80, detail 6] ──→ ColorRamp ──→ multiply 0.10 → add to Roughness
```

### C2. Blackened steel armor

Target hex: base **#1A1614** (near‑black with warm cast). Edge wear exposes **#5A4F47** (darker steel underneath, *not* shiny chrome — this is hammered steel that's been heat‑blued, oiled and tarnished).

**Node graph:**

```
# --- EDGE WEAR MASK ---
Geometry > Pointiness ──→ Math (Subtract 0.5) ──→ Math (Multiply 8) ──→ Math (Clamp 0–1)
       ──→ ColorRamp [0.0 black → 0.55 white] ──→ EDGE_MASK

# Optional: combine with bevel‑node curvature for cleaner Cycles result
Bevel (Samples 8, Radius 0.002) ──→ Vector Math (Dot Product with Geometry > Normal)
       ──→ ColorRamp ──→ multiply with EDGE_MASK above

# Break it up so it isn't uniform around every edge:
[Noise: scale 30, detail 5] ──→ ColorRamp 0.4–0.6 ──→ Multiply with EDGE_MASK ──→ FINAL_EDGE

# --- CAVITY / GRIME MASK ---
Ambient Occlusion (Samples 16, Distance 0.05, Inside ON)
       ──→ ColorRamp [0.0 black → 0.6 dark warm grey #2A2520] ──→ CAVITY_MASK

# --- BASE STEEL MIX ---
Mix Color (Fac = FINAL_EDGE):
   A = #1A1614   (blackened steel)
   B = #5A4F47   (worn steel revealed)
       ──→ Base Color

Metallic = 1.0

Roughness:
   Mix (Fac = FINAL_EDGE): A = 0.42, B = 0.28
   Add CAVITY_MASK × 0.15 (cavities feel rougher with grime)
       ──→ Roughness

IOR Level = 0.6  # blackened steel reads slightly less specular than polished

Normal:
   Brushed‑metal anisotropic noise: Noise (scale 800, detail 2) → Bump 0.05
```

Sources: ArtStation jsabbott "Procedural edge wear in Blender 4.2", BlenderKit's Edge Wear assets, blenderartists threads on pointiness + bevel. The "Subtract 0.5 → Multiply ~5–20 → Clamp" trick to amplify pointiness is the canonical post‑processing for usable curvature data and applies cleanly to all four metal/wood materials.

### C3. Tarnished gold filigree

Target hex: base **#9A7A28** (old yellow gold, slightly desaturated). Cavities **#3A2E10** (dark amber/oxide). Faint patina hint **#3F4F36** (cool green) painted only at deepest cavities.

```
# Reuse CAVITY_MASK from C2 (AO node) — but with Distance 0.03 for tighter recesses
# Reuse FINAL_EDGE for highlight on raised filigree

# --- BASE GOLD STACK ---
Base Color:
  ColorRamp on (CAVITY_MASK):
    0.00 → #3A2E10   (cavity dark)
    0.30 → #6E4F1A   (transition)
    0.70 → #9A7A28   (gold body)
    1.00 → #C39A38   (raised, hand‑polished)
        ──→ Mix RGB (Add, 0.15) with patina #3F4F36 masked by AO < 0.15
        ──→ Base Color

Metallic = 1.0

Roughness:
  ColorRamp on (CAVITY_MASK):
    0.0 → 0.55 (rough cavities)
    0.7 → 0.22 (polished raised)
       ──→ Roughness
  Add Voronoi (scale 600) × 0.05 for micro‑scratches.

IOR = 0.47  # not literally physical, but for gold the artistic IOR is around 0.18 (real) — the Principled BSDF in metallic mode interprets IOR via F0 channel; default 1.45 reads fine for gold once base colour is correct.

Coat Weight = 0  # no clear coat
Anisotropic = 0.3, Anisotropic Rotation driven by tangent map for radial scrollwork (optional)
```

### C4. Deep wine cloth (skirts, gown body)

Target hex: base **#1F0408** (almost black with a wine cast). Warp/weft sheen colour **#6A0F1A** (deep oxblood).

```
Base Color = #1F0408
Roughness = 0.85
Metallic = 0
IOR = 1.45

Sheen Weight = 0.85
Sheen Roughness = 0.3
Sheen Tint = #6A0F1A     # the wine sheen reads at grazing angle

# Fabric weave normal
Image Texture (tileable woven_normal_2K) → Normal Map (Strength 0.4) → Normal

# Subtle dirt at hem
Vertex group `hem_dirt` (painted) ──→ Mix RGB darken to #0A0102 at 0.4
```

Per the Blender 4.0 release notes, the new Sheen BSDF (now a layer of Principled) implements Zeltner et al.'s LTC microfiber sheen — community testing on crushed velvet found Sheen Weight ~2.0 with Sheen Roughness 0.3 matched reference, but in a Principled stack 0.85 is the clamped equivalent and reads correctly.

### C5. Black velvet cape (separate from C4)

Same as C4 but: Base Color = `#080406`, Sheen Tint = `#3A2A2E` (cooler, dust‑like), Sheen Weight 1.0, fabric normal scale 0.6, no hem dirt.

### C6. Bone‑white hair (Principled Hair BSDF, strand mode)

Use Cycles **Principled Hair BSDF** with Coloring Method = **Direct Coloring** for art‑directed white. Melanin mode also works for graded silver but is harder to push pure white without going chalky.

```
Shader: Principled Hair BSDF
  Color = #F0EBE0          # warm bone, NOT pure white
  Roughness = 0.30
  Radial Roughness = 0.55
  Coat = 0.10              # slight cuticle gloss
  IOR = 1.55
  Offset = 3°              # tilt of cuticle scales — human ~3°
  Random Color = 0.08      # per‑strand hue jitter
  Random Roughness = 0.15  # per‑strand roughness jitter
  Random = use a Hair Info > Random output

# ROOT‑TO‑TIP DARKENING (avoid chalky)
Hair Info > Intercept ──→ ColorRamp:
   0.00 (root) → #2A2222   (charcoal — silver‑black reading)
   0.15        → #6A6058
   0.50        → #BFB8AC
   1.00 (tip)  → #F0EBE0
       ──→ Color input

# COOL/WARM PER‑STRAND VARIATION
Hair Info > Random ──→ ColorRamp:
   0.0 → #E6E2D8 (cool)
   1.0 → #F4ECDA (warm)
       ──→ Mix RGB (Multiply, 0.1) with previous → Color
```

For the **silver‑black** variant (jet hair with silver highlights), invert the gradient: `#0A0808` at root, `#1A1A1F` mid, `#7A7A82` cool steel highlight at tip. Push Radial Roughness to 0.45 for sharper specular.

For **hair cards**, replace Principled Hair BSDF with Principled BSDF, Anisotropy 0.8, Anisotropic Rotation driven by a tangent map baked from strands. Set Alpha from a packed alpha channel of the baked card texture and use Alpha Hashed in EEVEE‑Next or Alpha Clip + AA in Cycles.

### C7. Crimson focus gem (and emerald variant)

Use a **Glass BSDF** as the primary lobe with chromatic dispersion in Cycles, plus an internal **Emission** from a darker secondary mesh for the iconic deep glow. Paco Salas / Emanuel Neto's "Chromatic Dispersion Glass" stacks 12 stepped Glass BSDFs at slightly varying IORs — overkill for a small focal gem; a single Glass with `Cycles > Light Paths > Filter Glossy = 1.0` and Cycles' built‑in Dispersion (added in Cycles in 4.x) is enough.

```
# --- OUTER GEM SHELL (faceted mesh, sub‑surfaced once) ---
Mix Shader (Fac = Layer Weight > Fresnel, IOR 1.77 ruby):
   Glass BSDF, Color = #FF1424, Roughness = 0.0, IOR = 1.77
   Glossy BSDF, Color = #FFB0B0, Roughness = 0.05

Cycles > Render > Light Paths > Max Transmission Bounces = 32
Cycles > Volumetrics or Material > Dispersion enabled, Abbe = 18 (ruby)

# --- INTERIOR MESH (a smaller copy of the gem, scale 0.85) ---
Emission, Color = #C8000E, Strength = 8.0
Mix with Transparent BSDF using Layer Weight > Facing 0.5 — this pushes glow to interior facets

# Emerald variant
   Glass Color = #14C840
   Glossy Color = #C8FFD0
   Emission Color = #007A20
   Abbe = 22
```

### C8. Procedural detail breakup (universal)

Every metal and cloth material gets:

```
[Voronoi: F1‑F2 distance, scale 350, randomness 1.0] ──→ ColorRamp 0.0–0.15 black ──→ DAMAGE_MASK
[Noise: scale 50, detail 8, distortion 0.5] ──→ ColorRamp 0.4–0.6 ──→ GRIME_MASK
```

`DAMAGE_MASK` mixes into Base Color (push toward darker) and Normal (small bump 0.02). `GRIME_MASK` mixes into Roughness (+0.15 in occluded zones) and Base Color (warm dark wash #1A1208 at 0.2).

---

## Part D — Render Setup

### D1. Cycles vs EEVEE‑Next in 2026

- **Cycles** is still mandatory for hero portrait skin: Random Walk SSS, true Hair BSDF dispersion, gem caustics, and the new spectral upgrades in 4.x produce results EEVEE‑Next still can't match for skin.
- **EEVEE‑Next** (default since 4.2, much stronger in 4.5) handles look‑dev, turntable previews, animation playblasts, and any shot where the focus is staging not skin micro‑detail. SSS is acceptable for stylized work, screen‑space everything has improved, and the new light linking + raytraced shadows close 70% of the prior gap.

**Workflow rule:** look‑dev in EEVEE‑Next at viewport 1080p, final hero stills in Cycles 4K with 1024 samples + OptiX denoise.

### D2. Lighting — "Noble Portrait" recipe

Three lights plus dim world. Targeting Lineage 2M cinematic key art mood.

| Light | Type | Position | Color (K / hex) | Energy | Notes |
|---|---|---|---|---|---|
| Key | Area 60×60 cm | Camera‑left, 35° above eye, 1.2 m from subject | 5200 K / `#FFE4C4` | 200 W | Soft skin shaping; slight warm |
| Fill | Area 100×100 cm | Camera‑right, eye level, 2.5 m | 6500 K / `#D6E4FF` | 25 W | Cool fill — pushes red shadows in skin |
| Rim | Spot, 25° cone | Behind subject, opposite of key, 30° above | 8000 K / `#A8C4FF` (cool steel) **or** 3200 K / `#FFB070` (warm candle) — pick one per shot | 600 W, narrow | Defines hair edge and pauldron silhouette |
| Practical | Small Area on the gem | Tiny, near the gem | matches gem color | 2 W | Sells the focal gem |
| World | dim HDRI | Studio HDRI at 0.05 strength, or solid color `#0A0810` | — | — | Near‑black ambient |

For the rim: cool rim plus warm key is the ceremonial recipe; warm rim plus cool key is the funereal/villainous variant.

### D3. Color management

- **View Transform:** **AgX** (default since 4.0). It is Filmic's successor with proper handling of saturated highlights (Filmic crushed reds and blues toward yellow due to the "Notorious Six" failure). For dark fantasy moodiness AgX is better — it preserves the saturation of the crimson gem and the wine cloth without desaturating the rim.
- **Look:** **AgX — Punchy** for hero stills (a touch more contrast than Medium High Contrast, and it doesn't crush blacks the way Filmic Very High did).
- **Exposure:** −0.3 to −0.7 EV for a darker overall key.
- **Gamma:** 1.0 (do not lift via gamma; lift via compositor curves if needed).
- For HDR delivery, AgX now has Rec.2100‑PQ and HLG variants (added in 4.x).

### D4. Compositing pass

Minimum compositor stack:

```
Render Layers
  → Glare (Bloom: Threshold 1.0, Size 7, Mix 0.0)        # only blooms emissions; gem and rim glints
  → Lens Distortion (Distortion 0.0, Dispersion 0.015)    # acts as chromatic aberration
  → Mix RGB (Multiply, vignette mask)                     # hand‑drawn elliptical mask, soft falloff
  → Color Balance (Lift slightly cool #E0E8FF, Gamma 1.0, Gain slight warm #FFF4E0)
  → File Output
```

In Blender 5.0 the new **Chromatic Aberration node** is a cleaner replacement for the Lens Distortion dispersion trick — use it directly with Amount 0.6, Type Spectral.

For "filmic dark fantasy" finishing, also add a faint film‑grain Noise (scale 1.0 in screen space, multiply 0.03) and a square LUT pass with subtle teal‑and‑gold split toning.

---

## Part E — Rigging

### E1. Rig generator choice in 2026

| Tool | Cost | Strengths | Weaknesses | Verdict |
|---|---|---|---|---|
| **Rigify** | Free (built‑in) | Maximum control; metarig system extensible to non‑humanoids; bulletproof IK/FK switching; large community | Steeper learning curve, no game‑export niceties | Best for hero/cinematic where you'll author custom controls (cape pulls, garment offsets) |
| **Auto‑Rig Pro** | Paid (Lucky3D) | Friendliest UX; best face rig out‑of‑the‑box; one‑click game export to UE5/Unity with humanoid mapping; retargeting from Mixamo/MoCap | Less flexible for non‑bipeds | Best for production/game pipeline |
| **AccuRIG** (Reallusion) | Free, standalone | Fastest auto‑rig (literally seconds); great for marketplace meshes in any pose | Requires internet for export; weaker on unusual silhouettes; no native Blender integration — round‑trip via FBX | Best for quick previs |

**Recommendation for Nocturne Matriarch:** Rigify for the body, with custom face controls (a manually‑driven shape‑key panel rather than Rigify's bone face — better for "noble" expressions which are subtle).

### E2. Cape and skirt physics

Two viable approaches and you usually combine them:

1. **Cloth simulation (Cycles‑final, baked once).** Use Blender's built‑in cloth modifier on the cape mesh. Settings for heavy ceremonial fabric: Mass 0.6 kg, Tension 25, Compression 25, Shear 15, Bending 5 (high — keeps stiff folds), Air Damping 1.2. Pin the cape to the shoulder armor with a vertex group, set collision against a low‑poly body proxy. Bake.
2. **Bone chain + driven physics (animation/realtime).** For the skirt panels build a bone chain per panel (5–7 bones), parent to hip bone, then apply either:
   - **Goo Physics** (paid, Superhive) — purpose‑built for cape/skirt secondary motion, great stylized feel.
   - **Bone Dynamics Pro** — alternative with similar feature set.
   - **Free DIY:** drive bone rotations from a low‑poly cloth mesh using Mesh Deform or a hook + spring constraint chain.

For the cape specifically, the "low‑poly cloth as target" trick (a 6×8 vertex grid simmed with cloth, then bones constrained to its vertices) gives you cinematic movement at game‑rig cost.

---

## Recommended recipe stack — Nocturne Matriarch

| Element | Decision |
|---|---|
| Sculpt path | Voxel Remesh blockout → retopo (35 k tris) → Multires (4 levels) → ZBrush bridge optional via FBX for finest skin pores; final bake to 4K normal |
| Face proportions | 7.75 heads tall, raised cheekbone (0.40 ratio), heart jaw, neck length 1.25× head, lifted outer canthus +4° |
| Costume order | Bodysuit → corset cuirass (Booleans + Bevel) → 6 skirt panels → vambraces (Sub‑D) → pauldrons (sculpt + retopo, demonic horn flourish) → gorget → high collar → crown → black velvet cape |
| Filigree | Curve‑bevel scrollwork on cuirass front; decal sheet for greaves and collar repeats; tarnished gold material |
| Hair (hero stills) | Curves‑based Hair object, ~120 k strands, bone‑white gradient (#2A2222 root → #F0EBE0 tip), Principled Hair BSDF Direct Coloring |
| Hair (animation) | Hair Tool 4 cards baked from same guides, Principled BSDF + anisotropy, jiggle bones |
| Skin | Principled BSDF v2, Random Walk Skin SSS, base #E8D2C0, radius (1.0, 0.35, 0.18), Scale 0.012, Sheen 0.15 peach‑fuzz, Coat 0.05 |
| Armor metal | Blackened steel #1A1614 with edge‑wear reveal #5A4F47, AO cavity grime, Roughness 0.28–0.42, Metallic 1.0 |
| Filigree metal | Tarnished gold #9A7A28 with cavity gradient to #3A2E10, faint #3F4F36 patina at deepest AO, slight anisotropy 0.3 |
| Cloth (gown) | Wine cloth #1F0408 with #6A0F1A microfiber Sheen 0.85, fabric weave normal |
| Cloth (cape) | Black velvet #080406, cool Sheen tint #3A2A2E, Sheen 1.0 |
| Focus gem | Crimson ruby — Glass BSDF #FF1424, IOR 1.77, Cycles dispersion Abbe 18, interior emission mesh #C8000E strength 8 |
| Render | Cycles 1024 samples + OptiX denoise for hero stills; EEVEE‑Next look‑dev |
| Lighting | Soft warm key 5200 K camera‑left‑above, cool fill 6500 K opposite, cool steel rim 8000 K behind |
| Color management | AgX Punchy view transform, Exposure −0.4, near‑black world |
| Composite | Subtle bloom on emissions only, Lens Distortion dispersion 0.015, elliptical vignette, faint film grain 0.03 |
| Rig | Rigify body + custom shape‑key face panel; cape via baked Cycles cloth sim; skirt via bone chain + Goo Physics |

---

## Sources

- [Blender Manual — Principled BSDF](https://docs.blender.org/manual/en/4.0/render/shader_nodes/shader/principled.html)
- [Blender Manual — Subsurface Scattering](https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/sss.html)
- [Blender Manual — Sheen BSDF](https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/sheen.html)
- [Blender Manual — Principled Hair BSDF](https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/hair_principled.html)
- [Blender Manual — Ambient Occlusion Node](https://docs.blender.org/manual/en/latest/render/shader_nodes/input/ao.html)
- [Blender Manual — Generate Hair Curves](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/hair/generation/generate_hair_curves.html)
- [Blender Manual — Adaptive Resolution sculpting](https://docs.blender.org/manual/en/latest/sculpt_paint/sculpting/introduction/adaptive.html)
- [Blender 4.0 Release Notes — Shading & Texturing](https://developer.blender.org/docs/release_notes/4.0/shading/)
- [Blender 4.0 Release Notes — Color Management (AgX)](https://developer.blender.org/docs/release_notes/4.0/color_management/)
- [Blender 5.0 Release Notes — Compositor (Chromatic Aberration node)](https://developer.blender.org/docs/release_notes/5.0/compositor/)
- [Blender Devtalk — Principled v2 feedback thread](https://devtalk.blender.org/t/principled-v2-feedback-discussion-thread/24997)
- [Blender Devtalk — Procedural Hair Nodes asset library](https://devtalk.blender.org/t/procedural-hair-nodes-nodegroup-assets-for-blender-3-5/27601)
- [Blender Devtalk — Charlie Sheen cloth shading formula](https://devtalk.blender.org/t/charlie-sheen-cloth-shading-formula/23264)
- [Blender Devtalk — Pointiness algorithm explained](https://devtalk.blender.org/t/understanding-the-pointiness-algorithm/13093)
- [Blender Projects — Velvet → Sheen BSDF Microfiber update](https://projects.blender.org/blender/blender/pulls/108869)
- [Blender Projects — Replace default OCIO with AgX](https://projects.blender.org/blender/blender/pulls/106355)
- [Blender Projects — Coat Tint and IOR for Principled BSDF](https://projects.blender.org/blender/blender/pulls/110993)
- [Blender Artists — Subsurface/Principled changes in 4.0](https://blenderartists.org/t/what-are-the-changes-related-to-subsurface-or-principled-bsdf-in-blender-4-0/1510753)
- [Blender Artists — Worn / scratched edges on metal](https://blenderartists.org/t/worn-scratched-edges-on-metal-what-is-the-best-method/1531106)
- [Blender Artists — Velvet shader using new Principled branch](https://blenderartists.org/t/velvet-shader-using-new-principled-bsdf-branch/1414294)
- [Blender Artists — Hair sculpt deform on new hair tools](https://blenderartists.org/t/blender-4-1-0-manual-scultp-deform-on-the-new-hair-tools-from-the-asset-library/1512516)
- [Blender Artists — Low poly cloth simulation as bone target](https://blenderartists.org/t/low-poly-cloth-simulation-as-target-for-bones/1576584)
- [ArtStation — jsabbott "Procedural edge wear in Blender 4.2"](https://www.artstation.com/blogs/jsabbott/rD6Ql/how-to-make-procedural-edge-wear-in-blender-42-tutorial)
- [ArtStation — Fantasy Female Warrior breakdown (Eddie Wibowo)](https://www.artstation.com/artwork/m8K3a9)
- [80.lv — Female Character Production Guide](https://80.lv/articles/female-character-production-guide)
- [80.lv — Creating Fantasy Character in Blender, ZBrush & Substance 3D Painter](https://80.lv/articles/creating-fantasy-character-in-blender-zbrush-substance-3d-painter)
- [80.lv — Stylized Simulations / Goo Physics add‑on](https://80.lv/articles/create-stylized-simulations-with-this-custom-physics-blender-add-on)
- [FlippedNormals — Female Game Character Creation in Blender](https://flippednormals.com/product/female-game-character-creation-in-blender-15778)
- [FlippedNormals — Realistic Character Making in Blender](https://flippednormals.com/product/realistic-character-making-in-blender-20624)
- [FlippedNormals Blog — Rise of the Character Artist (Sculpting FlipBox)](https://blog.flippednormals.com/rise-of-the-character-artist-blender-sculpting-flipbox/)
- [FlippedNormals Blog — How to Shade and Light a 3D Character in Blender](https://blog.flippednormals.com/how-to-shade-and-light-a-3d-character-in-blender/)
- [Yansculpts — Sculpting Stylized Character Busts](https://yansculpts.gumroad.com/l/stylizedbusts)
- [Hair Tool 4 documentation (joseconseco / Bartosz Styperek)](https://joseconseco.github.io/HairTool_3_Documentation/)
- [Hair Tool — Texture Baking docs](https://joseconseco.github.io/HairTool_3_Documentation/texture_baking/)
- [Hair Tool on Gumroad](https://bartoszstyperek.gumroad.com/l/hairtool)
- [Yelzkizi — Hair Cards In Blender game‑ready workflow](https://yelzkizi.org/create-hair-cards-in-blender/)
- [Yelzkizi — Realistic 3D Hair with Hair Curves & Geometry Nodes](https://yelzkizi.org/realistic-hair-new-hair-geometry-nodes-hair-curves/)
- [CG Cookie — Subsurface Scattering and Color in 4.2](https://cgcookie.com/community/19159-subsurface-scattering-and-color-in-4-2)
- [CG Cookie — Cycles vs Eevee 15 limitations](https://cgcookie.com/posts/blender-cycles-vs-eevee-15-limitations-of-real-time-rendering)
- [CG Cookie — AgX Raw Workflow for vibrant colors](https://cgcookie.com/posts/the-secret-to-rendering-vibrant-colors-with-agx-in-blender-is-the-raw-workflow)
- [CGDive — Rigify vs Auto‑Rig Pro comparison](https://cgdive.com/rigify-vs-auto-rig-pro-auto-rigging-comparison/)
- [Whizzy Studios — Best Rigging Add‑ons for Blender 2025](https://www.whizzystudios.com/post/best-rigging-add-ons-for-blender-in-2025-beyond-rigify-and-auto-rig-pro)
- [Tripo3D — Best Auto Rig Character Tools 2025](https://www.tripo3d.ai/content/en/use-case/the-best-auto-rig-character)
- [iRendering — Blender 4.2 Eevee Next vs Cycles](https://irendering.net/blender-4-2s-eevee-next-and-cycles-comparison/)
- [RadarRender — Eevee vs Cycles in 2025](https://radarrender.com/blender-eevee-vs-cycles-which-is-better-for-your-workflow-in-2025/)
- [BlenderNation — Gemstone Shader Breakdown](https://www.blendernation.com/2017/03/25/gemstone-shader-breakdown/)
- [BlenderNation — New Ornament Technique in Blender 2.91 (Custom Curve Bevel)](https://www.blendernation.com/2020/12/12/new-ornament-technique-in-blender-2-91/)
- [DECALmachine documentation](https://machin3.io/DECALmachine/docs/)
- [Trimflow on Superhive](https://superhivemarket.com/products/trimflow)
- [Hard Ops + Boxcutter Ultimate Bundle (masterxeon1001)](https://masterxeon1001.gumroad.com/l/hopscutter)
- [Pixcores — Free Box Cutter alternatives](https://www.pixcores.com/2022/09/free-box-cutter-alternatives-for-blender)
- [Polycount — What's the best way to make filigree and ornamental 3D objects](https://polycount.com/discussion/167070/whats-the-best-way-to-to-make-filigree-and-ornamental-3d-objects)
- [Sofia Pahaoja — Remesh + Multires workflow in Blender](https://medium.com/@skarkkai/remesh-multires-workflow-in-blender-2ae97ae5176d)
- [Packt — Sculpting the Blender Way (Voxel Remesh + Multires chapter)](https://subscription.packtpub.com/book/game-development/9781801073875/2/ch02lvl1sec19/exploring-the-most-powerful-sculpting-mode-multiresolution)
- [StraySpark — Procedural Weathering with Geometry Nodes](https://www.strayspark.studio/blog/procedural-weathering-blender-geometry-nodes)
- [StraySpark — Baking Curvature Maps in Blender](https://www.strayspark.studio/blog/curvature-maps-blender-substance-painter-alternative)
- [Brandon3D — Three Point Lighting in Blender](https://brandon3d.com/three-point-lighting-in-blender-3d/)
- [Brandon3D — Principled BSDF Shader Guide](https://brandon3d.com/blender-principled-bsdf-shader-guide/)
- [Ben Simonds — Lighting tips from the Masters](https://bensimonds.com/2010/06/03/lighting-tips-from-the-masters/)
- [PencilKings — Female Face Proportions Explained](https://www.pencilkings.com/female-face-proportions/)
- [21‑draw — Seven Face Proportions for drawing a perfect face](https://www.21-draw.com/face-proportions/)
- [Lineage 2 NCSoft Digital Artbook](https://about.ncsoft.com/artbook/en/lineage2/)
- [GameRant — 6 Things Throne and Liberty shares with Lineage](https://gamerant.com/throne-liberty-similarities-lineage-2/)
- [MMORPG.com — Throne and Liberty Review (Lineage successor)](https://www.mmorpg.com/reviews/throne-and-liberty-review-very-much-a-lineage-successor-2000133041)
- [CG Channel — Blender 5.0 release coverage](https://www.cgchannel.com/2025/11/blender-5-0-is-out-check-out-its-5-key-features/)
- [Creative Shrimp — Blender 3.5+ Realtime Compositor tips](https://www.creativeshrimp.com/blender-3-5-realtime-compositor.html)
- [BlenderKit — Edge Wear by Sebastian Villanueva](https://www.blenderkit.com/asset-gallery-detail/2885308a-1173-4b4e-993c-8f3570cd25b4/)
- [BlenderKit — Crimson Ruby material](https://www.blenderkit.com/asset-gallery-detail/b83a6765-0b74-45cc-bbae-2964028ff853/)
- [Superhive — Physically‑correct gems and precious stones shaders](https://superhivemarket.com/products/physically-correct-gems-and-precious-stones-shaders)
- [Superhive — Goo Physics](https://superhivemarket.com/products/goo-physics)
- [Bone Dynamics Pro — YouTube intro](https://www.youtube.com/watch?v=S-EJav3gc7c)
- [Egneva — Sheen Properties in Principled BSDF](https://egneva.com/sheen-properties-in-principled-bsdf-node-blender-advanced-training/)
- [Toodee — Setup Blender Filmic & AgX for HDR](https://www.toodee.de/exploring-hdr-displays/blender-and-agx/)
- [Blendergrid — Understanding Color Management in Blender](https://blendergrid.com/articles/color-management-in-blender)
