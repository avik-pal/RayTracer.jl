# Optimizing Scene Parameters using Optim.jl

In this tutorial we will explore the exact same problem as demonstrated
in [Inverse Lighting Tutorial](@ref) but this time we will use the
Optimization Package [Optim.jl](https://julianlsolvers.github.io/Optim.jl/stable/).
I would recommend going through a few of the
[tutorials on Optim](https://julianlsolvers.github.io/Optim.jl/stable/#user/minimization/#_top)
before starting this one.

If you have already read the previous tutorial, you can safely skip to
[Writing the Optimization Loop using Optim](@ref). The part previous to this
is same as the previous tutorial.

```julia
using RayTracer, Images, Zygote, Flux, Statistics, Optim
```

## Configuring the Scene

If you want a better quality image increase this value but it will slow down the
optimization.

```julia
screen_size = (w = 64, h = 64)
```

Now we shall load the scene using [`load_obj`](@ref) function. For
this we need the `obj` and `mtl` files. This will be downloaded using
the following commands:

```
wget https://raw.githubusercontent.com/tejank10/Duckietown.jl/master/src/meshes/tree.obj
wget https://raw.githubusercontent.com/tejank10/Duckietown.jl/master/src/meshes/tree.mtl
```

```julia
scene = load_obj("./tree.obj")
```

Let us set up the [`Camera`](@ref). For a more detailed understanding of
the rendering process look into [Introduction to rendering using RayTracer.jl](@ref).

```julia
cam = Camera(
    Vec3(0.0f0, 6.0f0, -10.0f0),
    Vec3(0.0f0, 2.0f0,  0.0f0),
    Vec3(0.0f0, 1.0f0,  0.0f0),
    45.0f0,
    0.5f0,
    screen_size...
)

origin, direction = get_primary_rays(cam)
```

We should define a few convenience functions. Since we are going to calculate
the gradients only wrt to `light` we have it as an argument to the function. Having
`scene` as an additional parameters simply allows us to test our method for other
meshes without having to run `Zygote.refresh()` repeatedly.

```julia
function render(light, scene)
    packed_image = raytrace(origin, direction, scene, light, origin, 2)
    array_image = reshape(hcat(packed_image.x, packed_image.y, packed_image.z),
                          (screen_size.w, screen_size.h, 3, 1))
    return array_image
end

showimg(img) = colorview(RGB, permutedims(img[:,:,:,1], (3,2,1)))
```

## [Ground Truth Image](@id optim)

For this tutorial we shall use the [`PointLight`](@ref) source.
We define the ground truth lighting source and the rendered image. We
will later assume that we have no information about this lighting
condition and try to reconstruct the image.

```julia
light_gt = PointLight(
    Vec3(1.0f0, 1.0f0, 1.0f0),
    20000.0f0,
    Vec3(1.0f0, 10.0f0, -50.0f0)
)

target_img = render(light_gt, scene)

showimg(zeroonenorm(render(light_gt, scene)))
```

```@raw html
<p align="center">
    <img width=300 height=300 src="../../assets/inv_light_original.png">
</p>
```

## Initial Guess of Lighting Parameters

We shall make some arbitrary guess of the lighting parameters (intensity and
position) and try to get back the image in [Ground Truth Image](@ref optim)

```julia
light_guess = PointLight(
    Vec3(1.0f0, 1.0f0, 1.0f0),
    1.0f0,
    Vec3(-1.0f0, -10.0f0, -50.0f0)
)

showimg(zeroonenorm(render(light_guess, scene)))
```

```@raw html
<p align="center">
    <img width=300 height=300 src="../../assets/inv_light_initial.png">
</p>
```

## Writing the Optimization Loop using Optim

Since, there is no direct support of Optim (unlike for Flux) in RayTracer
the interface might seem a bit ugly. This is mainly due to the way the
two optimization packages work. Flux allows inplace operation and ideally
even RayTracer prefers that. But Optim requires us to give the parameters
as an `AbstractArray`.

Firstly, we shall extract the parameters, using the [`RayTracer.get_params`](@ref)
function, we want to optimize.

```julia
initial_parameters = RayTracer.get_params(light_guess)[end-3:end]
```

Since the input to the `loss_function` is an abstract array we need to
convert it into a form that the RayTracer understands. For this we
shall use the [`RayTracer.set_params!`](@ref) function which will modify the
parameters inplace.

In this function we simply compute the loss values and print it for our
reference

```julia
function loss_function(θ::AbstractArray)
    light_optim = deepcopy(light_guess)
    RayTracer.set_params!(light_optim.intensity, θ[1:1])
    RayTracer.set_params!(light_optim.position, θ[2:end])
    loss = sum((render(light_optim, scene) .- target_img) .^ 2)
    @show loss
    return loss
end
```

RayTracer uses Zygote's Reverse Mode AD for computing the derivatives.
However, the default in Optim is ForwardDiff. Hence, we need to override
that by giving our own gradient function.

```julia
function ∇loss_function!(G, θ::AbstractArray)
    light_optim = deepcopy(light_guess)
    RayTracer.set_params!(light_optim.intensity, θ[1:1])
    RayTracer.set_params!(light_optim.position, θ[2:end])
    gs = gradient(light_optim) do L
        sum((render(L, scene) .- target_img) .^ 2)
    end
    G .= RayTracer.get_params(gs[1])[end-3:end]
end
```

Now we simply call the `optimize` function with `LBFGS` optimizer.

```julia
res = optimize(loss_function, ∇loss_function!, initial_parameters, LBFGS())

@show res.minimizer
```

One interesting thing to notice is that LBFGS took us to the global minima while
ADAM in the previous tutorial was only able to reach a local minima. Also, the
optimization took only 252 iterations compared to 500 incase of ADAM.

If we generate a `gif` for the optimization process it will look similar to this
```@raw html
<p align="center">
     <img width=300 height=300 src="../../assets/inv_lighting_optim.gif">
</p>
```

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

