import bpy


def _add_uv_sphere(
    name: str,
    loc: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    segments: int = 32,
    rings: int = 16,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return obj


def _add_cone(
    name: str,
    loc: tuple[float, float, float],
    radius1: float,
    radius2: float,
    depth: float,
    material: bpy.types.Material,
    vertices: int = 32,
) -> bpy.types.Object:
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


def _add_cylinder(
    name: str,
    loc: tuple[float, float, float],
    radius: float,
    depth: float,
    material: bpy.types.Material,
    vertices: int = 32,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return obj


def build_bodice(
    material_steel: bpy.types.Material,
    material_gold: bpy.types.Material,
    material_gem: bpy.types.Material,
) -> list[bpy.types.Object]:
    bodice = _add_cone("black steel bodice", (0, -0.012, 2.55), 0.36, 0.23, 0.92, material_steel, 48)
    bodice.rotation_euler.z = 3.141592653589793

    waist = _add_cylinder("gold waist cincher", (0, -0.005, 2.08), 0.31, 0.12, material_gold, 48)
    waist.rotation_euler.x = 1.5707963267948966

    focus = _add_uv_sphere(
        "crimson chest focus",
        (0, -0.235, 2.62),
        (0.075, 0.025, 0.105),
        material_gem,
        24,
        12,
    )

    return [bodice, waist, focus]
