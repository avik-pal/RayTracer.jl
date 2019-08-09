# ------- #
# Objects #
# ------- #

"""
    Object

All primitive objects must be a subtype of this. Currently there are
two primitive objects present, [`Triangle`](@ref) and [`Sphere`](@ref).
To add support for custom primitive type, two functions need to be
defined - [`intersect`](@ref) and [`get_normal`](@ref).
"""
abstract type Object end

"""
    get_color(obj::Object, pt::Vec3, sym::Val)

Computes the color at the point `pt` of the Object `obj` by dispatching
to the correct `get_color(obj.material, pt, sym, obj)` method.
"""
get_color(obj::Object, pt::Vec3, sym::Val) =
    get_color(obj.material, pt, sym, obj)

"""
    specular_exponent(obj::Object)

Returns the `specular_exponent` of the material of the Object.
"""
specular_exponent(obj::Object) = specular_exponent(obj.material)

"""
    reflection(obj::Object)

Returns the `reflection coefficient` of the material of the Object.
"""
reflection(obj::Object) = reflection(obj.material)

"""
    intersect(obj::Object, origin, direction)

Computes the intersection of the light ray with the object.
This function returns the ``t`` value where
``intersection\\_point = origin + t \\times direction``. In case
the ray does not intersect with the object `Inf` is returned.
"""
function intersect(obj::Object, origin, direction) end

"""
    get_normal(obj::Object, pt, direction)

Returns the normal at the Point `pt` of the Object `obj`. 
"""
function get_normal(obj::Object, pt, direction) end

# ----------- #
# - Imports - #
# ----------- #

include("objects/sphere.jl")
include("objects/triangle.jl")
include("objects/polygon_mesh.jl")
include("objects/obj_parser.jl")
