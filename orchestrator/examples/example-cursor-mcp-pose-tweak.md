---
id: example-cursor-mcp-pose-tweak
worker_class: cursor-mcp
mcp_lock_required: true
writes_tracked_source: false
priority: 3
estimated_minutes: 8
created_at: 20260510T051600Z
status: example
inputs:
  - outputs/nocturne_matriarch_blockout.blend
outputs:
  - outputs/renders/pose_threequarter_v1.png
depends_on: []
---

# Task

The orchestrator-loaded GUI Blender already has the Nocturne Matriarch blockout
open. Use the Blender MCP to:

1. `get_scene_info` — confirm the scene is the blockout and lights/camera exist.
2. Adjust the camera to a three-quarter angle: rotate around Z by 30° (positive),
   keep height at z=2.05, distance ~7.5 from origin in XY.
3. Lower the global Cycles sample count to 24 (faster preview).
4. Render with output to `outputs/renders/pose_threequarter_v1.png`.
5. Take a `get_viewport_screenshot` and embed any observations in the Promotion
   block as comments.

## Conventions

- Do not edit any object's mesh or transform other than the camera and render
  settings.
- All operations must be representable as bpy operations in the Promotion
  block.
- If the camera object's name differs from
  `"full body orthographic preview camera"`, find it by `bpy.context.scene.camera`
  rather than by name.

## Verification

`outputs/renders/pose_threequarter_v1.png` exists and is at least 800×800 pixels.

## Required ending

Emit a `## Promotion` block with the bpy snippet that reproduces the camera +
sample-count edits. The orchestrator will land a follow-up ticket converting
this into `scripts/poses/threequarter_v1.py`.

## Notes

Pose iteration is the canonical use of cursor-mcp: fast visual feedback in the
GUI, then promotion to a tracked script. Never let the iteration end without
promotion — the lock is held during this whole ticket.
