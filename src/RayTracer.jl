module RayTracer

using Zygote, Flux, Images, Flux3D, CUDA, NNlib
using LinearAlgebra, Statistics
import Base.show

using Flux: @functor

using Compat
import Compat.isnothing

# Rendering Utilities
include("utils.jl")
include("light.jl")

# Exports
## Custom Types
export DirectionalLight, PointLight
## Functions
export compute_diffuse_lighting, compute_specular_lighting
export spherical_to_cartesian

end
