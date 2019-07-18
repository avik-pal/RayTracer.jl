```@meta
CurrentModule = RayTracer
```

# Differentiation

The recommended mode of differentation is by Automatic Differentiation using [Zygote](https://github.com/FluxML/Zygote.jl).
Refer to the [Zygote docs](http://fluxml.ai/Zygote.jl/dev/#Taking-Gradients-1) docs for this. The API listed below
is for numerical differentiation and is very restrictive (and unstable) in its current form. It should only be used as a
validation for the gradients from Zygote.

```@index
Pages = ["differentiation.md"]
```

## Documentation

```@docs
ngradient
numderiv
```
