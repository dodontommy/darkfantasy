# AI 3D Generation for Dark Fantasy Character Production — May 2026 Reference

Audience: Technical 3D artist building a Lineage 2-inspired dark fantasy lady ("Nocturne Matriarch") in Blender, with the blender-mcp server giving direct access to Hyper3D Rodin, Hunyuan3D, Sketchfab, and PolyHaven.

Goal: Honest, current-as-of-May-2026 picture of which AI tools can actually contribute to character-grade output, what they cost, what their license posture is, and how to glue them together. No hype.

---

## At-a-glance comparison

| Tool | Type | Mesh fidelity (character) | Topology | Texture | License of output | Cost | Verdict for this pipeline |
|------|------|---------------------------|----------|---------|--------------------|------|----------------------------|
| Hyper3D Rodin Gen-2 / Gen-2 Edit | Image+text-to-3D, hosted | Top-tier among hosted; 4x mesh quality vs Gen-1 | Quad-dominant, 4k/8k/18k/50k face presets, T/A-pose enforcement | 4K PBR (albedo, normal, roughness, metallic) | Full commercial rights on all tiers including Free | Free tier, $20–30/mo Creator, ~$120/mo Business with API | Primary base-mesh generator. Use it. |
| Tencent Hunyuan3D 2.1 | Image-to-3D, open weights | High geometric detail; 1024 res in 2.5 (closed) | Tri by default; PolyGen 1.5 adds quad/auto-retopo | 4K PBR with physics-based shading | Apache 2.0 (2.1) — restricted in EU/UK/KR; 2.5 / PolyGen still closed | Free if self-hosted; cloud APIs vary | Best open-weights option. Self-host for IP safety. |
| Hunyuan3D-PolyGen 1.5 | Auto-retopo over mesh | n/a (it consumes meshes) | Autoregressive quad/tri, 10K+ faces, clean edge loops | n/a | Closed beta (in HY3D engine); inquiry open about open-sourcing | Hosted on Tencent's HY3D engine | Best AI auto-retopo of 2026 if you can get access. |
| Tripo 3.0 / 3.1 / P1 | Text+image-to-3D, hosted | Strong since 3.0 update; sharp edges, coherent structures | Smart quad remesh, 48–500K faces | PBR up to 2048; auto-rig included | Commercial rights with paid plan; consult ToS | Free 300 cr/mo; Pro $19.90/mo for 3,000 cr | Strong all-rounder; best end-to-end (gen+rig) hosted pipeline. |
| Meshy 6 | Text+image-to-3D, hosted | Up to ~600K faces; refined geometry vs Meshy 5 | Built-in remesh; A/T-pose option | PBR + AI texture refresh | Commercial with paid plan | Free; Pro $20/mo; Max $60; API/Enterprise $90 | Good for rapid iteration; weaker on character anatomy than Rodin. |
| Microsoft TRELLIS / TRELLIS.2 | Image-to-3D, open weights | TRELLIS.2 (4B) handles complex topology + sharp features | "Field-free" sparse voxel (O-Voxel); not native quad | Native PBR in TRELLIS.2; can hand off to SDXL/FLUX texturing | MIT | Free (self-host; ~24GB VRAM for full model) | Excellent for technical users with a GPU. Best open mesh quality after Hunyuan. |
| CSM AI | Image+sketch-to-3D, hosted | Decent; Character-Sheet-to-3D shipped to reduce hallucinations | Quad-friendly; SAM-based part segmentation | PBR | Commercial with paid plan | Tiered subscriptions | Useful if you have orthographic concept sheets. |
| Kaedim | Hybrid AI + human cleanup | Production-grade (artist-finished) | Guaranteed quads, watertight, separated meshes | Studio-finished textures/UVs | Full commercial; studio service | Enterprise pricing (per-asset, $$$) | Skip unless budget is high and deadline is real. |
| Luma Genie | Text-to-3D, hosted | Fast, decent base meshes | Quad-capable at any poly count, in standard formats | Basic textures | Commercial with paid plan | Free tier; metered API | Quick concept blockouts; not for hero characters. |
| Stable Fast 3D (Stability AI) | Image-to-3D, open | Single image in ~0.5s; fast preview-grade | Optional quad/tri remesh; good UVs | Albedo + material + normals; light disentanglement | Stability AI Community License — commercial up to revenue cap | Free (self-host) | Useful as a fast first-pass; not hero-character quality. |
| CharacterGen | Image-to-3D, character-specific (research) | Pose-canonicalized; good for downstream rigging | Quad-friendly via canonicalized A-pose output | Modest | Research / non-commercial style license; check repo | Free (self-host) | Useful research baseline; eclipsed by Rodin/Hunyuan in 2026 quality. |
| StdGEN (CVPR 2025) | Image-to-3D, semantic-decomposed | Decomposes hair/clothes/body — useful for fantasy outfits | Per-part meshes that retopo separately | Modest | Open source | Free (self-host) | Promising for armor + body separation; small dataset shows. |
| Hitem3D | Image-to-3D, hosted | Ultra-high mesh res (1536³), miniature/print focus | Triangle soup; not animation-ready | Limited | Commercial with paid plan | Tiered | Use only if you want printable figurine, not a rigged character. |
| NVIDIA Edify 3D / Picasso | Enterprise foundry models | Variable; depends on partner fine-tune | Variable | Variable | Enterprise license through partners (Shutterstock, Getty) | Enterprise; NIM preview ended June 2025 | Not relevant for an indie/single-artist pipeline. |
| Adobe Substance 3D + Firefly | DCC + 2D/3D AI assist | n/a (texturing/scene only) | n/a | Firefly Text-to-Texture, Generative Background, 3D-to-Image | Commercial-safe per Adobe IP indemnity | Substance Collection ~$50/mo | Useful for textures with corporate-friendly IP. |
| Stable Projectorz | Texture projection in DCC | n/a | n/a | Multi-view projection PBR via Stable Diffusion | AGPL-3.0 | Free | Best AI texture finisher for Blender. |
| StableGen (Blender add-on) | Texture projection in Blender | n/a | n/a | SDXL/FLUX direct in Blender | Open source | Free | Good in-Blender alternative to Projectorz. |
| Quad Remesher (Exoside) | Auto-retopo (algorithmic, not AI) | n/a | Quads, edge-loop aware; v1.3.0 supports 2025–2026 | n/a | Commercial | $99 indie / $260 standard | Default battle-tested retopo on top of any AI mesh. |
| ZRemesher (ZBrush) | Auto-retopo, same author as Quad Remesher | n/a | Quads with guides | n/a | Bundled with ZBrush | ZBrush subscription | Use if you sculpt cleanup in ZBrush. |
| RetopoFlow 4.1.6 | Manual retopo toolkit, Blender | n/a | Quads, integrated into Edit Mode | n/a | Commercial add-on | Paid (25% upgrade for v3 owners) | Manual safety net for face/hands. |
| AccuRIG 2 (Reallusion) | Auto-rigging, free | n/a | n/a | n/a | Free for commercial | Free | Best free auto-rigger 2026; outputs Rigify-friendly. |
| Mixamo | Auto-rigging, hosted | n/a | n/a | n/a | Free for commercial | Free | Stagnant since Adobe acquisition; still works as a fallback. |
| Anything World | Auto-rigging, hosted | n/a | n/a | n/a | Commercial with paid plan | Tiered | Good for low-poly + non-humanoids; less ideal for hero characters. |
| KIRI Engine 3DGS-to-Mesh / SuGaR | Gaussian splat to mesh | Good for likeness from photos; not for invented characters | Triangle soup → needs retopo | Vertex color / texture bake | KIRI commercial; SuGaR research | Free–tiered | Reference workflow, not production character source. |

