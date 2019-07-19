# Inverse Lighting Tutorial

In this tutorial we shall explore the inverse lighting problem.
Here, we shall try to reconstruct a target image by optimizing
the parameters of the light source (using gradients).

```julia
using RayTracer, Images, Zygote, Flux, Statistics
```

## Configuring the Scene

Reduce the screen_size if the optimization is taking a bit long

```julia
screen_size = (w = 300, h = 300)
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

## [Ground Truth Image](@id inv_light)

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
position) and try to get back the image in [Ground Truth Image](@ref inv_light)

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

We shall store the images in `results_inv_lighting` directory

```julia
mkpath("results_inv_lighting")

save("./results_inv_lighting/inv_light_original.png",
     showimg(zeroonenorm(render(light_gt, scene))))
save("./results_inv_lighting/inv_light_initial.png",
     showimg(zeroonenorm(render(light_guess, scene))))
```

## Optimization Loop

We will use the ADAM optimizer from Flux. (Try experimenting with other
optimizers as well). We can also use frameworks like Optim.jl for optimization.
We will show how to do it in a future tutorial

```julia
for i in 1:401
    loss, back_fn = Zygote.forward(light_guess) do L
        sum((render(L, scene) .- target_img) .^ 2)
    end
    @show loss
    gs = back_fn(1.0f0)
    update!(opt, light_guess.intensity, gs[1].intensity)
    update!(opt, light_guess.position, gs[1].position)
    if i % 5 == 1
        save("./results_inv_lighting/iteration_$i.png",
             showimg(zeroonenorm(render(light_guess, scene))))
    end
end
```

If we generate a `gif` for the optimization process it will look similar to this
```@raw html
<p align="center">
     <img width=300 height=300 src="../../assets/inv_lighting.gif">
</p>
```

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

