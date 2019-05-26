# API Documentation

```@meta
CurrentModule = RayTracer
```

## General Utilities

List of the General Functions and Types provided by the RayTracer. Most of the other functionalities
are built upon these.

```@autodocs
Modules = [RayTracer]
Pages = ["utils.jl",
         "imutils.jl"]
Order = [:type,
         :macro,
         :function]
```

```@docs
get_params
set_params!
```

## Differentiation

The recommended mode of differentation is by Automatic Differentiation using [Zygote](https://github.com/FluxML/Zygote.jl).
Refer to the `Zygote` docs for this. The API listed below is for numerical differentiation and is very
restrictive in its current form.

```@docs
ngradient
numderiv
```

## Scene Configuration

### Camera

```@autodocs
Modules = [RayTracer]
Pages = ["camera.jl"]
Order = [:type,
         :macro,
         :function]
```

### Light

```@autodocs
Modules = [RayTracer]
Pages = ["light.jl"]
Order = [:type,
         :macro,
         :function]
```

### Materials
```@autodocs
Modules = [RayTracer]
Pages = ["material.jl"]
Order = [:type,
         :macro,
         :function]
```

### Objects

```@autodocs
Modules = [RayTracer]
Pages = ["sphere.jl",
         "triangle.jl",
         "cylinder.jl",
         "disc.jl",
         "polygon_mesh.jl",
         "objects.jl"]
Order = [:type,
         :macro,
         :function]
```

## Renderers

```@autodocs
Modules = [RayTracer]
Pages = ["blinnphong.jl"]
Order = [:type,
         :macro,
         :function]
```

## Optimization

```@autodocs
Modules = [RayTracer]
Pages = ["optimize.jl"]
Order = [:type,
         :macro,
         :function]
```