---

## Deep dives

### 1. Hyper3D Rodin (Gen-2 / Gen-2 Edit)

**What it is.** A hosted text/image/multi-image-to-3D system from Deemos. Gen-2 is a 10B-parameter model, claimed 4x mesh quality over Gen-1, generates in 30–60s. Gen-2 Edit (announced late 2025) is the first true 3D GenAI editing platform — you can re-prompt parts of an existing generation. There is no public Gen-3 as of May 2026; a Gen-2.5 waitlist was teased in early 2026 with focus on ultra-detailed geometry.

**Outputs.** Quad-dominant topology at 4K / 8K / 18K / 50K face presets. T/A-pose enforcement is exposed as a parameter (critical for downstream rigging). Multi-image support lets you feed front/side/back of a concept. PBR maps: albedo, normal, roughness, metallic, up to 4K on the Business tier.

**Strengths for dark fantasy.** Best textures in the hosted-tool field, by most 2026 head-to-heads. Handles costume detail (cloth folds, leather buckles) better than Tripo or Meshy. The T-pose enforcement plus 18K-quad preset is the closest thing to a "drop-in animation-ready base" you'll get from any AI tool today.

**Weaknesses.** Faces are still uncanny — particularly eyes, eyelashes, and lip seams. Hair comes back as a chunky helmet, never strands. Fingers and weapon-grip detail are unreliable. Symmetry on full-body characters is good but never perfect.

**License.** Per Hyper3D's pricing page, all tiers — including Free — grant full commercial rights to generated assets. Their training-data disclosure is thin (typical for the category). Treat outputs as commercial-usable for derivative work, but do not assume the tool will indemnify you against third-party claims.

**Cost.** Free tier; Education $15/mo; Creator $20/mo first month then $30/mo (30 credits/mo); Business ~$120/mo with 4K textures, high-poly export, and API access. Per-asset download is roughly $0.50–$1.50 in the metered model.

**Blender integration.** Already wired through the blender-mcp server you have. Output is .glb / .fbx / .obj; PBR maps come unpacked.

**Verdict.** Primary base-mesh generator for Nocturne Matriarch. Use 18K_Quad with T-pose enforcement, multi-image input from your concept references.

---

### 2. Tencent Hunyuan3D (2.1, 2.5, PolyGen)

**State of the family in May 2026.**
- **Hunyuan3D 2.0**: open Apache-2.0, 512 geo res.
- **Hunyuan3D 2.1**: fully open-sourced June 13, 2025 — weights, VAE encoder, training code. Adds production-ready PBR with physics-grounded material synthesis.
- **Hunyuan3D 2.5**: April 23, 2025. Closed-beta-only as of May 2026. 1024 geo res (2x linear / 10x effective face count), 4K textures, bump mapping, multi-view PBR. Open-source plans inquired about; not delivered.
- **Hunyuan3D-PolyGen 1.5**: July 2025. Autoregressive mesh generator that produces quad-or-tri art-grade topology with continuous edge loops. Used inside Tencent's own game pipelines. Hosted only.
- **Hunyuan 3D Engine** went global in late 2025, bundling these models behind one API.

