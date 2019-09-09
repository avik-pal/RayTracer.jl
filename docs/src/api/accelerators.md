```@meta
CurrentModule = RayTracer
```

# Acceleration Structures

!!! warning
    This is a Beta Feature and not all things work with this.

```@index
Pages = ["accelerators.md"]
```

## Bounding Volume Hierarchy

Bounding Volume Hierarchy (or BVH) acts like a primitive object, just
like [`Triangle`](@ref) or [`Sphere`](@ref). So we can simply pass a BVH
object into [`raytrace`](@ref) function.

!!! warning
    The backward pass for BVH is currently broken

```@autodocs
Modules = [RayTracer]
Pages = ["bvh.jl"]
```
