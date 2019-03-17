module RayTracer

export raytrace, intersect
export Vec3, rgb, norm
export SimpleSphere, CheckeredSphere

include("utils.jl")
include("objects.jl")
include("tracer.jl")

end
