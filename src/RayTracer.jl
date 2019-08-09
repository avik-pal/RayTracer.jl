module RayTracer

using Zygote, Flux, Images, Distributed, Statistics
import Base.show

using Compat
import Compat.isnothing

# Rendering Utilities
include("utils.jl")
include("light.jl")
include("materials.jl")
include("objects.jl")
include("camera.jl")
include("optimize.jl")

# Acceleration Structures
include("bvh.jl")

# Renderers
include("renderers/blinnphong.jl")
include("renderers/rasterizer.jl")
include("renderers/accelerated_raytracer.jl")

# Image Utilities
include("imutils.jl")

# Differentiable Rendering
include("gradients/zygote.jl")
include("gradients/numerical.jl")

end
