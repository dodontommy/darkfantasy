# Dark Fantasy Character Research

Goal: create an original Lineage 2-inspired dark fantasy lady without copying a specific NCSoft character, armor set, iconography, or silhouette. Use the influence at the level of genre language: elegant high-fantasy proportions, ornate armor, sharp jewelry-like metalwork, long hair, ceremonial darkness, and readable game-character silhouettes.

## Local Baseline

- Blender CLI is installed: `/usr/bin/blender`, version `4.0.2`.
- Useful bundled Blender add-ons are present: `rigify`, `io_scene_fbx`, `io_scene_gltf2`, `magic_uv`, `mesh_auto_mirror`, `mesh_bsurfaces`, `mesh_looptools`, `object_boolean_tools`, `add_curve_extra_objects`, `object_print3d_utils`.
- `uv`, `uvx`, `npx`, `git`, and Python 3.12 are available.
- No MCP resources/templates are currently configured in this Codex session.

## Current Tooling Findings

### Blender MCP

Best candidate: `ahujasid/blender-mcp`.

Why it matters:
- Active, popular open-source Blender MCP bridge.
- Uses a Blender add-on plus MCP server.
- Supports scene inspection, object creation/modification/deletion, material changes, and arbitrary Blender Python execution.
- Current feature list also mentions viewport screenshots, Sketchfab search/download, Poly Haven assets, Hyper3D Rodin, Hunyuan3D, remote host support, and anonymous telemetry.

Practical fit:
- Worth trying if we want live conversational Blender control from an MCP-capable client.
- For this current Codex environment, direct Blender CLI scripting is already enough for deterministic asset generation and rendering.
- Treat arbitrary Python execution as high-trust local automation. Do not connect an unknown MCP server to important files without reviewing it.

Other MCPs:
- `sandraschi/blender-mcp` exists and claims broad tool coverage plus a web dashboard, but it had very low GitHub signal in search results compared with `ahujasid/blender-mcp`.
- Blockbench MCP exists, but Blockbench is better for voxel/low-poly/pixel-style assets than this more elaborate dark fantasy character.

### Skills

Public skills found via `npx skills find`:
- `omer-metin/skills-for-antigravity@3d-modeling`: 387 installs, broad 3D modeling guidance, 75 GitHub stars. Useful as generic topology/UV/LOD critique, not Blender-character specific.
- `smithery.ai@blender 3d` / `pacphi/blender-3d`: low install count but directly related to Blender MCP.
- `jasonjgardner/blockbench-mcp-project@blockbench-modeling`: relevant only if we intentionally choose a blocky low-poly style.

Recommendation: create a local project skill instead of installing a generic one. The useful skill should encode our specific character pipeline, style constraints, file layout, Blender CLI checks, and quality gates.

## Character Production Pipeline

### 1. Direction Lock

Deliverables:
- One-page art brief.
- 3 to 5 silhouette thumbnails.
- Color/material board.

Style target:
- Dark fantasy noble/war-caster, feminine, severe, elegant.
- Long vertical silhouette, narrow waist, high pauldrons or collar, cape/train shapes, ornate metal trim.
- Palette should avoid one-note black/purple. Use near-black cloth, desaturated steel, tarnished gold, bone/ivory skin accents, muted crimson or emerald gems.

Avoid:
- Direct L2 armor replicas.
- Exact racial/crest symbols.
- Overly modern tactical gear.
- Pure pinup framing where costume design becomes secondary.

### 2. Base Body

Fastest route:
- Use procedural blockout now, then replace with a humanoid base mesh from MB-Lab/CharMorph/MakeHuman or manual sculpt.

Open/free candidates:
- MB-Lab: works with Blender 4.0+, but repository is archived and final version notes known issues. Useful for humanoid base meshes, not enough for final costume.
- CharMorph: successor/rewrite direction from MB-Lab ecosystem; worth evaluating if we want generated humanoids inside Blender.
- MakeHuman: older but still useful as an external base-body generator if import/export is clean.

