# RayTracer.jl

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

## CURRENT ROADMAP

These are not listed in any particular order

- [X] Add more types of common objects - Disc, Plane, Box
- [ ] Add support for rendering arbitrary mesh (a proof of concept version is present in `master`
  but is very slow)
- [ ] GPU Support using CuArrays (partially supported in `ap/gpu` branch)
- [ ] Inverse Rendering Examples
- [ ] Application in Machine Learning Models through Flux
