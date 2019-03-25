module RayTracer

export raytrace, intersect
export Vec3, rgb, norm
export SimpleSphere, CheckeredSphere, SimpleCylinder, CheckeredCylinder,
       Triangle
export get_primary_rays

include("utils.jl")
include("materials.jl")
include("objects.jl")
include("tracer.jl")
include("camera.jl")

end
