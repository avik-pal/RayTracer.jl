```@meta
CurrentModule = RayTracer
```

# Optimization

One of the primary use cases of RayTracer.jl is to solve the Inverse Rendering Problem. In this problem, we
try to predict the 3D scene given a 2D image of it. Since, "truly" solving this problem is very difficult,
we focus on a subproblem where we assume that we have partial knowledge of the 3D scene and now using this
image we need to figure out the correct remaining parameters. We do this by iteratively optimizing the parameters
using the gradients obtained with the [Differentiation](@ref) API.

We describe the current API for optimizing these parameters below.

```@index
Pages = ["api/optimization.md"]
```

## Documentation

```@autodocs
Modules = [RayTracer]
Pages = ["optimize.jl"]
```
