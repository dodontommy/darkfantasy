---
name: blender-character-director
description: Use when designing, generating, or reviewing original Blender fantasy characters, especially dark fantasy humanoids. Applies concept-brief discipline, originality checks, silhouette-first modeling, Blender CLI validation, and staged character pipeline guidance.
---

# Blender Character Director

## Workflow

1. Restate the character target in one paragraph: archetype, silhouette, material palette, intended use, and what existing IP must not be copied.
2. Lock silhouette before details. Generate or request front, side, and three-quarter checks.
3. Keep body, hair, armor, cloth, jewelry, weapons, rig, lights, and cameras as separately named objects/collections.
4. Use Blender CLI for reproducible generation and validation:

```bash
blender --background --python-exit-code 1 --python scripts/<script>.py
```

5. Do not retopologize until the silhouette and major costume layers are approved.

## Style Rules

- Prefer elegant high-fantasy shapes: vertical silhouette, high collar, angular pauldrons, layered cloth, ceremonial metalwork.
- Avoid direct copies of named game characters, armor sets, logos, crests, or unique silhouettes.
- Use varied dark palettes: blackened steel, tarnished gold, deep wine, muted emerald, ivory/bone, ash leather.
- Make the character readable at thumbnail size before adding filigree.

## Quality Gates

- Originality: inspired by genre language, not a replica.
- Readability: pose and silhouette identify role from a distance.
- Modularity: costume pieces are independently editable.
- Production readiness: scale applied, object names meaningful, final deforming meshes avoid ngons.
- Validation: save a `.blend` and produce at least one preview render.
