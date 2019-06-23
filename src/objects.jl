# ------- #
# Objects #
# ------- #

# NOTE: All objects **MUST** have the material field
abstract type Object end

get_color(obj::Object, pt::Vec3, sym::Val) =
    get_color(obj.material, pt, sym, obj)

specular_exponent(obj::Object) = specular_exponent(obj.material)

reflection(obj::Object) = reflection(obj.material)

# ----------- #
# - Imports - #
# ----------- #

# include("objects/sphere.jl")
# include("objects/cylinder.jl")
include("objects/triangle.jl")
# include("objects/disc.jl")
# include("objects/polygon_mesh.jl")
