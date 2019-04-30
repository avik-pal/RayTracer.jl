# RayTracer.jl

A Differentiable Ray Tracer written in Julia.

## Installation

The package is currently not registered. So open up a Julia 1.\* repl and enter the pkg mode.

```julia
] add https://github.com/avik-pal/RayTracer.jl
```

For being able to use the differentiable aspects of the package install Zygote.

```julia
] add Zygote
```

## Minimum Usage Examples

### Rendering a Simple Scene

First we define the scene parameters

```julia
using RayTracer, Images

# The dimensions of the screen
screen_size = (w = 400, h = 300)

# The source of light. Currently we support presence of only one light source
# but this will change shortly in the future where you wll be allowed to have
# multiple sources of light.
light = PointLight(Vec3(1.0f0), 20.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

# Eye position is essentially the position of the camera. We infer the direction
# of the primary rays from this, the screen size and the field of view.
eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

# Now we define the objects in the scene. Currently we support only a small number
# objects. To know about all the objects look up the API Documentation.
scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, color = rgb(0.0f0, 0.0f0, 1.0f0)),
    SimpleSphere(Vec3(-0.75f0, 0.1f0, 2.25f0), 0.6f0, color = rgb(0.5f0, 0.223f0, 0.5f0)),
    SimpleSphere(Vec3(-2.75f0, 0.1f0, 3.5f0), 0.6f0, color = rgb(1.0f0, 0.572f0, 0.184f0)),
    CheckeredSphere(Vec3(0.0f0, -99999.5f0, 0.0f0), 99999.0f0,
                    color1 = rgb(0.0f0, 1.0f0, 0.0f0),
                    color2 = rgb(0.0f0, 0.0f0, 1.0f0), reflection = 0.25f0)
    ]

# Finally we use a convenience function to get the direction vectors and the
# origin (in this case it is the eye_pos)
origin, direction = get_primary_rays(Float32, 400, 300, 90, eye_pos)
```

The only thing now left to do is to render the scene.
```julia
color = raytrace(origin, direction, scene, light, eye_pos, 0)
```

Finally we save this image
```julia
proper_shape(a) = clamp.(reshape(a, screen_size.w, screen_size.h), 0.0f0, 1.0f0)

col1 = proper_shape(color.x)
col2 = proper_shape(color.y)
col3 = proper_shape(color.z)

im_arr = permutedims(cat(col1, col2, col3, dims = 3), (3, 2, 1))

img = colorview(RGB, im_arr)

save("simple_spheres_scene.jpg", img)
```

If all went well then the following image should have been produced

![simple_spheres_scene](https://raw.githubusercontent.com/avik-pal/RayTracer.jl/master/assets/simple_spheres_scene.jpg)

Now you know everything there is to know about rendering using RayTracer :P. For rendering more
interesting scenes you just need to vary the parameters of the above example.

### Gradient Based Optimization of Scene Parameters

**Work in Progress**

## API Documentation

**Work in Progress**