Best production route:
- Start from a legally clean base mesh.
- Sculpt over it for style.
- Retopologize only after silhouette and costume are approved.

### 3. Sculpt And Forms

Use:
- Symmetry for face/body/armor blockout.
- Voxel remesh during exploratory sculpting.
- Multires/subdivision only after major forms are stable.
- Separate objects for hair masses, armor plates, cloth layers, jewelry, and weapon props.

Key shapes:
- Face: high cheekbones, calm severe expression, long neck.
- Hair: large readable locks first; strand detail last.
- Armor: primary plates define silhouette; secondary filigree supports closeup; tertiary scratches/wear are late-stage.

### 4. Retopology

For animation-ready character:
- Body and face: clean quads, loops around eyes/mouth/shoulders/elbows/hips/knees.
- Armor: separate hard-surface meshes can use triangles where deformation is minimal.
- Cloth: quads with enough topology for folds or simulated motion.

Blender helpers:
- Shrinkwrap modifier.
- Face snapping/project.
- BSurfaces, F2, LoopTools, Auto Mirror.
- Keep high-poly sculpt and low-poly game/render mesh separate.

### 5. UVs And Materials

Suggested texture sets:
- Body/face: skin material, subtle roughness, procedural pores only if closeup.
- Armor metal: dark steel base, tarnished gold trim, edge wear, engraved masks.
- Cloth: near-black blue/green/red fabrics with woven bump/normal.
- Gems: crimson/emerald, emissive only if it supports the magic identity.

Use packed UV sets by material category at first; atlas later if game export matters.

### 6. Rigging And Posing

Blender-native:
- Rigify is bundled and suitable for humanoid body rig generation.
- Add facial shape keys later if expression animation matters.

Paid/optional:
- Auto-Rig Pro: strong for game export workflows.
- Faceit: focused facial expression/ARKit shape-key workflows.

First pose:
- Contrapposto stance, shoulders open, one hand near weapon/spell focus.
- Camera from slightly below eye level for noble/dangerous presence.

### 7. Rendering

Use CLI for repeatable checks:

```bash
blender --background scene.blend --render-output //renders/preview_ --render-frame 1
```

Use `--python-exit-code 1` for CI-style script failures:

```bash
blender --background --python-exit-code 1 --python scripts/create_dark_fantasy_lady_blockout.py
```

## First Character Brief

Working name: Nocturne Matriarch.

Core read:
- A dark elven highborn war-caster: austere, beautiful, dangerous, ceremonial rather than practical.

Silhouette:
- Tall, slim, long neck.
- High collar framing the jaw.
- Crown/horn headpiece rising behind hair.
- Angular pauldrons.
- Long split skirt/cape shapes.

Costume:
- Fitted bodice with dark steel breastplate.
- Tapered waist armor.
- Layered skirt panels.
- Thigh-high armored greaves.
- Finger armor or clawed gauntlets.
- Pendant or chest gem as magical focal point.

Materials:
- Blackened steel.
- Tarnished gold trim.
- Deep wine cloth.
- Bone-white hair or silver-black hair.
- One strong accent gem: crimson or emerald.

## Quality Gates

- Reads clearly at thumbnail size.
- Distinct from existing Lineage 2 assets.
- Body, cloth, armor, hair are separate enough to revise independently.
- No final retopology until silhouette and costume are approved.
- Every generated/rendered asset should be reproducible from a script or `.blend`.

## Sources To Keep Handy

- Blender command-line manual: background rendering and Python script execution.
- Blender Rigify manual: bundled automatic rigging from building-block components.
- Blender sculpting/retopology manual sections: sculpt, remesh, shrinkwrap, snapping.
- MB-Lab GitHub/docs: Blender 4.0+ humanoid character generation, archived/final-state caveats.
- Faceit docs: facial shape-key workflow if needed.
- `ahujasid/blender-mcp`: MCP bridge candidate for live Blender control.
