---
id: example-copilot-extract-bodice
worker_class: copilot
mcp_lock_required: false
writes_tracked_source: true
priority: 3
estimated_minutes: 12
created_at: 20260510T051600Z
status: example
inputs:
  - scripts/create_dark_fantasy_lady_blockout.py
outputs:
  - scripts/parts/__init__.py
  - scripts/parts/bodice.py
  - outputs/nocturne_matriarch_blockout.blend
depends_on: []
---

# Task

Extract the bodice construction (the `black steel bodice` cone, `gold waist
cincher` cylinder, and any directly bodice-attached pieces such as the front
crimson chest focus gem) from `scripts/create_dark_fantasy_lady_blockout.py`
into a new module `scripts/parts/bodice.py`. Define a function:

```python
def build_bodice(material_steel, material_gold, material_gem) -> list[bpy.types.Object]:
    ...
```

that creates and returns the three Blender objects. Update the main script to
import and call this function in place of the inlined cone/cylinder/sphere
calls. Re-run the regeneration command (see Verification) and confirm the
existing `.blend` is reproduced.

## Conventions

- Naming: keep the existing object names verbatim ("black steel bodice",
  "gold waist cincher", "crimson chest focus") so downstream tickets find them
  by name.
- Helper signature: pass materials in, do not look them up by name from inside
  `build_bodice` — keep it pure-construction.
- All paths via `pathlib.Path` from `__file__`. No hardcoded absolutes.
- `scripts/parts/__init__.py` should re-export `build_bodice`.
- Do not modify `clear_scene`, `setup_scene`, `add_ground`, or any other helper.
- Do not refactor the other body parts in this ticket — only the bodice cluster.

## Verification

```bash
blender --background --factory-startup --enable-autoexec \
  --python-exit-code 2 \
  --python scripts/create_dark_fantasy_lady_blockout.py
```

Must exit 0 and produce both `outputs/nocturne_matriarch_blockout.blend` and
`outputs/renders/nocturne_matriarch_blockout.png`. Visual diff against the
prior render is not automated — orchestrator inspects manually.

## Notes

This is the canonical "promote inline construction to a parts module" pattern.
Future tickets will repeat for each costume cluster (collar, pauldrons, skirt,
greaves, hair, crown). Keep the pattern stable.
