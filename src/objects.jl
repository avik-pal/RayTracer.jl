# ------- #
# Objects #
# ------- #

# NOTE: All objects **MUST** have the material field
abstract type Object end

diffusecolor(obj::O, pt::Vec3) where {O<:Object} = diffusecolor(obj.material, pt)

# ----------- #
# - Imports - #
# ----------- #

include("objects/sphere.jl")
include("objects/cylinder.jl")
include("objects/triangle.jl")
include("objects/disc.jl")
include("objects/polygon_mesh.jl")