**Strengths for dark fantasy.** 2.1 self-hosted gives you a model that produces textures with believable nylon, leather, and metallic specularity under HDRI lighting. PolyGen is the standout: it's the only AI-native auto-retopo that produces edge loops the way an environment artist would.

**Weaknesses.** 2.1 mesh output is triangle soup unless you pass it through PolyGen. Fingers and faces show the same issues as everything else in the category. 2.5 and PolyGen 1.5 are not open weights — you depend on Tencent's hosted engine for them.

**License.** Hunyuan3D 2.1 is Apache 2.0, but the official model card explicitly excludes use in the EU, UK, and South Korea due to regulatory exposure (EU AI Act in particular — see IP section below). Outputs from cloud Hunyuan: check the engine ToS at time of use; commercial rights generally extend with paid tier.

**Cost.** Free if you self-host (one A100 / one 24GB consumer GPU for 2.1). Cloud pricing varies by reseller (fal.ai, WaveSpeedAI, Scenario).

**Blender integration.** Available through your blender-mcp server and via direct .glb export from any cloud reseller.

**Verdict.** Best open-weights option. If IP hygiene matters (you want to be able to point at training-data terms), self-hosted Hunyuan3D 2.1 is the strongest defensible choice in 2026. PolyGen is the post-process you want over any AI mesh, if you can get access.

---

### 3. Tripo (Tripo3D, by VAST AI Research)

**State May 2026.** Tripo 3.0/3.1 is the "feature-rich" tier — up to 500K faces, smart low-poly and quad remeshing, parts segmentation, PBR up to 2048. P1 is the game-optimized tier: 48–20K faces, model seeds for reproducibility, orientation control, native 3D diffusion. Tripo also ships a built-in Auto-Rigger producing motion-cap-quality skeletons and skin weights — nobody else hosted ships this in one click.

**Strengths.** End-to-end pipeline in one tool: gen → remesh → rig → animation library. Quality jumped substantially with 3.0; the old "blobby AI mesh" problem is largely gone. Their official Blender add-on (`VAST-AI-Research/tripo-3d-for-blender`) plus a Python SDK make this genuinely scriptable.

**Weaknesses.** Texture realism still trails Rodin. Auto-rig is good but not Lineage-2-grade — expect to redo eye, jaw, and finger weights for cinematic close-ups.

**License.** Pro plan ($19.90/mo) explicitly grants commercial rights on outputs. Free plan (300 credits) is personal use only.

**Cost.** Free / Pro $19.90/mo (3,000 credits) / pay-as-you-go API with credits valid 365 days.

**Blender integration.** Official add-on. First-class.

**Verdict.** The most pragmatic single-tool pipeline for indie character work. If you only buy one paid 3D AI subscription this year, it is Tripo.

---

### 4. Meshy 6

**State May 2026.** Meshy 6 shipped January 18, 2026. Up to ~600K faces; sharper edges; A-pose / T-pose option for rigging-friendly generation; Low-Poly Mode for game-ready output; multi-color 3D printing support; expanded API.

**Strengths.** Massive ecosystem, very fast, easy in-browser iteration. The Retexture endpoint (Meshy 5/6) lets you re-skin an existing mesh from a text/image prompt — useful for variant armor.

**Weaknesses.** Geometry quality on full-body characters lags Rodin and Tripo 3.0. Topology, even after the built-in remesh, needs Quad Remesher to be animation-grade.

**License.** Commercial rights with paid plan (Pro $20, Max $60, API/Enterprise $90).

**Cost.** Meshy-6 preview = 20 credits/task; full textured = 30 credits/task.

**Blender integration.** Web export to .glb/.fbx, official API. No first-party add-on.

**Verdict.** Use it for variant exploration and quick retextures, not as your hero base mesh.

---

### 5. Microsoft TRELLIS / TRELLIS.2

