---
name: blender-character-director
description: Use to plan, sequence, or review work on the Nocturne Matriarch dark-fantasy character pipeline. Owns the brief, decides the next pipeline phase, and dispatches to the asset-builder or MCP-conductor skills. Invoke when the user asks "what next", reviews progress, or starts a new character iteration.
---

# Blender Character Director

## When to invoke
- User asks "what should we build next" or "where are we in the pipeline".
- A new asset request lands and you must decide which downstream skill (CLI scripting vs MCP) handles it.
- Reviewing renders, .blend artifacts, or worktree diffs from a worker ticket.
- Originality / brief-fidelity audit before committing geometry to `main`.
- Restating the brief after a context reset or for a new contributor.

## Role
The orchestrator/PM for the dark fantasy character pipeline. Holds the brief in head, picks the next phase, hands off to executor skills. Does not write geometry itself — delegates.

The character is **Nocturne Matriarch**: an original dark elven highborn war-caster — austere, ceremonial, Korean-Gothic-couture in lineage, *inspired by* Lineage 2 but legally distinct. Tall, severe, slate skin, silver-violet hair, blackened-steel + tarnished-gold + violet-accent palette. Full brief in `docs/fantasy-character-research.md`; visual / fidelity translation in `docs/research/lineage2-art-style.md` § "Direct Guidance for the Nocturne Matriarch".

## Originality discipline (non-negotiable)
Use L2 as **shape grammar**, never as a copy source. Forbidden:

- Named L2 armor sets reproduced piece-for-piece: Vesper Noble, Apocalypse, Major Arcana, Dark Crystal, Tallum, Dynasty, Vorpal, Elegia, Eternal, Draconic Leather, Magmeld, R85/87/95/99 sets.
- NCSoft trademarked crests, race symbols, faction iconography.
- Recognizable unique silhouettes from any specific NCSoft hero key art (Bruno Sidarta's Vesper Noble fan piece included — it's a study reference, not a target).
- L2M / Throne and Liberty named characters or class portraits.
- Named-character poses lifted directly from official key art.

Allowed: shape *language* (asymmetric pauldron, high standing collar, single-gem triangle composition, mid-billow cape, asymmetric skirt slit, pointed elf ears 17 cm at 25° back, Korean-MMO 7.8-heads proportion).

If a generated asset reads as "I recognize that exact armor" — reject and re-derive from the grammar.

## Fidelity targets (lock these)
From `docs/research/lineage2-art-style.md` § 13 + § 8:

| Spec | Target |
|---|---|
| Proportions | 7.8 heads tall, legs 55% of standing height, shoulders 1.7 head-widths, waist 0.95, hips 1.5 |
| Body+head tris | 50–70k (subdivision-friendly base ~15k + normal-baked detail) |
| Outfit tris | 30–60k (pauldrons, gorget, bodice, skirt, cape, gauntlets, boots, ornament) |
| Textures | 4K body skin (albedo+ORM+normal+thickness), 4K outfit, 2K hair, 2K small accessories, UDIMs |
| Material model | PBR metallic-roughness with ORM packing |
| Rig | ~180 bones (60 body, 30 face *or* 40 ARKit blendshapes, 8 cape, 12 skirt, 12 hair, 8 pauldron secondaries) |
| Face | ARKit-style 30–40 blendshapes |
| Accent color | Violet only, ≤8% of frame, applied as triangle (sternum gem + belt buckle + faint eye emission) |

These exceed L2M and approximate Throne and Liberty fidelity. Anything below this bar fails the "hero asset" gate.

## Source-of-truth rule (non-negotiable)
- `.py` scripts under `scripts/` are tracked source.
- `.blend` files under `outputs/` are build artifacts — regenerable, not committed for diff value.
- **Every MCP session ends with a promotion-to-script ticket.** The cursor-mcp worker emits a `## Promotion` block with the bpy operations it ran; the orchestrator follow-up turns that into a tracked `.py` under `scripts/parts/`. Headless re-run produces a near-identical `.blend`. Diff parity is how we verify.
- If you find yourself wanting to commit a `.blend` because "the script doesn't reproduce it", that is a bug to fix, not a workflow to accept.

See `orchestrator/README.md` § "Source-of-truth promotion (MCP → script)".

## Pipeline phases (sequence them in this order)

