module RayTracer

using Requires

export raytrace
export Vec3, rgb
export SimpleSphere, CheckeredSphere, SimpleCylinder, CheckeredCylinder,
       Triangle
export get_primary_rays

include("utils.jl")
include("materials.jl")
include("objects.jl")
include("tracer.jl")
include("camera.jl")

@init @require Zygote="e88e6eb3-aa80-5325-afca-941959d7151f" include("zygote.jl")

end
