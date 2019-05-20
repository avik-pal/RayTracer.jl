using RayTracer, Images

screen_size = (w = 512, h = 512)

light = PointLight(Vec3(1.0f0), 20000.0f0, Vec3(1.0f0, 5.0f0, -1.0f0))

cam = Camera(Vec3(0.0f0, 0.35f0, -1.0f0), Vec3(1.0f0, 0.0f0, 1.0f0), Vec3(0.0f0, 1.0f0, 0.0f0),
             45.0f0, 1.0f0, screen_size.w, screen_size.h)

scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, color = rgb(0.0f0, 0.0f0, 1.0f0)),
    SimpleSphere(Vec3(-0.75f0, 0.1f0, 2.25f0), 0.6f0, color = rgb(0.5f0, 0.223f0, 0.5f0)),
    SimpleSphere(Vec3(-2.75f0, 0.1f0, 3.5f0), 0.6f0, color = rgb(1.0f0, 0.572f0, 0.184f0)),
    CheckeredSphere(Vec3(0.0f0, -99999.5f0, 0.0f0), 99999.0f0,
                    color1 = rgb(0.0f0, 1.0f0, 0.0f0),
                    color2 = rgb(0.0f0, 0.0f0, 1.0f0), reflection = 0.25f0)
    ]

origin, direction = get_primary_rays(cam)

color = raytrace(origin, direction, scene, light, origin, 0)

img = get_image(color, screen_size.w, screen_size.h)

save("spheres1.jpg", img)

light = PointLight(Vec3(1.0f0), 5000000.0f0, Vec3(5.0f0, 55.0f0, -1.0f0))

color = raytrace(origin, direction, scene, light, origin, 0)

img = get_image(color, screen_size.w, screen_size.h)

save("spheres2.jpg", img)

