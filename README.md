# RayTracer.jl

[![Build Status](https://travis-ci.com/avik-pal/RayTracer.jl.svg?branch=master)](https://travis-ci.com/avik-pal/RayTracer.jl)
[![codecov](https://codecov.io/gh/avik-pal/RayTracer.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/avik-pal/RayTracer.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/887v1miv7ig4mod2?svg=true)](https://ci.appveyor.com/project/avik-pal/raytracer-jl) 
[![Latest Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://avik-pal.github.io/RayTracer.jl/dev/)

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

Follow the instructions below to run individual code examples or use
`code/script.sh` to run all of them together.

First we need to get the versions of the packages used when these
examples were written.

**NOTE:** We have tested the examples on versions of Julia >= 1.1.
          It is known that the RayTracer won't function in Julia 1.0.

```bash
$ cd code
$ julia --color=yes -e "using Pkg; Pkg.instantiate()"
```

Now we can run any of the file we need by
`julia --project=. --color=yes "/path/to/file"`

### Some specific things for certain examples

1. For the `teapot` rendering we need to download the `obj` file.

`wget https://raw.githubusercontent.com/McNopper/OpenGL/master/Binaries/teapot.obj`

2. For the performance benchmarks:

```bash
$ mkdir meshes
$ cd meshes
$ wget https://raw.githubusercontent.com/avik-pal/RayTracer.jl/ap/texture/test/meshes/sign_yield.obj
$ wget https://raw.githubusercontent.com/avik-pal/RayTracer.jl/ap/texture/test/meshes/sign_yield.mtl1
$ cd ..

$ mkdir textures
$ cd textures
$ wget https://raw.githubusercontent.com/avik-pal/RayTracer.jl/ap/texture/test/textures/wood_osb.jpg
$ wget raw.githubusercontent.com/avik-pal/RayTracer.jl/ap/texture/test/textures/sign_yield.png
$ cd ..
```

This example requires a few arguments to be passes from command line. Chack them using

`julia  --project=. --color=yes "performance_benchmarks.jl" --help`

### Additional Examples

[Duckietown.jl](https://github.com/tejank10/Duckietown.jl) uses RayTracer.jl for generating renders
of a self-driving car environment. For more complex examples of RayTracer, checkout that project.

## JULIACON PAPER

## Build Instructions

```bash
$ cd paper
$ latexmk -bibtex -pdf paper.tex
$ latexmk -c
```

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
