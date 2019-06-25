using RayTracer, Images

screen_size = (w = 512, h = 512)

cam = Camera(
    Vec3(0.0f0, 0.35f0, -1.0f0),
    Vec3(1.0f0, 0.0f0, 1.0f0),
    Vec3(0.0f0, 1.0f0, 0.0f0),
    45.0f0, 1.0f0,
    screen_size.w,
    screen_size.h
)

scene = [
    Sphere(Vec3( 0.75f0,      0.1f0,  1.0f0),     [0.6f0],
           Material(color_diffuse = rgb(0.0f0, 0.0f0, 1.0f0),
                    color_ambient = rgb(0.0f0, 0.0f0, 1.0f0))),
    Sphere(Vec3(-0.75f0,      0.1f0, 2.25f0),     [0.6f0],
           Material(color_diffuse = rgb(0.5f0, 0.223f0, 0.5f0),
                    color_ambient = rgb(0.5f0, 0.223f0, 0.5f0))),
    Sphere(Vec3(-2.75f0,      0.1f0,  3.5f0),     [0.6f0],
           Material(color_diffuse = rgb(1.0f0, 0.572f0, 0.184f0),
                    color_ambient = rgb(1.0f0, 0.572f0, 0.184f0))),
    Sphere(Vec3(  0.0f0, -99999.5f0,  0.0f0), [99999.0f0],
           Material(color_diffuse = rgb(0.0f0, 1.0f0, 0.0f0),
                    color_ambient = rgb(0.0f0, 1.0f0, 0.0f0),
                    reflection = 0.25f0))
    ]

origin, direction = get_primary_rays(cam)

light = PointLight(
    Vec3(1.0f0, 1.0f0, 1.0f0),
    2.0f4,
    Vec3(1.0f0, 5.0f0, -1.0f0)
)

color = raytrace(origin, direction, scene, light, origin, 0)

img = get_image(color, screen_size.w, screen_size.h)

save("spheres1.jpg", img)

light = PointLight(
    Vec3(1.0f0),
    5.0f6,
    Vec3(5.0f0, 55.0f0, -1.0f0)
)

color = raytrace(origin, direction, scene, light, origin, 0)

img = get_image(color, screen_size.w, screen_size.h)

save("spheres2.jpg", img)