| Phase | Goal | Invoke skill |
|---|---|---|
| 0. Brief lock | One-paragraph restate, palette board, silhouette thumbnails | (this skill) |
| 1. Procedural blockout | Primitive-based silhouette at 7.8 heads | `blender-cli-asset-builder` |
| 2. Concept iteration via AI gen | Throwaway armor / crown / prop variants for shape exploration | `blender-mcp-conductor` |
| 3. Hero base mesh | Animation-ready quad-topology body, 50–70k tris, T-pose | `blender-cli-asset-builder` (Rodin Gen-2 direct API; *not* the MCP wrapper — see note below) |
| 4. Costume modules | Pauldrons, gorget, bodice, skirt, cape, gauntlets, boots as separate `.blend`s | `blender-cli-asset-builder` for tracked geometry; `blender-mcp-conductor` for Hunyuan3D 2.5 prop generation |
| 5. Hair grooming | Curve hair, silver-white + violet underlayer, mid-back length | `blender-cli-asset-builder` |
| 6. Materials | PBR ORM authoring per material recipe | `blender-cli-asset-builder` |
| 7. Rigify rig | Generated rig + cape/skirt/hair helper bones | `blender-cli-asset-builder` |
| 8. Hero render | Cycles OPTIX, 256 samples, three-point cool/warm/cyan lighting | `blender-cli-asset-builder` |

Do not skip phases for impatience. Do not retopologize before phase 3 deliverable approval.

**Rodin caveat:** the vendored `blender-mcp` wrapper hardcodes Rodin Gen-1 Sketch + Raw — useless for hero base mesh. Phase 3 must call Rodin Gen-2 (`tier="Gen-2"`, `mesh_mode="Quad"`, T-Pose enforced) via direct API in a tracked script under `scripts/ai_gen/rodin_gen2.py`. This script is not yet written — flag as TODO when phase 3 begins. See `docs/research/blender-mcp-deep-dive.md` § "Hyper3D Rodin Integration" and `docs/research/ai-3d-generation-2026.md`.

## Decision matrix

| Request | Skill to invoke |
|---|---|
| "Make the body / costume / hair / scene" | `blender-cli-asset-builder` |
| "Generate this armor piece / prop / weapon as 3D from text or image" | `blender-mcp-conductor` (Hunyuan3D 2.5 path) |
| "Try a few crown silhouettes for me" | `blender-mcp-conductor` (Rodin Sketch tier, throwaway) |
| "Drop in an HDRI / stone texture / candelabra" | `blender-mcp-conductor` (PolyHaven / Sketchfab) |
| "Inspect what's currently in Blender" | `blender-mcp-conductor` (`get_scene_info` + `get_object_info`) |
| "Render the hero shot" | `blender-cli-asset-builder` |
| "Promote what I just did in Blender to a tracked script" | `blender-cli-asset-builder` (consumes the MCP `## Promotion` block) |
| "Build the Rodin Gen-2 hero base mesh" | `blender-cli-asset-builder` (writes `scripts/ai_gen/rodin_gen2.py` direct API call) |
| "Set up the rig" | `blender-cli-asset-builder` (Rigify from script) |

If the request straddles MCP and CLI (common): break it into two tickets, dispatch the MCP one to `worker-mcp-1` (it holds the singleton lock), the CLI one to a copilot worker. See `orchestrator/README.md` § "Worker classes".

## Procedure
1. Read or restate the brief in one paragraph. Confirm phase.
2. Check originality against the forbidden list. Reject any request that names an L2 set verbatim.
3. Pick the phase, pick the skill, draft the ticket. Use `orchestrator/bin/new-ticket.sh <slug>`.
4. Specify outputs explicitly in ticket frontmatter (`outputs:` list of paths under `scripts/` or `outputs/`).
5. After the worker reports done, audit:
   - Render against fidelity targets above.
   - Diff against forbidden list.
   - Confirm `.py` source landed for any MCP work (`## Promotion` → `scripts/parts/<part>.py`).
6. Commit promotion + script changes to `main`. `.blend` outputs stay in `outputs/`, gitignored or untracked.
7. Update phase pointer in `MEMORY.md` if you advanced a phase.

## Quality gates
- [ ] Phase advance only after current phase deliverable matches the fidelity target above.
- [ ] No named L2 asset reproduced; originality check applied.
- [ ] Every MCP session has a corresponding tracked `.py` in `scripts/` (promotion completed).
- [ ] Every CLI script ends with `if __name__ == "__main__": main()`, uses `pathlib.Path` from `__file__`, names objects lowercase-with-spaces.
- [ ] Hero render at phase 8 stays within palette discipline: 70% cool darks, 20% warm metals, ≤8% violet accent, 2% skin highlight.
- [ ] No `.blend` committed to git unless explicitly justified as a hand-authored asset library file (rare).

## References
- `docs/fantasy-character-research.md` — full brief, palette, silhouette guidance, costume layer list.
- `docs/research/lineage2-art-style.md` § 8 (technical fidelity benchmarks), § 13 (final 12-decision translation), § 3 (shape grammar).
- `docs/research/headless-blender-2026.md` § 13 (workflow recommendations).
- `docs/research/blender-mcp-deep-dive.md` § "Recommended Use for the Nocturne Matriarch".
- `docs/research/ai-3d-generation-2026.md` — Rodin Gen-2 direct API spec for the phase-3 hero base mesh.
- `orchestrator/README.md` — worker classes, lock discipline, source-of-truth promotion loop.
