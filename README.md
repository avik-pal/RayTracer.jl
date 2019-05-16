# RayTracer.jl

A Ray Tracer written completely in Julia. This allows us to leverage the AD capablities provided
by Zygote to differentiate through the Ray Tracer.

## INSTALLATION

The package is currently not registered. So open up a Julia 1.1+ repl and enter the pkg mode.

```julia
] add https://github.com/avik-pal/RayTracer.jl
```

## USAGE EXAMPLES

### Rendering a Simple Scene

First we define the scene parameters

```julia
using RayTracer, Images

# The dimensions of the screen
screen_size = (w = 400, h = 300)

# The source of light. This can be replaced by a Vector of Light Sources
# if needed.
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
# `get_image` is available only if you have loaded `Images`.
img = get_image(color, screen_size.w, screen_size.h)

save("spheres1.jpg", img)
```

If all went well then the following image should have been produced

![simple_spheres_scene](https://raw.githubusercontent.com/avik-pal/RayTracer.jl/master/assets/spheres1.jpg)

Now you know everything there is to know about rendering using RayTracer :P. For rendering more
interesting scenes you just need to vary the parameters of the above example.

### Gradient Based Optimization of Scene Parameters

First of all, we start by rendering a scene. (We will demonstrate using only a single object.
To use more objects you just need to follow the previous demonstration)

You will have to install `Zygote` manually for this example to run.

```julia
using RayTracer, Zygote, Statistics, Images

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0f0), 50.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

# Our aim is to change this `light_purturbed` to `light`
light_perturbed = PointLight(Vec3(1.0f0), 40.0f0, Vec3(3.0f0, 3.0f0, -7.0f0))

eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, color = rgb(0.0f0, 0.0f0, 1.0f0)),
    ]

origin, direction = get_primary_rays(Float32, 400, 300, 90, eye_pos)
```

Let us define a convenience function for saving the images

```julia
function create_and_save(color, val)
    img = get_image(color, screen_size.w, screen_size.h)

    save("images/image_$(val).jpg", img)
end
```

Now render and save the ground truth image

```julia
color = raytrace(origin, direction, scene, light, eye_pos, 0)

create_and_save(color, "original")
```

Finally define the loss function (L2 loss in our case) and the optimization loop. We can use any of
the optimizers provided by the Flux Deep Learning Library for optimization.

```julia
function diff(lgt)
    c = color - raytrace(origin, direction, scene, lgt, eye_pos, 0)
    mean(abs2.(c.x)) + mean(abs2.(c.y)) + mean(abs2.(c.z))
end

opt = ADAM(0.0001f0)

l = deepcopy(light_perturbed)

for i in 0:100
    global l
    y, back = Zygote._forward(diff, l)
    println("Loss = $y")
    g = back(1.0f0)[2]
    update!(opt, l, g)
    if i % 10 == 0
        create_and_save(raytrace(origin, direction, scene, l, eye_pos, 0), i)
    end
    display(l)
end
```

So here was a simple demo of a very simple gradient based inverse rendering problem. We optimized for
only a single scene parameter but we can do a lot more cool stuff like joint optimization of
multiple scene parameters.

## API DOCUMENTATION

This part lists the currently available functions and types. To get the full documentation either
look into the source code or use `? <function_name>` in the Julia REPL. (The documentation is still
under construction so some of the functions might still be undocumented. Feel free to open an issue
or reach out to us on the Julia Slack if you need to understand how to use one of those functions.)

### Types

* Vec3 
* Objects - Sphere, Triangle, Cylinder, Disc
* Light Sources - PointLight, DistantLight
* Surface Color - PlainColor, CheckeredSurface
* Material                                                            

### Functions

#### Exported Functions

* get\_primary\_rays
* raytrace
* SimpleSphere, CheckeredSphere
* SimpleCylinder, CheckeredCylinder
* Triangle
* Disc
* numderiv

#### Internal Functions

You should not bother about these functions unless you are trying to add a new type to
RayTracer.

* get\_shading\_info
* get\_direction, get\_intensity
* diffuse\_color
* light
* get\_normal, intersect
* get\_image
* ngradient, get\_params, set\_params!

## CURRENT ROADMAP

These are not listed in any particular order

- [ ] Add more types of common objects - Disc, Plane, Box.
- [ ] Add support for rendering arbitrary mesh.
- [ ] GPU Support using CuArrays
- [ ] Inverse Rendering Examples
- [ ] Application in Machine Learning Models through Flux