**State May 2026.** Original TRELLIS (CVPR'25 Spotlight) introduced Structured LATents (SLAT). TRELLIS.2 (4B parameters) followed with a "field-free" sparse voxel representation called O-Voxel that handles complex topologies, sharp features, and full PBR. Models on Hugging Face (`microsoft/TRELLIS.2-4B`); MIT license.

**Strengths.** Best raw mesh accuracy among open-weight image-to-3D models, especially with a T-pose reference image. Native PBR. Decoder can spit out radiance fields, Gaussians, or meshes — useful if you want to render the same generation in different forms.

**Weaknesses.** Output is not native quad — you need Quad Remesher / PolyGen / ZRemesher behind it. Requires a serious GPU for the 4B variant. No native rigging.

**License.** MIT for code and the majority of weights — the cleanest open-source posture in this whole list.

**Cost.** Free, self-hosted. Plan for ~24GB VRAM minimum.

**Blender integration.** Via .glb export; no first-party add-on.

**Verdict.** If you have a local 4090/5090, TRELLIS.2 is your best open-weights mesh generator. Combine with PolyGen or Quad Remesher for topology.

---

### 6. CSM AI (Common Sense Machines)

**State May 2026.** Major release earlier in 2026 added "Object/Character Sheet-to-3D" which directly accepts concept-art sheets (orthographics not required) and reduces hallucinations. Uses Meta's SAM 2 for part segmentation so output meshes come pre-decomposed for rigging.

**Strengths.** The character-sheet ingestion is genuinely differentiated — for stylized fantasy work where you have a 3-view illustration, CSM is the best fit. SAM-based part separation is helpful for armor pieces.

**Weaknesses.** Texture realism trails Rodin and Hunyuan. Less buzz / smaller user base than competitors → fewer community workflows.

**License.** Paid plans grant commercial rights.

**Cost.** Subscription tiers (consult csm.ai).

**Verdict.** Worth a free-tier trial if you have a proper Lineage-2 concept sheet. Otherwise, skip.

---

### 7. Kaedim

**State May 2026.** Hybrid AI + ~80 in-house artists. Outputs are guaranteed quads, separated into multiple meshes, watertight, with proper UVs. Sells itself on "production-ready, 10x faster than manual."

**Strengths.** Only option in this list that delivers studio-ready meshes you'd actually ship to a Lineage-2-tier game without further retopo.

**Weaknesses.** Cost. Turnaround is hours-to-days, not seconds. You're paying for human labor underneath the AI.

**License.** Full commercial; standard studio service contract.

**Cost.** Enterprise / per-asset; not publicly listed but expect $$$.

**Verdict.** Skip for an indie / single-artist project unless you have a fixed deadline and a real budget.

---

### 8. Luma Genie

**State May 2026.** Still hosted text-to-3D with sub-10s generations. Quad meshes available at any poly count.

**Strengths.** Speed. Free tier is generous. Good for pure ideation/blockout.

**Weaknesses.** Character results are notably weaker than Rodin/Tripo/Hunyuan. No native rigging.

**License.** Commercial with paid plan.

**Verdict.** Use as a sketchpad. Not a hero-character source.

---

### 9. Stable Fast 3D (Stability AI)

**State May 2026.** Single-image to textured mesh in ~0.5s. UV-unwrapped, illumination-disentangled albedo, predicted material parameters and normals. Open-source on GitHub and Hugging Face. Initial release was August 2024; no major revision since — Stability's 3D efforts have been quiet through 2025–2026.

**Strengths.** Speed; clean UVs; light/shadow disentanglement makes textures behave correctly under new lighting.

**Weaknesses.** Mesh quality below Hunyuan3D 2.1 and far below Rodin. Character work is weak.

**License.** Stability AI Community License — commercial use up to a revenue cap (verify current terms).

**Verdict.** Useful for a sub-second preview pass; not for a hero asset.

---

### 10. CharacterGen / StdGEN

**CharacterGen (SIGGRAPH'24).** Image-to-3D-character with multi-view pose canonicalization — outputs in a unified A-pose so the result feeds rigging cleanly. Open source on GitHub and Hugging Face.

**StdGEN (CVPR 2025).** Semantic-decomposed character generation — separates hair / clothes / body into distinct meshes from a single image. Excellent for armored characters where you want gauntlets, pauldrons, and underbody as distinct objects.

**Verdict.** Both are research-grade and have been eclipsed in raw mesh fidelity by Rodin/Hunyuan/TRELLIS.2 in 2026. StdGEN's decomposition is the genuinely useful idea — worth running for armor part separation if you have the GPU.

---

### 11. NVIDIA Edify 3D / Picasso

**State May 2026.** Edify 3D is part of NVIDIA's foundry stack delivered through partners (Shutterstock, Getty Images for indemnified content). NVIDIA Edify is no longer offered as a NIM microservice preview as of June 6, 2025; access is through partner products on build.nvidia.com.

**Verdict.** Not a relevant option for an indie pipeline. Skip.

---

### 12. Adobe Substance 3D + Firefly

**State May 2026.** Substance 3D Modeler 1.22.x is the latest desktop / VR sculpting client (no major AI-gen integration yet — sculpting still happens by hand). The Firefly AI surface lives in Sampler (Text-to-Texture), Stager (Generative Background), and Viewer (3D-Model-to-Image). Firefly is trained on Adobe Stock and licensed content; Adobe offers IP indemnity for enterprise customers.

**Verdict.** Substance Painter / Sampler with Firefly textures is the safest commercial pipeline for surface work if you're paranoid about IP. Substance 3D Modeler itself is just sculpting; not generative.

---

### 13. Rigging stack: AccuRIG 2, Mixamo, Tripo Auto-Rig, Anything World

- **AccuRIG 2 (Reallusion)** — free, fast, accurate. Outputs FBX/USD that drop straight into Blender as Rigify-ready skeletons. The 2025 v2 release is materially better than Mixamo. **Use this as default.**
- **Mixamo** — free, stagnant since Adobe acquisition, no meaningful updates "in years." Still works for quick humanoid rigs and grabbing animation clips. Fallback only.
- **Tripo Auto-Rig** — built into Tripo, single-click after generation. Convenient if you're already in Tripo. Less control than AccuRIG.
- **Anything World** — strong on non-humanoids (animals, vehicles); fine for low-poly humanoids. Not the choice for a hero fantasy character.
- **RigNet** — academic; not maintained for production.

For Nocturne Matriarch, plan: AccuRIG 2 to bones/weights, then Blender Rigify control rig over the top for animation control.

---

### 14. AI texture generators that pair with a finished mesh

- **Stable Projectorz** (AGPL-3.0). Multi-view depth-aware projection of Stable Diffusion / SDXL / FLUX onto your mesh. Best-in-class for organic surfaces (skin, weathered metal, fabric); struggles on hard-surface industrial seams. Free.
- **StableGen** (Blender add-on, open source). Same idea, lives inside Blender directly. Less mature than Projectorz but you don't leave the DCC.
- **TRELLIS.2 native PBR** + a re-texture pass via SDXL/FLUX/Qwen-Image-Edit. Mentioned in TRELLIS.2 docs as the recommended pipeline.
- **Substance Sampler (Firefly Text-to-Texture).** IP-clean fallback, paid.
- **Material Maker AI / AI Material Factory** — Blender Market plugins for procedural-plus-AI material setups; useful for patterns (heraldry, runes) on cape/cloth.

---

### 15. Photogrammetry / Gaussian splatting (reference, not character source)

- **KIRI Engine 3.12** — 3DGS-to-Mesh 2.0 with normal prediction and reflection removal; KIRI Blender add-on v4.1 for direct PLY import.
- **SuGaR** — academic Gaussian splat → editable mesh (single GPU, minutes). Animation works by binding gaussians to the extracted mesh surface.
- **Splatware / SkySplat** — Blender 5 import + render add-ons.

For an *invented* character, splatting is a dead end (you can't photograph a non-existent person). For *reference plates* (a leather jacket, a chainmail coif you photographed) it's now a real production option.

---

## Best workflow for a high-fidelity dark fantasy character in 2026

The honest answer: there is no single tool that gives you a Lineage-2-fidelity character end-to-end. The best 2026 pipeline chains specialists.

1. **Concept art (2D).** Midjourney v7 with `--oref` to lock the character across views, or FLUX 1.1 Pro for editable reference. Generate at minimum a front, 3/4, and back orthographic. Save the prompt for reproducibility.
2. **3D base mesh.** Hyper3D Rodin Gen-2 with `multi-image` input (the front/3-quarter/back from step 1), `T_Pose=true`, `18k_Quad` topology, 4K PBR. Fall back to self-hosted Hunyuan3D 2.1 if you want defensible IP / no cloud dependency. For armor pieces specifically, run StdGEN to get pauldrons / gauntlets / breastplate as separate meshes.
3. **Topology refinement.** If you have access, run Hunyuan3D-PolyGen 1.5 over the Rodin output. Otherwise: Quad Remesher in Blender (Exoside add-on) targeting ~30K quads for the body, separate retopo passes for hands and head.
4. **Manual sculpt cleanup in Blender.** This is non-optional for hero characters. Hands/fingers, face symmetry, hair planes, costume connectors (belts where they meet the waist, armor straps where they cross). Plan 2–6 hours.
5. **UV pass.** Trust Rodin's UVs for the body, redo for the head. Use UVPackmaster 3 for repacking.
6. **AI texture pass.** Stable Projectorz with SDXL or FLUX, projecting your concept-art's color palette onto the cleaned mesh. Bake to 4K. For runes/heraldry on the cape, Substance Sampler Text-to-Texture with Firefly (IP-clean).
7. **Material setup.** PBR maps imported as Principled BSDF. Adjust roughness on metal, add SSS on skin (Rodin albedo is fine, but its skin is too matte by default).
8. **Hair.** AI hair generation is still not viable in 2026. Use Blender's hair curves with a Lineage-2-style braided/loose card-based approach, or buy a hair pack from Superhive/Blender Market.
9. **Rigging.** AccuRIG 2 for the bone hierarchy and skin weights. Drop into Blender, build a Rigify control rig on top. Verify deformations on shoulder, elbow, hip.
10. **Animation library.** Mixamo for placeholders. Rokoko free pack or AccuRIG ActorCore for production motion clips.

### What you still cannot trust AI for in 2026

- **Hands / fingers.** Every model in this report fails at finger separation, nail detail, and grip poses. Manual sculpt or graft hands from a known-good base mesh.
- **Faces (close-up).** Eyes, eyelashes, lip seams, ear cartilage. AI faces are uncanny. Use a high-quality blendshape head (e.g., MetaHuman, Character Creator 4 head) and blend.
- **Hair strands.** AI gives you a helmet of hair. Use Blender hair curves or hair cards.
- **Costume connectors.** Belt buckles, armor straps, ribbon ties. AI hallucinates the geometry where two pieces meet.
- **Animation-ready topology around joints.** Even PolyGen and Rodin's quad mode fall short on knee, shoulder, and jaw loops.
- **Symmetry on full-body.** Always re-symmetrize a mirror axis manually in Blender.
- **Logos / IP-recognizable elements.** Do not let AI generate Lineage-2-trademarked iconography directly — paraphrase the dark-fantasy aesthetic, don't reproduce specific NCsoft IP.

---

## Retopology after AI generation in 2026

| Tool | Type | Status May 2026 | Recommended for |
|------|------|-----------------|------------------|
| Hunyuan3D-PolyGen 1.5 | AI auto-retopo | Closed beta in HY3D engine; best AI-native quad output | Bodies, organic forms — if you have access |
| Quad Remesher (Exoside v1.3.0) | Algorithmic | Maintained, supports Blender / Max 2025–2026 | Default reliable retopo for any AI mesh |
| ZRemesher | Algorithmic | Bundled with ZBrush; same author as Quad Remesher | If you sculpt cleanup in ZBrush |
| Blender Voxel Remesh / Quadriflow | Algorithmic | Built-in, free | Crude blockouts only |
| RetopoFlow 4.1.6 (Orange Turbine) | Manual toolkit | Released April 2026, integrated into Blender Edit Mode | Faces and hands, where automatic fails |

Reality check: **No fully-AI auto-retopo is yet trustworthy unattended for hero characters.** PolyGen 1.5 is the closest, and it's still gated behind Tencent's hosted engine. Best 2026 practice is: AI mesh → Quad Remesher pass → manual RetopoFlow cleanup on face and hands.

---

## IP, license, and dataset hygiene in 2026

**US Copyright Office.** Position is settled: pure-AI output with no human creative contribution beyond a prompt is not copyrightable. AI-assisted works *can* be protected for the human-authored parts. The Supreme Court denied cert on March 2, 2026 in the Thaler appeal, leaving the human-authorship requirement intact.

**Practical implication:** Your final Nocturne Matriarch *can* be copyrighted by you, but only the parts you meaningfully authored — the sculpt cleanup, the rigging, the texture composition. Document your manual contributions (screenshots, version history) so you can show creative authorship.

**EU AI Act.** Training-data transparency rules come into force August 2, 2026. Every general-purpose AI model provider must publish a public summary of training datasets using the Commission's mandatory template. Penalties up to €15M or 3% of global revenue. This is why Hunyuan3D 2.1's Apache 2.0 license carves out the EU/UK/South Korea — Tencent is not yet ready to file the disclosure. If you operate or distribute in those jurisdictions, prefer models that have already filed (Adobe Firefly, NVIDIA Edify partners) or pure self-hosted models where you control the data trail.

**Active 3D-relevant litigation as of May 2026.**
- **Disney + Lucasfilm + Marvel + Universal v. Midjourney** survived motion to dismiss; discovery proceeding. Sets the precedent that will likely shape 3D-AI cases next.
- **Getty v. Stability AI** ongoing.
- **Bartz v. Anthropic** settled for $1.5B (not 3D-specific, but sets the tone for "training on pirated work" damages).

**Tool-specific posture:**
- **Hyper3D Rodin** — full commercial rights stated for output on all tiers. Training-data disclosure thin.
- **Hunyuan3D 2.1** — Apache 2.0 weights, EU/UK/KR carve-out. Best for self-host IP defensibility.
- **Tripo / Meshy / Luma / CSM** — commercial rights with paid plan. No public dataset disclosure.
- **TRELLIS / TRELLIS.2** — MIT, cleanest open posture. Research-paper-disclosed dataset (~500K objects).
- **Stable Fast 3D** — Stability Community License with revenue cap.
- **Adobe Firefly textures** — IP-indemnified for enterprise, trained on licensed content. Cleanest commercial posture.
- **Sketchfab downloads** — CC-BY default, attribution required. Other CC variants possible (NC, ND, SA). Always check the per-model license before commercial use.
- **PolyHaven** — CC0, no attribution required, fully commercial.

**Recommended posture for Nocturne Matriarch:** Self-hosted Hunyuan3D 2.1 or licensed Hyper3D Rodin output (commercial rights) → human sculpt and texture pass (establishes copyrightable authorship) → CC0 PolyHaven HDRIs and any reference textures → Adobe Firefly for any text/heraldry generation. Document every manual step with timestamps.

---

## Recommended pipeline for Nocturne Matriarch

A concrete 9-step plan, scoped to a single technical artist with the blender-mcp server already wired up.

1. **Concept lock.** Generate the front / 3-quarter / back orthographic of Nocturne Matriarch in Midjourney v7 or FLUX 1.1 Pro. Use Omni Reference / IP-Adapter to maintain the same face and costume across all three. Save prompts, seeds, and the three reference images to `outputs/concept/`.
2. **Base body generation.** Through blender-mcp, call `mcp__blender__generate_hyper3d_model_via_images` with the three references, `T_Pose=true`, topology preset `18k_Quad`, PBR enabled. Import the .glb into Blender as the base. Backup: self-hosted Hunyuan3D 2.1 if you want a defensible-IP variant.
3. **Armor part decomposition.** Run StdGEN locally on the same orthographic to get pauldrons, gauntlets, and breastplate as separate meshes. Import as kit-bash pieces; align to the base body.
4. **Topology pass.** Quad Remesher in Blender on the body at ~30K quads. Separate retopo on the head (~12K quads, edge loops around eyes/lips). Optional: if Hunyuan3D-PolyGen access is available, run it first for AI-native quads.
5. **Sculpt cleanup.** In Blender's Sculpt Mode: re-do the face proportions, fix finger separation, sharpen costume connectors, add belt/buckle detail. Use RetopoFlow 4.1.6 for any sections that need manual quads.
6. **UV pass.** Trust Rodin's body UVs; redo head UVs manually; use UVPackmaster for the armor kit.
7. **Texture pass.** Stable Projectorz with FLUX projecting your concept palette onto body and armor. Bake to 4K PBR. Substance Sampler Firefly Text-to-Texture for any heraldry/runes (IP-clean). Mix in PolyHaven CC0 fabric and metal materials for base layers.
8. **Hair and eyes.** Blender hair curves for hair (do not trust AI). Source MetaHuman or CC4 eye geometry; blend into the head. This is the step where the character starts looking alive.
9. **Rig and test.** AccuRIG 2 for bones + weights → import into Blender → Rigify control rig on top → load 3 Mixamo clips (idle, walk, attack) and verify deformations on shoulder, elbow, hip, jaw. Iterate weights as needed.

Optional step 10: Render a turntable and a hero shot in Cycles with a PolyHaven HDRI. Use the result as the new reference for any variant generations (armor recolor, weapon swap) via Meshy 6 Retexture.

---

## Sources

- [Hyper3D — Rodin Gen-2 official](https://hyper3d.io/)
- [Hyper3D Developer — Gen-2 Generation API spec](https://developer.hyper3d.ai/api-specification/rodin-generation-gen2)
- [Hyper3D — pricing & plans](https://hyper3d.ai/subscribe)
- [Rodin by Hyper3D Review 2026 — pricing, pros, cons](https://mostpopularaitools.com/tools/rodin-by-hyper-3d)
- [Rodin Gen-2 release notes (toolnavs)](https://toolnavs.com/en/article/403-rodin-gen-2-is-now-available-officials-claim-it-offers-a-4x-improvement-in-mesh)
- [AWN — Hyper3D CTO on Rodin Gen-2 Edit](https://www.awn.com/animationworld/beyond-generation-hyper3dai-cto-zhang-qixuan-rodin-gen-2-edit-and-future-3d-ai)
- [Tencent — Hunyuan3D-2.1 GitHub (open source PBR pipeline)](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1)
- [Tencent — Hunyuan3D-2 GitHub (2.0 base model)](https://github.com/Tencent-Hunyuan/Hunyuan3D-2)
- [Vset3D — Hunyuan 3D-2.5 deep-dive](https://www.vset3d.com/hunyuan-3d-2-5-tencent-pushes-the-boundaries-of-3d-generation-with-ai/)
- [GitHub issue — open-source plans for Hunyuan3D-2.5 and PolyGen](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/issues/111)
- [Tencent Hunyuan3D-PolyGen announcement](https://www.artificialintelligence-news.com/news/tencent-hunyuan3d-polygen-a-model-for-art-grade-3d-assets/)
- [Scenario — Hunyuan PolyGen 1.5 essentials](https://help.scenario.com/en/articles/hunyuan-polygen-the-essentials/)
- [Tencent — Hunyuan 3D Engine global launch](https://www.tencent.com/en-us/articles/2202235.html)
- [Tripo3D — official site](https://www.tripo3d.ai/)
- [Tripo API documentation](https://www.tripo3d.ai/api)
- [VAST-AI-Research — Tripo Blender add-on](https://github.com/VAST-AI-Research/tripo-3d-for-blender)
- [VAST-AI-Research — Tripo Python SDK](https://github.com/VAST-AI-Research/tripo-python-sdk)
- [Tripo AI Review 2026](https://mostpopularaitools.com/tools/tripo-ai)
- [Meshy — pricing](https://www.meshy.ai/pricing)
- [Meshy AI v6 review (2026)](https://www.toolworthy.ai/tool/meshy-ai-v6)
- [Meshy 6 release & pricing details](https://costbench.com/software/ai-3d-generation/meshy/)
- [Microsoft TRELLIS GitHub (CVPR'25)](https://github.com/microsoft/TRELLIS)
- [Microsoft TRELLIS.2 GitHub](https://github.com/microsoft/TRELLIS.2)
- [TRELLIS.2 project page](https://microsoft.github.io/TRELLIS.2/)
- [Hugging Face — microsoft/TRELLIS.2-4B](https://huggingface.co/microsoft/TRELLIS.2-4B)
- [arXiv 2512.14692 — TRELLIS.2 paper](https://arxiv.org/html/2512.14692v1)
- [CSM AI overview](https://moge.ai/product/common-sense-machines-csm)
- [Meta AI blog — CSM uses SAM 2 for production-ready 3D](https://ai.meta.com/blog/segment-anything-common-sense-machines-3d-assets/)
- [Kaedim — official site](https://www.kaedim3d.com/)
- [Kaedim — how it works](https://docs.kaedim3d.com/welcome/how-kaedim-works)
- [Kaedim review 2026 (Toosio)](https://toosio.com/tool/kaedim-3d-modeling-review)
- [Luma AI Genie review 2026](https://www.toolworthy.ai/tool/luma-ai-genie)
- [Luma — API page](https://lumalabs.ai/api)
- [Stability AI — Stable Fast 3D announcement](https://stability.ai/news-updates/introducing-stable-fast-3d)
- [Stability AI — Stable Fast 3D GitHub](https://github.com/Stability-AI/stable-fast-3d)
- [SF3D project page](https://stable-fast-3d.github.io/)
- [CharacterGen project page (SIGGRAPH'24)](https://charactergen.github.io/)
- [CharacterGen GitHub](https://github.com/zjp-shadow/CharacterGen)
- [StdGEN — semantic-decomposed character generation (CVPR 2025)](https://github.com/hyz317/StdGEN)
- [Hitem3D vs Rodin vs Tripo (3DAIStudio)](https://www.3daistudio.com/3d-generator-ai-comparison-alternatives-guide/rodin-alternative)
- [TRELLIS vs Meshy vs Tripo vs Hitem3D (2026)](https://trellis2.app/blog/best-ai-3d-model-generator)
- [3DAI Studio — best 3D AI APIs 2026](https://www.3daistudio.com/blog/best-3d-model-generation-apis-2026)
- [Sloyd — 2026 3D AI pricing comparison](https://www.sloyd.ai/blog/3d-ai-price-comparison)
- [NVIDIA — Edify 3D announcement](https://blogs.nvidia.com/blog/edify-3d-generative-ai-custom-fine-tuning/)
- [NVIDIA — Edify cloud foundry](https://www.nvidia.com/en-us/gpu-cloud/edify/)
- [Adobe — Firefly in Substance 3D apps](https://news.adobe.com/news/news-details/2024/adobe-brings-firefly-generative-ai-into-substance-3d-workflows)
- [Adobe — Substance 3D Viewer Gen AI](https://helpx.adobe.com/substance-3d-viewer/using/gen-ai.html)
- [Reallusion — AccuRIG official](https://actorcore.reallusion.com/auto-rig)
- [Reallusion — AccuRIG to Blender pipeline](https://magazine.reallusion.com/2022/11/11/accurig-to-blender-pipeline-an-easy-accurate-way-to-auto-rig-any-character/)
- [Reallusion — AccuRIG 2 vs Mixamo](https://magazine.reallusion.com/2025/07/30/accurig-2-vs-mixamo-smarter-auto-rigging-for-3d-animators/)
- [MoCap Online — Best Mixamo alternatives 2026](https://mocaponline.com/blogs/mocap-news/mixamo-alternatives)
- [Anything World — official](https://anything.world/)
- [Stable Projectorz — official](https://stableprojectorz.com/)
- [StableGen — Blender add-on (GitHub)](https://github.com/sakalond/StableGen)
- [Exoside — Quad Remesher official](https://exoside.com/)
- [Exoside Quad Remesher v1.3.0 (3ds Max 2025–2026)](https://gfx-hub.co/plugins/3ds-max-addons/140169-exoside-quad-remesher-v130-for-3ds-max-2025-2026-win.html)
- [RetopoFlow — official docs](https://docs.retopoflow.com/)
- [RetopoFlow 4.1.5/4.1.6 release notes](https://www.cgchannel.com/2026/04/orange-turbine-releases-retopoflow-4-for-blender/)
- [KIRI Engine — 3DGS to Mesh 2.0](https://www.kiriengine.app/blog/what-is-3dgs-to-mesh)
- [SuGaR — Gaussian to mesh project](https://anttwo.github.io/sugar/)
- [Splatware — Gaussian Splatting in Blender 5](https://splatware.com/learn/gaussian-splatting-blender)
- [Sketchfab — Creative Commons licenses intro](https://sketchfab.com/blogs/community/an-introduction-to-creative-commons-licenses/)
- [Sketchfab — license agreement](https://sketchfab.com/licenses)
- [Poly Haven — license (CC0)](https://polyhaven.com/license)
- [US Copyright Office — AI policy guidance PDF](https://www.copyright.gov/ai/ai_policy_guidance.pdf)
- [Morgan Lewis — Supreme Court denies cert in Thaler (March 2026)](https://www.morganlewis.com/pubs/2026/03/us-supreme-court-declines-to-consider-whether-ai-alone-can-create-copyrighted-works)
- [Mayer Brown — Supreme Court denies review in AI authorship case](https://www.mayerbrown.com/en/insights/publications/2026/03/supreme-court-denies-review-in-ai-authorship-case)
- [Norton Rose Fulbright — AI copyright cases update 2026](https://www.nortonrosefulbright.com/en/knowledge/publications/ce8eaa5f/ai-in-litigation-series-an-update-on-ai-copyright-cases-in-2026)
- [Bochner PLLC — beyond training data, the shifting battleground](https://www.bochner.law/news/publications/2026-04-10-beyond-the-training-data-the-shifting-battleground-in-ai-copyright-law)
- [Scalevise — EU AI Act 2026 training data and copyright](https://scalevise.com/resources/eu-ai-act-2026-changes/)
- [European Commission — GPAI training-content disclosure template](https://digital-strategy.ec.europa.eu/en/faqs/template-general-purpose-ai-model-providers-summarise-their-training-content)
- [WilmerHale — mandatory AI training-data disclosure template](https://www.wilmerhale.com/en/insights/blogs/wilmerhale-privacy-and-cybersecurity-law/european-commission-releases-mandatory-template-for-public-disclosure-of-ai-training-data)
- [Paul Weiss — EU GPAI guidelines & training data template](https://www.paulweiss.com/insights/client-memos/eu-commission-publishes-guidelines-on-general-purpose-ai-obligations-as-well-as-training-data-disclosure-template-further-clarity-as-the-countdown-to-enforcement-begins)
- [Magic Hour — FLUX Kontext vs Midjourney v7 (2026)](https://magichour.ai/blog/flux-kontext-vs-midjourney-v7)
- [TechSifted — Midjourney v7 review 2026](https://techsifted.com/reviews/midjourney-review-2026/)

