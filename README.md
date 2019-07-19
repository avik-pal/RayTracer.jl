# RayTracer.jl

[![Build Status](https://travis-ci.com/avik-pal/RayTracer.jl.svg?branch=master)](https://travis-ci.com/avik-pal/RayTracer.jl)
[![codecov](https://codecov.io/gh/avik-pal/RayTracer.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/avik-pal/RayTracer.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/887v1miv7ig4mod2?svg=true)](https://ci.appveyor.com/project/avik-pal/raytracer-jl) 
[![Latest Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://avik-pal.github.io/RayTracer.jl/dev/)

**NOTE**: For the latest version and documentation please use the `review_updates` branch. It
contains a set of getting started examples.

A Ray Tracer written completely in Julia. This allows us to leverage the AD capablities provided
by Zygote to differentiate through the Ray Tracer.

## INSTALLATION

The package is currently not registered. So open up a Julia 1.1+ repl and enter the pkg mode.

```julia
] add https://github.com/avik-pal/RayTracer.jl
```

For GPU Support

```julia
] add https://github.com/avik-pal/RayTracer.jl#ap/gpu
```

## USAGE EXAMPLES

For usage examples look into the `examples` directory. Also the documentation has some getting
started examples.

[Duckietown.jl](https://github.com/tejank10/Duckietown.jl) uses RayTracer.jl for generating renders
of a self-driving car environment. For more complex examples of RayTracer, checkout that project.

## CURRENT ROADMAP

These are not listed in any particular order

- [X] Add more types of common objects (use mesh rendering for this) - Disc, Plane, Box
- [X] Add support for rendering arbitrary mesh
  but is slow)
- [ ] GPU Support using CuArrays (partially supported in `ap/gpu` branch)
- [ ] Inverse Rendering Examples
- [ ] Application in Machine Learning Models through Flux
- [X] Texture Rendering
- [ ] Make everything differentiable:
  - [ ] Triangle Mesh
