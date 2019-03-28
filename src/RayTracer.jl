module RayTracer

using Requires

export raytrace
export Vec3, rgb
export SimpleSphere, CheckeredSphere, SimpleCylinder, CheckeredCylinder,
       Triangle
export get_primary_rays

# NOTE: We add the addition function for all the structs in this package. Though it
#       makes no semantic sense to do so it is needed for gradient accumulation.

include("utils.jl")
include("materials.jl")
include("objects.jl")
include("tracer.jl")
include("camera.jl")
include("light.jl")

@init @require Zygote="e88e6eb3-aa80-5325-afca-941959d7151f" include("zygote.jl")

end
