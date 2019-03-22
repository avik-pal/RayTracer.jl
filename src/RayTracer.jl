module RayTracer

export raytrace, intersect
export Vec3, rgb, norm
export SimpleSphere, CheckeredSphere, SimpleCylinder, CheckeredCylinder

include("utils.jl")
include("materials.jl")
include("objects.jl")
include("tracer.jl")

end
