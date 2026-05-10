import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = Path(__file__).resolve().parent
OUT_DIR = ROOT / "outputs"
RENDER_DIR = OUT_DIR / "renders"
BLEND_PATH = OUT_DIR / "nocturne_matriarch_blockout.blend"
RENDER_PATH = RENDER_DIR / "nocturne_matriarch_blockout.png"

if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from parts import build_bodice


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


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


def add_uv_sphere(name, loc, scale, material, segments=32, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return obj


def add_cube(name, loc, scale, material):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("soft bevels", "BEVEL")
    bevel.width = 0.035
    bevel.segments = 2
    return obj


def add_cone(name, loc, radius1, radius2, depth, material, vertices=32):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=loc,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return obj


def add_cylinder(name, loc, radius, depth, material, vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return obj


def rotate(obj, x=0, y=0, z=0):
    obj.rotation_euler = (math.radians(x), math.radians(y), math.radians(z))
    return obj


def build_character():
    skin = mat("pale ivory skin", (0.72, 0.62, 0.56, 1), roughness=0.62)
    hair = mat("bone white hair", (0.84, 0.82, 0.76, 1), roughness=0.72)
    cloth = mat("deep wine black cloth", (0.08, 0.012, 0.025, 1), roughness=0.78)
    steel = mat("blackened steel", (0.035, 0.04, 0.046, 1), metallic=1.0, roughness=0.26)
    gold = mat("tarnished gold trim", (0.74, 0.52, 0.19, 1), metallic=1.0, roughness=0.34)
    gem = mat("crimson focus gem", (0.95, 0.02, 0.035, 1), roughness=0.12, emission=(0.95, 0.02, 0.04, 1), strength=0.7)

    collection = bpy.data.collections.new("Nocturne Matriarch Blockout")
    bpy.context.scene.collection.children.link(collection)

    parts = []
    parts.append(add_uv_sphere("head", (0, 0, 3.55), (0.22, 0.18, 0.28), skin))
    parts.append(add_cylinder("long neck", (0, 0, 3.17), 0.085, 0.48, skin, 24))
    parts.append(add_uv_sphere("torso base", (0, 0, 2.55), (0.38, 0.22, 0.58), skin))
    parts.append(add_uv_sphere("hip base", (0, 0, 1.83), (0.42, 0.24, 0.28), skin))

    parts.extend(build_bodice(steel, gold, gem))

    parts.append(add_uv_sphere("left pauldron", (-0.47, 0, 2.93), (0.24, 0.16, 0.13), steel))
    parts.append(add_uv_sphere("right pauldron", (0.47, 0, 2.93), (0.24, 0.16, 0.13), steel))
    left_spike = add_cone("left pauldron spike", (-0.67, 0.01, 3.02), 0.055, 0.0, 0.46, gold, 16)
    right_spike = add_cone("right pauldron spike", (0.67, 0.01, 3.02), 0.055, 0.0, 0.46, gold, 16)
    parts.extend([rotate(left_spike, 0, 82, 0), rotate(right_spike, 0, -82, 0)])

    for side, sx in [("left", -1), ("right", 1)]:
        upper = add_cylinder(f"{side} upper arm", (sx * 0.58, 0, 2.42), 0.065, 0.62, skin, 20)
        lower = add_cylinder(f"{side} forearm gauntlet", (sx * 0.69, 0, 1.89), 0.075, 0.55, steel, 20)
        hand = add_uv_sphere(f"{side} hand", (sx * 0.76, -0.01, 1.55), (0.07, 0.045, 0.09), skin, 16, 8)
        parts.extend([rotate(upper, 0, 0, sx * 10), rotate(lower, 0, 0, sx * -8), hand])

    skirt = add_cone("split dark skirt mass", (0, 0, 1.15), 0.58, 0.24, 1.35, cloth, 48)
    parts.append(skirt)
    for side, sx in [("left", -1), ("right", 1)]:
        panel = add_cube(f"{side} front skirt panel", (sx * 0.18, -0.17, 1.15), (0.13, 0.035, 0.68), cloth)
        parts.append(rotate(panel, 0, 0, sx * 4))
        leg = add_cylinder(f"{side} black greave", (sx * 0.2, 0.02, 0.52), 0.095, 0.95, steel, 24)
        parts.append(leg)

    collar = add_cone("high raven collar", (0, 0.06, 3.05), 0.44, 0.18, 0.62, cloth, 48)
    parts.append(rotate(collar, 180, 0, 0))
    back_hair = add_cone("long white hair sheet", (0, 0.18, 2.65), 0.28, 0.12, 1.72, hair, 32)
    parts.append(rotate(back_hair, 8, 0, 0))

    crown_center = add_cone("central crown spear", (0, -0.015, 4.05), 0.045, 0.0, 0.68, gold, 18)
    parts.append(crown_center)
    for side, sx in [("left", -1), ("right", 1)]:
        horn = add_cone(f"{side} crown horn", (sx * 0.18, -0.015, 3.98), 0.04, 0.0, 0.62, gold, 18)
        parts.append(rotate(horn, 0, sx * 22, 0))

    for obj in parts:
        for old in obj.users_collection:
            old.objects.unlink(obj)
        collection.objects.link(obj)


def setup_scene():
    bpy.context.scene.render.engine = "CYCLES"
    bpy.context.scene.cycles.samples = 32
    bpy.context.scene.cycles.use_denoising = False
    bpy.context.scene.render.resolution_x = 1400
    bpy.context.scene.render.resolution_y = 1800
    bpy.context.scene.view_settings.view_transform = "Filmic"
    bpy.context.scene.view_settings.look = "Medium High Contrast"
    bpy.context.scene.world.color = (0.015, 0.016, 0.019)

    bpy.ops.object.light_add(type="AREA", location=(-2.4, -3.5, 4.2))
    key = bpy.context.object
    key.name = "large softbox key"
    key.data.energy = 550
    key.data.size = 4.0

    bpy.ops.object.light_add(type="POINT", location=(1.8, 1.6, 2.7))
    rim = bpy.context.object
    rim.name = "small red rim"
    rim.data.energy = 95
    rim.data.color = (0.9, 0.05, 0.04)

    bpy.ops.object.camera_add(location=(0, -7.5, 2.05), rotation=(math.radians(90), 0, 0))
    camera = bpy.context.object
    bpy.context.scene.camera = camera
    camera.name = "full body orthographic preview camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 4.75


def add_ground():
    ground_mat = mat("matte charcoal floor", (0.02, 0.022, 0.024, 1), roughness=0.9)
    bpy.ops.mesh.primitive_plane_add(size=4.0, location=(0, 0, -0.02))
    ground = bpy.context.object
    ground.name = "charcoal floor"
    ground.data.materials.append(ground_mat)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    clear_scene()
    build_character()
    add_ground()
    setup_scene()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    bpy.context.scene.render.filepath = str(RENDER_PATH)
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
