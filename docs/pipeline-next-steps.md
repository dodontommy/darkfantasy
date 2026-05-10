# Pipeline Next Steps

## Immediate

1. Generate blockout from `scripts/create_dark_fantasy_lady_blockout.py`.
2. Review front/three-quarter renders for silhouette only.
3. Pick one direction for hair: straight sheet, heavy waves, high ponytail, or crown-backed veil.
4. Pick one costume identity: war-caster, assassin noble, death priestess, or cursed queen.
5. Replace mannequin body with a better humanoid base.

## Skill Ideas

Create these as local Codex skills if this becomes an ongoing workflow:

### `blender-character-director`

Use when planning or reviewing a fantasy character. It should enforce concept brief, originality checks, silhouette/readability, material palette, and quality gates before modeling detail.

### `blender-cli-asset-builder`

Use when generating or validating `.blend` files from Python. It should define folder layout, script conventions, render commands, object naming, and automated sanity checks.

### `dark-fantasy-costume-modeler`

Use when creating armor, cloth, hair, weapons, jewelry, or material variations. It should encode gothic/high-fantasy shape language, layer hierarchy, and material recipes.

### `character-topology-reviewer`

Use when retopology starts. It should check deformation loops, UV readiness, manifold issues, mirrored topology, applied scale, naming, export settings, and rigging risks.

## MCP Plan

Best first experiment:

```json
{
  "mcpServers": {
    "blender": {
      "command": "uvx",
      "args": ["blender-mcp"]
    }
  }
}
```

But only after reviewing the Blender add-on code and deciding which MCP client will host it. For deterministic batch work on this Linux server, use direct `blender --background --python ...` scripts first.
