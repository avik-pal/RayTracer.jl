# Introduction to rendering using RayTracer.jl

In this example we will render the famous UTAH Teapot model.
We will go through the entire rendering API. We will load
an obj file for the scene. This needs to be downloaded manually.

Run this code in your terminal to get the file:
`wget https://raw.githubusercontent.com/McNopper/OpenGL/master/Binaries/teapot.obj`

If you are using REPL mode you need the `ImageView.jl` package

```julia
using RayTracer, Images #, ImageView
```

## General Attributes of the Scene

Specify the dimensions of the image we want to generate.
`screen_size` is never passed into the RayTracer directly so it
need not be a named tuple.

```julia
screen_size = (w = 256, h = 256)
```

Load the teapot object from an `obj` file. We can also specify
the scene using primitive objects directly but that becomes a
bit involved when there are complicated objects in the scene.

```julia
scene = load_obj("teapot.obj")
```

We shall define a convenience function for rendering and saving
the images.
For understanding the parameters passed to the individual functions
look into the documentations of [`get_primary_rays`](@ref), [`raytrace`](@ref)
and [`get_image`](@ref)

```julia
function generate_render_and_save(cam, light, filename)
    #src # Get the primary rays for the camera
    origin, direction = get_primary_rays(cam)

    #src # Render the scene
    color = raytrace(origin, direction, scene, light, origin, 2)

    #src # This will reshape `color` into the proper dimensions and return
    #src # an RGB image
    img = get_image(color, screen_size...)

    #src # Display the image
    #src # For REPL mode change this to `imshow(img)`
    display(img)

    #src # Save the generated image
    save(filename, img)
end
```

## Understanding the Light and Camera API

### DistantLight

In this example we will be using the [`DistantLight`](@ref). This king of lighting
is useful when we want to render a scene in which all parts of the scene
receive the same intensity of light.

For the DistantLight we need to provide three attributes:
* Color     - Color of the Light Rays. Must be a Vec3 Object
* Intensity - Intensity of the Light
* Direction - The direction of light rays. Again this needs to be a Vec3 Object

### Camera

We use a perspective view [`Camera`](@ref) Model in RayTracer. Let us look into the
arguments we need to pass into the Camera constructor.

* LookFrom - The position of the Camera
* LookAt   - The point in 3D space where the Camera is pointing
* vup      - The UP vector of the world (typically Vec3(0.0, 1.0, 0.0), i.e. the y-axis)
* vfov     - Field of View of the Camera
* Focus    - The focal length of the Camera
* Width    - Width of the output image
* Height   - Height of the output image

## Rendering Different Views of the Teapot

Now that we know what each argument means let us render the teapot

### TOP VIEW Render

```julia
light = DistantLight(
    Vec3(1.0f0),
    100.0f0,
    Vec3(0.0f0, 1.0f0, 0.0f0)
)

cam = Camera(
    Vec3(1.0f0, 10.0f0, -1.0f0),
    Vec3(0.0f0),
    Vec3(0.0f0, 1.0f0, 0.0f0),
    45.0f0,
    1.0f0,
    screen_size...
)

generate_render_and_save(cam, light, "teapot_top.jpg")
```

```@raw html
<p align="center">
    <img width=256 height=256 src="../../assets/teapot_top.jpg">
</p>
```

### SIDE VIEW Render

```julia
light = DistantLight(
    Vec3(1.0f0),
    100.0f0,
    Vec3(1.0f0, 1.0f0, -1.0f0)
)

cam = Camera(
    Vec3(1.0f0, 2.0f0, -10.0f0),
    Vec3(0.0f0, 1.0f0, 0.0f0),
    Vec3(0.0f0, 1.0f0, 0.0f0),
    45.0f0,
    1.0f0,
    screen_size...
)

generate_render_and_save(cam, light, "teapot_side.jpg")
```

```@raw html
<p align="center">
    <img width=256 height=256 src="../../assets/teapot_side.jpg">
</p>
```

### FRONT VIEW Render

```julia
light = DistantLight(
    Vec3(1.0f0),
    100.0f0,
    Vec3(1.0f0, 1.0f0, 0.0f0)
)

cam = Camera(
    Vec3(10.0f0, 2.0f0, 0.0f0),
    Vec3(0.0f0, 1.0f0, 0.0f0),
    Vec3(0.0f0, 1.0f0, 0.0f0),
    45.0f0,
    1.0f0,
    screen_size...
)

generate_render_and_save(cam, light, "teapot_front.jpg")
```

```@raw html
<p align="center">
    <img width=256 height=256 src="../../assets/teapot_front.jpg">
</p>
```

## Next Steps

* Try Rendering complex environments with RayTracer
* Look into the other examples in `examples/`
* Read about inverse rendering and see the examples on that

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

