# RayTracer : Differentiable Ray Tracing in Julia

```@raw html
<p align="center">
    <video width="512" height="320" autoplay loop>
        <source src="./assets/udem1.webm" type="video/webm">
    </video> 
</p>
```

RayTracer.jl is a library for differentiable ray tracing. It provides utilities for

1. Render complex 3D scenes.
2. Differentiate the Ray Tracer wrt arbitrary scene parameters for Gradient Based
   Inverse Rendering.
                                                                      
## Installation

Download [Julia 1.0](https://julialang.org/) or later. 

For the time being, the library is under active development and hence is not registered. But the
master branch is pretty stable for experimentation. To install it simply open a julia REPL and 
do `] add RayTracer`.

The master branch will do all computation on CPU. To try out the experimental GPU support do
`] add RayTracer#ap/gpu`. To observe the potential performance
gains of using GPU you will have to render scenes having more number of objects and the 2D
image must be of reasonably high resolution.

!!! note
    Only rendering is currently supported on GPUs. Gradient Computation is broken but
    will be supported in the future.
    
## Supporting and Citing

This software was developed as part of academic research. If you would like to help support it, please star the repository. If you use this software as part of your research, teaching, or other activities, we would be grateful if you could cite:

```
@misc{pal2019raytracerjl,
    title={{RayTracer.jl: A Differentiable Renderer that supports Parameter Optimization for Scene Reconstruction}},
    author={Avik Pal},
    year={2019},
    eprint={1907.07198},
    archivePrefix={arXiv},
    primaryClass={cs.GR}
}
```

## Contribution Guidelines

This package is written and maintained by [Avik Pal](https://avik-pal.github.io). Please fork and
send a pull request or create a [GitHub issue](https://github.com/avik-pal/RayTracer.jl/issues) for
bug reports. If you are submitting a pull request make sure to follow the official
[Julia Style Guide](https://docs.julialang.org/en/v1/manual/style-guide/index.html) and please use
4 spaces and NOT tabs.

### Adding a new feature

* For adding a new feature open a Github Issue first to discuss about it.

* Please note that we try and avoid having many primitive objects. This might speed up 
  rendering in some rare cases (as most objects will end up being represented as [`Triangle`](@ref)s)
  but is really painful to maintain in the future.

* If you wish to add rendering algorithms it needs to be added to the `src/renderers` directory.
  Ideally we wish that this is differentiable but we do accept algorithms which are not differentiable
  (simply add a note in the documentation).

* Any new type that is defined should have a corresponding entry in `src/gradients/zygote.jl`. Look
  at existing types to understand how it is done. Note that it is a pretty ugly thing to do and
  becomes uglier as the number of fields in your struct increases, so do not define something that has
  a lot of fields unless you need it (see [`Material`](@ref)).

* If you don't want a field in your custom type to be not updated while inverse rendering create a
  subtype of [`RayTracer.FixedParams`](@ref) and wrap those field in it and store it in your custom type.

### Adding a tutorial/example

* We use Literate.jl to convert `examples` to `markdown` files. Look into its
  [documentation](https://fredrikekre.github.io/Literate.jl/stable/)

* Next use the following commands to convert he script to markdown

```
julia> using Literate

julia> Literate.markdown("examples/your_example.jl", "docs/src/getting_started/",
                         documenter = false)
```

* Add an entry to `docs/make.jl` so that it is available in the side navigation bar.

* Add an entry to the `docs/src/index.md` [Contents](@ref) section.

## Contents

### Home

```@contents
Pages = [
    "index.md"
]
Depth = 2
```

### Getting Started Tutorials

```@contents
Pages = [
    "getting_started/teapot_rendering.md",
    "getting_started/inverse_lighting.md",
    "getting_started/optim_compatibility.md"
]
Depth = 2
```

### API Documentation

```@contents
Pages = [
    "api/utilities.md",
    "api/differentiation.md",
    "api/scene.md",
    "api/optimization.md",
    "api/renderers.md",
    "api/accelerators.md"
]
Depth = 2
```

## Index

```@index
```
