module RayTracer

using Zygote, Flux, Images, FileIO, MeshIO

# Rendering Utilities
include("utils.jl")
include("light.jl")
include("materials.jl")
include("objects.jl")
include("camera.jl")
include("optimize.jl")

# Renderers
include("renderers/blinnphong.jl")

# Image Utilities
include("imutils.jl")

# Differentiable Rendering
include("gradients/zygote.jl")
include("gradients/numerical.jl")

end
