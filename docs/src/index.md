# RayTracer : Differentiable Ray Tracing in Julia

```@raw html
<p align="center">
    <img src="./assets/udem1.gif">
</p>
```

RayTracer.jl is a library for differentiable ray tracing. It provides utilities for

1. Render complex 3D scenes.
2. Differentiate the Ray Tracer wrt arbitrary scene parameters for Gradient Based
   Inverse Rendering.
                                                                      
## Installation

Download [Julia 1.1](https://julialang.org/) or later. 

!!! note
    This library won't work with Julia 1.0 as it needs the `isnothing` function.

For the time being, the library is under active development and hence is not registered. But the
master branch is pretty stable for experimentation. To install it simply open a julia REPL and 
do `] add https://github.com/avik-pal/RayTracer.jl`.

The master branch will do all computation on CPU. To try out the experimental GPU support do
`] add https://github.com/avik-pal/RayTracer.jl#ap/gpu`. To observe the potential performance
gains of using GPU you will have to render scenes having more number of objects and the 2D
image must be of reasonably high resolution.

!!! note
    Only rendering is currently supported on GPUs. Gradient Computation is broken but
    will be supported in the future.

## Contents

```@contents
Pages = ["index.md",
         "getting_started/rendering.md",
         "getting_started/optimization.md",
         "api.md"]
Depth = 3
```

## Contributions

This package is written and maintained by [Avik Pal](https://avik-pal.github.io). Please fork and
send a pull request or create a [GitHub issue](https://github.com/avik-pal/RayTracer.jl/issues) for
bug reports or feature requests.

## Index

```@index
```
