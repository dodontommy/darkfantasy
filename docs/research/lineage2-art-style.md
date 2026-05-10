# Lineage 2 Character Art & Technical Fidelity — Reference for the Nocturne Matriarch

Scope: a working reference for an original dark-fantasy female character ("Nocturne Matriarch") modeled in Blender, *inspired* by Lineage 2 (NCSoft, 2003–present) but legally distinct. Covers the aesthetic language and the technical fidelity bar across L2's eras, with explicit translation into modeling decisions at the end.

Currency: written May 2026. Includes Aden 2024–2025 updates and Throne and Liberty (2024 global launch) as the modern fidelity reference.

---

## 1. Eras of Lineage 2 Character Art

L2 is unusual in that the *same shipping client* has been continuously patched for 22 years on top of an Unreal Engine 2.5 base, while parallel reboots (L2M, Throne and Liberty) iterate on UE4. The visual bar is therefore not one number; it is a stack of layers. Pick the layer you want to match.

### 1.1 Prelude / Chronicles 1–5 (2003 KR launch → 2006)
- Engine: Unreal Engine 2.5. Vertex lighting, no normal maps in the early builds, mostly diffuse-only textures. Outdoor terrain rendering was a deliberate engine selection by lead designer Raoul Kim.
- Character density (estimated from datamined PSK files via Gildor's UE Viewer): **~2k–4k triangles per body**, plus low-poly armor sub-meshes layered on top. Heads were ~800–1,500 tris.
- Texture budget: **256² for body parts, 512² for armor sets, 128² for accessories.** No normal/spec; everything baked into diffuse with painted highlights.
- Faces: a fixed library of 4 face presets per race per gender, with no morph targets. Eye geometry is flat, eyebrows are texture-painted. Mouths do not animate beyond a closed/open visemic toggle.
- Hair: pure planar cards with alpha-cutout. 6–10 cards per long hairstyle. No physics; hair is rigidly skinned to head/spine bones with one or two cape-style helper bones.

### 1.2 Chaotic Throne / Interlude / Gracia / High Five (2006–2011)
- Same UE2.5 engine, but content shipped now uses a basic normal-map path on armor and weapons. Skin still mostly diffuse.
- Armor sub-meshes climb to **~6k–10k tris** for top-tier sets (Vesper, Vorpal, Elegia). Texture per armor region moved to **512²/1024²**, with separate normal maps for the high-grade sets.
- This is the era that produced most of the *iconic* armor language people associate with L2: Draconic Leather, Major Arcana robe, Dark Crystal robe, Tallum, Dynasty, Vesper, Vorpal, Elegia. The shape language stabilized here.
- Kamael race added (2007); first race modeled with a slightly different skeleton (one wing-like back attachment, slimmer build).

### 1.3 Goddess of Destruction (2011) — the "remodel" reboot
- Same engine, but NCSoft re-authored the playable character base meshes, added a new character creation system, restyled hairstyles (hair now uses denser card stacks and ornamentation slots), and rebalanced proportions toward longer legs and a smaller head.
- Female body: head-to-body ratio shifted from roughly **7.0** to roughly **7.5–8.0 heads** depending on race; Dark Elves and Elves are tallest. This is where the now-recognizable "L2 silhouette" — a small head, very long lower body, narrow waist, severe shoulder line — was locked in.
- Texture budgets bumped to **1024²–2048²** for the new top-tier armor (R-grade and beyond — Magmeld, R85/R87/R95/R99 sets introduced here). Specular maps standard, but workflow is still **specular-gloss, not metallic-roughness**. No PBR.
- Faces: more presets, slight shape variation, but no FACS-style blendshapes. Cinematics use bespoke meshes.
- Free-to-play transition (Nov 2011) coincided.

**This is the era to match if you want "high-fidelity classic L2."** Goddess of Destruction onward is what most reference imagery (DeviantArt, ArtStation Bruno Sidarta Vesper Noble piece, official key art) actually depicts.

### 1.4 Aden / 2024–2026 modern client
- Still UE2.5 underneath. NCSoft has not migrated the PC client; instead, they patch in re-textured assets, raise lighting quality, and add gear with updated normal/spec authoring.
- The Feb 2024 "Character Enhance Package" and the 2024 20th-anniversary High Elves rework added selectively higher-density armor models in the **15k–25k tri** range with **2K** textures. The Dec 2024 Dawn of the Guardian and the August 2025 Rose Vain Dark Elf dagger class continued this re-skin trend.
- L2 Aden in 2026 looks like a 2010 game with selectively 2018-quality re-skins on high-end gear. Useful as *silhouette* reference, not as *render-target* reference.

### 1.5 Lineage 2M (mobile, KR 2019, global 2021) — Unreal Engine 4
- Full UE4 rewrite. Fully PBR (metallic-roughness). 4K UHD output target on mobile/PC. Reviews consistently call out "thoroughly drawn armour patterns and detailed character expressions."
- Estimated character budget (community datamining via UModel UE4 fork): **30k–50k tris for body+head, plus 20k–30k for high-tier armor sets.** Texture sets at **2K base + 1K accessories**, with packed roughness/metallic/AO ORM textures.
- Hair is still card-based but with substantially more cards (30–80 per hairstyle), ornamentation slots, and bone-driven secondary motion.
- L2M is the most useful **fidelity** match for a Blender hero asset rendered in EEVEE Next or Cycles.

### 1.6 Throne and Liberty (NCSoft, KR 2023, global Oct 2024) — adjacent reference
- Originally announced as Lineage Eternal in 2011, rebranded as Project TL (2017) then Throne and Liberty (2022). Spiritually adjacent to L2 but legally separate IP.
- Engine: **Unreal Engine 4** (4.27-class), not UE5 despite community speculation. Cross-platform PC / PS5 / Xbox Series.
- Character creation includes photo-to-character AI workflow (humans only). Per-feature sliders for eye spacing, jaw protrusion, cheekbone, etc. Character creation is widely considered best-in-class for the genre.
- Estimated body budget: **60k–90k tris hero**, **2K–4K** PBR texture sets, ~150–220 bone rigs with face rig (~50–80 face bones, roughly FACS-equivalent through bones not blendshapes).
- T&L is the cleanest **modern** reference for "what L2's design language looks like at 2024 fidelity." Match this if you want the asset to feel current.

---

## 2. Race-by-Race Silhouette and Costume Language

| Race | Key visual traits | Costume language |
|---|---|---|
| Human | 7.0–7.5 heads. Average build, moderate ornament, warmest skin. Most "neutral" of the races. | Mixed European medieval and late-Gothic plate. Heraldic colors. Reds, blues, gold trim. |
| Light Elf | 7.5–8.0 heads. Pale-warm skin, blonde/silver hair, tall pointed ears. Slight build, narrow shoulders. | Nature-aligned: leaf and feather motifs, soft greens, ivory whites, organic silhouette filigree. Skirts and high collars. |
| **Dark Elf** | 7.5–8.0 heads. Blue-gray to slate-purple skin, silver/white or near-black hair, sharper facial features than Light Elves, often heavy eye-makeup look. Followers of Shilen, goddess of Death. | Severe, "edgy": black leather and dark steel, exposed midriffs/legs on females, bone and chitin motifs, deep purples and crimson accents, spike forms. Highest revealing-skin index of all races. |
| Orc | 6.5–7.0 heads (broader). Green-brown skin, tusks, bulky shoulders. | Tribal: leather strapping, fetish bones, fur collars, fire-themed metals. Less filigree. |
| Dwarf | 4.5–5.0 heads, comically squat. | Mechanical/industrial. Gold-plated, riveted plate. Often comic-relief proportions. |
| Kamael | 7.5 heads, slim. Single mechanical/ethereal wing on the back. Pale skin, often white/silver hair. | Battle-themed: angular plate, broken-symmetry shoulders to accommodate the wing, blue/black palette with white edges. |
| Ertheia | 6.5 heads. Childlike, fae proportions. Pastel hair colors. Added in Aden expansion. | Light, gauzy, mystical robes; cosmic motifs. |

For the Nocturne Matriarch the canonical reference set is **Dark Elf female noble caster** (Vesper Noble robe, Major Arcana robe, Apocalypse robe) — possibly cross-referenced with **High-tier Light Elf female** (Elegia, Eternal) for the cleaner filigree.

---

## 3. Iconic Armor Sets — Shape Language to Study (and not Copy)

L2's high-grade armor sets are the visual backbone of the franchise. Common shape grammar across **Draconic Leather, Dynasty, Vesper, Vorpal, Elegia, Eternal, Apocalypse, Dark Crystal, Tallum, Major Arcana**:

- **Pauldrons.** Asymmetric or oversized; one shoulder is often more pronounced than the other. Common forms: dragon-jaw maw biting outward; layered fan-blade plates; upturned spike crowns; folded "lily petal" steel. Pauldron extends well past the natural shoulder line, exaggerating the silhouette by 20–40%.
- **Gorget / collar.** Almost always a high standing collar — either an upright raven-wing flare (caster sets) or a ribbed metal cone (heavy sets). Faces are framed by collar, not by hood. Hoods are rare; tiaras and circlets are common.
- **Cape / skirt.** Long, vented, asymmetric skirts that split front-or-side to expose leg armor or stocking. Capes are heavy and trail; back ornament is a major silhouette decision (wing-shapes, arched horn frames, draped cowl).
- **Gem placement.** Single large center-chest gem (sternum), repeated as a smaller gem at belt buckle, again at gorget. Triangle compositions. Gems emit subtle bloom; never glow violently except on weapons.
- **Filigree density.** Dense at chest, gorget, and wrist; sparse at midriff and thigh. Negative space is an explicit design tool — Dark Elf casters in particular use a bare midriff or sheer panel to break up otherwise heavy plate.
- **Color logic per tier.** Lower tiers are darker and matte; mid tiers introduce gold/silver edge plating; top tiers (Eternal, Apocalypse) introduce one chromatic accent (cyan, violet, blood-red) on gem and trim only — never on the field metal.
- **Asymmetry.** Most top sets break symmetry: one cuff longer than the other, one pauldron larger, one leg with greave, one without. Useful for silhouette legibility at distance.

For the Matriarch, study Vesper Noble robe and Apocalypse robe specifically — both are caster-tier Dark Elf-friendly female sets that sit closest to the brief.

---

## 4. Female Character Proportions in L2

- Head-to-body ratio: **7.5–8.0 heads** for Elves and Dark Elves post-Goddess of Destruction.
- Leg length: roughly **55% of total height** (vs. realistic 47–50%). The exaggerated leg is signature.
- Waist: **0.55–0.60** of shoulder width. Shoulders are deliberately narrow to make the head read large enough at MMO viewing distance, and to make pauldrons read bigger.
- Hip-to-shoulder: **roughly 1:1** or slight hourglass — narrower hips than Western fantasy norms (which tend toward 1.1 hips:shoulders). The L2 silhouette is closer to a long inverted exclamation mark than to an hourglass.
- Bust: medium (cup C-equivalent). Not the hyper-emphasized chest of TERA or Blade & Soul. NCSoft's L2 design language is explicitly more austere than its sibling studios.
- Hand and foot size: small, almost mannequin-like. Boots and gauntlets visually inflate them.
- Neck: long. Crucial for the high-collar silhouette to land.
- Face: high cheekbones, narrow jaw, pointed chin, large eyes (slightly oversized for realism, well within human range — not anime). Lips small. Brows often arched.

This is a Korean MMO informed by Western fantasy but absorbed through manhwa proportions: **taller and slimmer than Western realism, but less stylized than anime or TERA.** Anchors in the Hyung-Tae Kim school of Korean concept art (Kim worked at NCSoft on Blade & Soul / Magna Carta; he is *not* the L2 lead — Juno Jeong is — but the school is the same): emphasis on flow, on fat distribution as the source of femininity, and on staying "just inside" the boundary of the human-readable.

---

## 5. Materials — How L2 Handles Surfaces

L2 is **not natively PBR** on the original PC client. It uses a diffuse + normal + specular-gloss workflow with hand-painted highlights baked into albedo. L2M and Throne and Liberty are full PBR (metallic-roughness, ORM packing).

For a 2026 Blender asset you should author **PBR metallic-roughness** to L2M / T&L specs, but stylize the diffuse with a hint of painted highlights to read as "L2" rather than as photoreal. Concrete material targets:

- **Dark steel.** Base color ~#1a1a1f to #232633, near-black with a faint cool tint. Roughness ~0.45–0.6. Metallic 1.0. Avoid mirror finish; L2 metals are matted, with subtle anisotropy from brushed-metal normal patterns. Edge wear is *painted on* in the trim, not generated procedurally.
- **Gold trim.** Base color ~#c79a3a–#d4ae53. Roughness ~0.25 for crowns and gem settings, 0.4 for engraved trim. Slightly desaturated vs. real gold. Used sparingly — never more than ~8% of surface area.
- **Gem emission.** Strong diffuse color (ruby red, sapphire blue, amethyst violet), low emission strength (0.3–0.8 in Blender Cycles units), with a screen-space bloom in post. Gems should never bloom out; they should *suggest* light.
- **Cloth (caster robes, skirt, cape).** Roughness 0.7–0.85, slight sheen layer (Blender Principled BSDF "Sheen" 0.2, sheen tint warm). Velvets and silks dominate. Embroidered trim should be a separate floating mesh, not a normal-map fake.
- **Leather.** Roughness 0.55–0.7. Medium dark. Visible stitch lines, painted not normal-mapped, ~2 mm scale at body-readable distance.
- **Fur.** Used sparingly on collars and cape lining. L2 typically uses geometry tufts (low cards) plus a fur-strip alpha texture, not Blender hair particles. For a hero Blender asset, hair grooming is acceptable.
- **Skin.** Subsurface scattering with cool radius (red/pink, ~0.6 radius in Blender units), but kept low — Dark Elves in particular have nearly translucent-stone skin readability. Roughness ~0.45. No oily forehead highlight; L2 skin is matte-ceramic.

---

## 6. Hair

- Modeling: **planar cards with alpha cutout** is canonical across all L2 eras. L2M raises card density substantially.
- Length: hero female hair is typically **mid-back to lower-back length**, often with one or two strand groups falling forward across one shoulder. Pinned-up styles exist but are minority on caster classes.
- Mass: heavy; hair often has more silhouette mass than the head itself. This is intentional and contributes to the "elegant noble" read.
- Ornament: hair accessories are a defined slot in L2 (Eva's Hair Accessories item line introduced extensive options: hairpins, horns, ears, chaplets, antlers, ribbons). For Dark Elf nobles: silver tiara, twin curved horns, raven-feather pins, chained circlets.
- Motion: bone-driven secondary motion via 2–4 helper bones per major strand group. No native cloth simulation in original client; L2M uses bone chains animated by physics constraints.
- Color: silver, white, near-black, deep violet, and rare deep blood-red are the canonical Dark Elf palette. Avoid bright fantasy primaries.

For Blender hero work: do hair grooming with curve hair for renders, but build a card-based fallback if any game-engine deployment is downstream.

---

## 7. Faces

- Korean MMO face style. **Larger eyes than realism** (about 1.3× the realistic eye-to-face ratio), but not anime-sized. Iris is large and saturated; sclera is small visible area.
- High cheekbones, **prominent zygomatic ridge**, narrow lower jaw, pointed chin. Mid-face is short relative to lower face — the philtrum and lip-to-chin distance is reduced.
- Brow ridge minimal, brows themselves high and arched (signature for Dark Elf females).
- Nose is small, narrow bridge, slightly upturned tip. Western "strong nose" reads wrong for the language.
- Mouth small, full lower lip, painted dark or matte for Dark Elves.
- Ears for elves: **15–20 cm pointed**, swept back at ~25° from horizontal.
- Skin shader as in §5; for ceremonial poses, add subtle metallic temple or cheek paint as a separate decal mesh.

L2's original face system has no real blendshapes. For modern Blender authoring, you should still build **20–40 facial blendshapes** (ARKit-equivalent core set) so the asset is animation-ready.

---

## 8. Technical Fidelity Benchmarks

Approximate, drawn from datamining via Gildor's UE Viewer/UModel community and from comparable AAA MMO targets cited by polycount.com discussions.

| Era | Body tris | Head tris | Top armor tris | Texture per region | Bones | Face blendshapes |
|---|---|---|---|---|---|---|
| L2 Prelude (2003) | 2k–4k | 0.8k–1.5k | 2k–4k | 256²/512² diffuse only | ~50 | 0 |
| L2 Goddess of Destruction (2011) | 6k–10k | 2k–3k | 6k–12k | 1024² + normal | ~70 | 0 |
| L2 Aden modern reskins (2024–26) | 8k–15k | 3k–4k | 15k–25k | 2048² + normal/spec | ~70 | 0 |
| L2M (UE4, 2019) | 15k–25k | 4k–6k | 20k–30k | 2048² PBR ORM | ~120 | 10–20 morphs (limited) |
| Throne and Liberty (UE4, 2024) | 30k–50k | 6k–10k | 30k–50k | 2K–4K PBR ORM | ~150–220 (incl. ~50–80 face bones) | bone-rigged face, ~50–80 controls |
| **Hero Blender asset target (this project)** | **40k–70k body+head** | (combined) | **30k–60k** outfit | **4K body, 4K outfit, 2K accessories** | **~180** | **30–40 ARKit-style** |

Reference points outside L2: Civilization VI leaders ~60k tris; Nier:Automata 2B ~72k tris; Aloy in Horizon ~100k tris in-game. A Blender hero piece at ~100k–130k total tris with 4K PBR sits squarely in modern AAA hero range and comfortably above the L2M/T&L bar.

---

## 9. Posing and Silhouette Conventions

L2 official key art and class-promo art follow a tight set of posing conventions:

- **Severe contrapposto.** Hip cocked sharply to one side (15–25°), opposite shoulder dropped, head tilted slightly toward the dropped shoulder. Creates an S-curve through the body.
- **Weapon-as-anchor.** Caster classes hold staff/orb/dagger across the body diagonally, providing a strong compositional line. Weapon is often planted point-down to one side rather than held aloft.
- **Severe noble stance.** Standing portraits are often near-frontal, head turned 15° off-axis, eyes to camera. Almost no smile; jaw set, lips closed.
- **Cape behavior.** Cape is rendered mid-billow even in static art — a horizontal wind line is nearly always present. This is critical to L2's "in-motion-but-frozen" signature.
- **Hands.** One hand on weapon, the other often raised at chest height with two fingers extended (casting glyph), or resting on hip.
- **Camera framing.** Three-quarter low-angle, ~15° below eye line, lens around 50–85 mm equivalent. Subject occupies central 60% of frame; cape and hair break the rule-of-thirds.
- **Lighting.** Dramatic side or back rim light, fill from below at a cooler temperature. Background dark and atmospheric.

---

## 10. Color Palette

L2 promo art is **desaturated dark with one chromatic accent**.

- Field: blacks (#0a0a0e to #1d1f28), cool grays (#3a3e48), aged silvers (#7e828b), oxblood (#3a0c12).
- Neutral mids: warm parchment (#cbb892), tarnished bronze (#7a5e2a).
- Accent (one only per character): cold cyan (#42a8c4), violet (#5b2a8a), blood crimson (#8e1320), poison green (#3d7a2c), gold flare (#d4ae53).
- Skin (Dark Elf): cool slate (#7d8aa0 to #56627a) with violet undertone at shadows.
- Hair (Dark Elf): silver-white #d3d8df, near-black #1a1f25, deep violet #2a1738, rare bloody-red #4a1018.

The discipline is: **one accent color, used in three places forming a triangle** (e.g., gem at sternum, gem at belt, faint emission in eye highlights).

---

## 11. Where to Find Reference (Legally)

- **NCSoft official digital artbook for Lineage 2** — about.ncsoft.com/artbook/en/lineage2/. Six chapters covering character design progression, equipment showcases, and historical chronicles.
- **Creative Uncut Lineage II concept art galleries** — pages a–d. Hosts Juno Jeong / Fufuhol official concept art.
- **lineage2.fandom.com** — comprehensive race and lore wiki.
- **l2wiki.com**, **l2db.info**, **l2db.club**, **lineage.pmfun.com**, **l2gamerguide.com** — armor/item databases with rendered icons and sometimes 3D previews.
- **lineage2media.com** — fan portal with armor screenshot galleries (Magmeld, R85/87/95/99).
- **strategywiki.org/wiki/Lineage_II** — armor set listings.
- **Bruno Sidarta's ArtStation** — high-quality fan recreation of Vesper Noble Dark Elf female; useful for proportions reference.
- **Gildor's UE Viewer / UModel** — for inspecting model topology and texture authoring on extracted L2 / L2M assets. Reference only; do not redistribute extracted assets.

Do not copy meshes, textures, or trademarked names. Study silhouette language, material treatment, and proportions.

---

## 12. Differentiating L2 from Adjacent Korean Fantasy MMOs

L2 sits in an "elegant high-fantasy with Gothic-ceremonial overtones" space shared by Aion, TERA, Black Desert, and Throne and Liberty. The signature differentiators:

- **vs. TERA.** TERA is more anime, more pastel, more cute-sexy. Larger eyes, smaller noses, more chibi (Elin race especially), more saturated palette, more hair colors. L2 is more austere, less saturated, more European-Gothic. Match: think "L2 noble lady at a funeral" rather than "TERA priestess at a festival."
- **vs. Black Desert (BDO).** BDO is hyper-baroque, layered, nearly Rococo on its female noble armor. Where L2 uses one center gem and a triangle composition, BDO uses dozens of gems, layered cloth, and physically-simmed multi-layer skirts. BDO is also more photoreal in skin shading. L2 is **simpler in composition, darker in palette, more Gothic-architectural.**
- **vs. Aion.** Aion shares a similar art lineage (NCSoft sister-studio) but uses **brighter colors, white/gold for the Elyos faction, more angelic motifs**. L2 is darker even at top tiers and never goes full angelic.
- **vs. Throne and Liberty.** T&L is L2's spiritual successor in art bar but with a different core: more grounded, more "high-noble-court" than "high-magic-temple." T&L's character creator humanizes proportions back toward 7.0–7.5 heads. L2 is taller, sharper, cooler.
- **vs. Western fantasy (WoW, ESO).** L2 is taller, slimmer, more verticalized. Western fantasy MMOs push wider shoulders, more solid plate, less filigree. L2 is more **Korean-Gothic-couture**; Western fantasy is more **Anglo-Saxon-knight**.

The L2 sweet spot: dark + tall + sharp + sparing-accent + Gothic-ceremonial, with emphasis on collar/pauldron silhouette and a single chromatic gem chord.

---

## 13. Modern (2024–2026) State of L2 / L2M / NCSoft Fantasy Line

- **L2 Aden (PC):** continuous patch cycle on UE2.5. Selectively re-skinned hero gear, but the core engine is unchanged. The 20th anniversary (April 2024) brought High Elves rework, Dec 2024 added Dawn of the Guardian, August 2025 added Rose Vain Dark Elf dagger class. Visually still anchored in 2011-class fidelity with 2018-class top-end gear.
- **L2M:** active KR/JP/SEA/global, full UE4 PBR. Considered the most accurate "what would L2 look like at 2024 fidelity" reference for shipped product.
- **Throne and Liberty:** the de facto NCSoft modern fantasy benchmark, cross-platform PC/PS5/XSX, 3M players in launch week (Oct 2024), reached 300k+ Steam concurrent. UE4-based PBR with photo-to-character AI customization. Use as fidelity reference; do not use as direct visual reference (shape language differs).

NCSoft's strategic posture as of 2026: legacy L2 maintained for revenue, L2M as the mobile flagship, T&L as the global new-IP flagship. There is no announced full UE5 L2 reboot.

---

## Direct Guidance for the Nocturne Matriarch

Translating the above into 12 concrete decisions for Blender authoring:

1. **Proportions: 7.8 heads tall.** Lock the head height first; everything is measured in head-units. Legs occupy 55% of standing height. Shoulders 1.7 head-widths. Waist 0.95 head-widths. Hips 1.5 head-widths. Neck 0.4 head-heights long.
2. **Silhouette grammar.** One oversized asymmetric pauldron (right shoulder, dragon-jaw or upturned lily-petal form), opposite shoulder smaller and closer to body. Standing collar flaring 8–12 cm beyond the neck on each side. Skirt asymmetric, slit on the left to expose greaved leg; cape trailing right. Cape billow is not optional — pose her with mid-billow.
3. **Body poly budget: ~50k–70k tris for the body+head combined,** subdivision-friendly base mesh (~15k tris) plus normal-baked detail. Outfit budget: **30k–60k tris** spread across pauldrons, gorget, bodice, skirt, cape, gauntlets, boots, ornament.
4. **Texture sets:** 4K body skin (albedo + ORM + normal + thickness for SSS), 4K outfit metals/cloth, 2K hair, 2K small accessories. Use UDIMs to split the outfit logically (metals on one tile, cloth on another, leather on a third).
5. **Materials: full PBR metallic-roughness.** Dark steel (#1a1a1f base, 0.5 roughness, 1.0 metallic), gold trim (#c79a3a, 0.3 roughness), violet velvet cloth (Sheen 0.25), matte slate Dark Elf skin with cool subsurface. One chromatic accent — pick **violet** for the Matriarch — applied at sternum gem, belt buckle, eye iris faint emission. No other accent color anywhere.
6. **Skin tone:** cool slate with violet undertone (#6e7a92 base, deeper #485472 in shadow). SSS radius small (0.4–0.6 in Blender units), cool tint.
7. **Face:** ARKit-style 30–40 blendshape rig. Eyes 1.3× realistic ratio. Pointed elf ears at ~17 cm, swept ~25° back. High cheekbone, narrow chin, small mouth with dark matte lip. Arched brows. Add subtle violet temple paint as a decal.
8. **Hair:** waist-length, primarily silver-white (#d3d8df) with deep violet underlayer revealed in motion. Use Blender curve hair for grooming. Mass should silhouette larger than the head. One forward strand group across the right shoulder. Build 3–4 helper bones per major strand for animation.
9. **Hair ornament:** silver tiara forward of the hairline, twin curved horns or raven-feather pins at the temples, optional chained circlet trailing to the nape. Treat ornament as separate floating geometry, not normal-mapped trim.
10. **Rig:** ~180 bones total. ~60 body, ~30 face (or 40 blendshapes alternative), ~40 distributed across cape (8), skirt (12), hair (12), pauldron secondaries (8). Single-skeleton, no hand-IK shortcuts — full FK/IK switchable arms and legs.
11. **Pose for hero render:** severe contrapposto, hip cocked 20° to her right, opposite shoulder dropped, head tilted 8° toward the dropped shoulder, weapon (a dark-metal staff or curved dagger) held diagonally across the body with the point planted to her left, free hand at chest height with two fingers extended in a glyph gesture. Camera at ~15° below eye line, 70 mm equivalent, three-quarter front.
12. **Lighting and color discipline:** key light cool blue-violet from above-left at 40° elevation, rim light warm gold from behind-right, fill from below at deep cyan. Background black-to-deep-violet gradient, no environment detail. Final palette: 70% cool darks, 20% warm metals, 8% violet accent, 2% skin highlight. *Never let the violet accent exceed 8% of the frame.*

These twelve constraints, held together, will produce a character that reads unambiguously as **L2-language Dark Elf female noble caster** without copying any specific NCSoft asset.

---

## Sources

- [Lineage II — Wikipedia](https://en.wikipedia.org/wiki/Lineage_II)
- [Throne and Liberty — Wikipedia](https://en.wikipedia.org/wiki/Throne_and_Liberty)
- [Lineage II 20th Anniversary plans — Massively Overpowered (April 2024)](https://massivelyop.com/2024/04/21/lineage-ii-outlines-its-20th-anniversary-plans-for-all-of-its-versions/)
- [Lineage II Summer Update (Rose Vain Dark Elf class) — MMOBomb](https://www.mmobomb.com/news/lineage-ii-summer-update-brings-new-classes-bosses-customization-across-all-versions)
- [Lineage II December 2024 updates — Massively Overpowered](https://massivelyop.com/2024/12/05/lineage-ii-releases-new-individual-updates-and-a-snowman-hunt-event-for-all-three-versions/)
- [Lineage II Aden Character Enhance Package — official](https://www.lineage2.com/en-us/news/lineage-ii-aden-character-enhance-package-february-2024)
- [Lineage II Digital Artbook — NCSoft](https://about.ncsoft.com/artbook/en/lineage2/)
- [The Art of TL — NCSoft](https://about.ncsoft.com/en/news/article/the-art-of-tl/)
- [Throne and Liberty Review: Very Much A Lineage Successor — MMORPG.com](https://www.mmorpg.com/reviews/throne-and-liberty-review-very-much-a-lineage-successor-2000133041)
- [Throne and Liberty Doesn't Entirely Abandon NCSoft's Lineage — GameSpace](https://gamespace.com/all-articles/news/throne-and-liberty-doesnt-entirely-abandon-ncsofts-lineage/)
- [NCSoft is reimagining Lineage Eternal as Throne and Liberty — Massively Overpowered](https://massivelyop.com/2022/03/17/ncsoft-is-reimagining-lineage-eternal-as-throne-and-liberty-with-a-new-ip-and-look/)
- [Throne and Liberty Character Creation guide](https://throneandliberty.online/throne-and-liberty-character-creation/)
- [Lineage 2M Comprehensive Review — L2-Top](https://l2-top.wordpress.com/2024/05/30/lineage-2m-a-comprehensive-game-review/)
- [Lineage 2M release / device requirements — GINX TV](https://www.ginx.tv/en/mobile-games/lineage-2m-release-date-and-time-device-requirements-features-and-more)
- [UE4 Lineage 2M discussion — Gildor's Forums](https://www.gildor.org/smf/index.php?topic=6898.0)
- [Lineage II: Remastered (UE4 fan project) — MMO Culture](https://mmoculture.com/2019/11/lineage-ii-remastered-work-begins-on-unreal-engine-4-renewal-project/)
- [Lineage 2 Remastered UE4 Upgrade — WCCFTech](https://wccftech.com/lineage-2-remastered-being-worked-on-at-ncsoft-as-an-unreal-engine-4-upgrade/)
- [UE Viewer (UModel) for Lineage 2 — l2crypt.com](https://l2crypt.com/l2-tools/ue-viewer/)
- [Gildor PSK/PSA importer & UModel — gildor2/UEViewer](https://github.com/gildor2/UEViewer/blob/master/readme.txt)
- [Races (Lineage 2 Wiki) — Fandom](https://lineage2.fandom.com/wiki/Races)
- [Dark Elf (Lineage 2 Wiki) — Fandom](https://lineage2.fandom.com/wiki/Dark_Elf)
- [Lineage 2 Dark Elf guide — MMO Auctions](https://mmoauctions.com/news/lineage-2-dark-elf-guide-learn-about-the-deadliest-race-in-l2)
- [Lineage II Legacy character appearance / hairstyles guide](https://legacy-lineage2.com/guide/appearance_hairstyles.html)
- [Lineage II Legacy face options guide](https://legacy-lineage2.com/guide/appearance_face_options.html)
- [Lineage II Legacy: Kamael race](https://legacy-lineage2.com/Knowledge/race_kamael.html)
- [Awakening (Update) — Lineage 2 Fandom Wiki](https://lineage2.fandom.com/wiki/Awakening_(Update))
- [Goddess of Destruction character creation video — elliebellynet](http://elliebellynet.blogspot.com/2011/05/character-creation-systems-lineage2.html)
- [Goddess of Destruction new hair styles — elliebellynet](http://elliebellynet.blogspot.com/2011/01/futures-and-design-new-characther-hair.html)
- [Lineage 2 Goddess of Destruction Bringing Big Changes — MMORPG forum](https://forums.mmorpg.com/discussion/314191/lineage-2-goddess-of-destruction-bringing-big-changes)
- [Lineage II Concept Art & Characters — Creative Uncut](https://www.creativeuncut.com/art_lineage-2_a.html)
- [Lineage 2 — Dark Elf Female (Bruno Sidarta, Vesper Noble) — ArtStation](https://www.artstation.com/artwork/deoBQ)
- [Lineage 2 Magmeld / R85 / R87 / R95 / R99 armor sets — lineage2media](https://lineage2media.com/Lineage2Goddess%20of%20Destruction%20New%20Armor%20Sets%20Magmeld%20.html)
- [Armor Sets Vesper S84 — L2DB](https://l2db.info/high-five/armorsets?grade=s84_vesper)
- [Lineage 2 Armor Sets — pmfun](https://lineage.pmfun.com/list/set)
- [Lineage II Armor Sets — StrategyWiki](https://strategywiki.org/wiki/Lineage_II/Items/Armor_Sets)
- [L2 Armors (Interlude) — l2.dropspoil.com](https://l2.dropspoil.com/?action=db&what=armor&button=Show&grade=s84)
- [Lineage 2 Armors — Lineage 2 Fandom Wiki](https://lineage2.fandom.com/wiki/Armors)
- [Eva's Hair Accessories — official Lineage 2 news](https://www.lineage2.com/en-us/news/evas-hair-accessory-2021)
- [Hyung-Tae Kim: Designing Around Fat — Game Developer](https://www.gamedeveloper.com/design/feel-the-flow-hyung-tae-kim-designs-around-fat)
- [Hyung-Tae Kim profile — gameproxl](https://www.gameproxl.com/post/hyung-tae-kim)
- [Korean MMO Art Style discussion — MMORPG.com forums](https://forums.mmorpg.com/discussion/460102/do-you-like-korean-mmo-art-style)
- [TERA art style discussion — MMORPG.com forums](https://forums.mmorpg.com/discussion/299388/tera-art-style)
- [Polygon counts for AAA character models — polycount discussion](https://polycount.com/discussion/230710/how-many-tris-for-a-aaa-modern-unreal-5-engine-game-pc-specs)
- [Thoughts on polygon count for MMO characters — Unreal forums](https://forums.unrealengine.com/t/thoughts-on-polygon-count-for-characters-for-an-mmo/35513)
- [Polygon Count standards — polycount wiki](http://wiki.polycount.com/wiki/Polygon_Count)
- [MMORPG character polygon count discussion — polycount](https://polycount.com/discussion/156009/polygon-count-for-a-mmorpg-game-to-be-released-on-two-years)
- [Unreal Engine 4.27 Photorealistic Character — Epic Games docs](https://docs.unrealengine.com/4.27/en-US/Resources/Showcases/PhotorealisticCharacter)
