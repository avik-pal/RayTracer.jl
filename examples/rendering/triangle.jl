using RayTracer, Images

screen_size = (w = 256, h = 256)

light = PointLight(Vec3(1.0f0), 20000.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

cam = Camera(Vec3(0.0f0, 0.0f0, -5.0f0), Vec3(0.0f0), Vec3(0.0f0, 1.0f0, 0.0f0),
             45.0f0, 1.0f0, screen_size.w, screen_size.h)

scene = [
    Triangle(Vec3(-1.7f0, 1.0f0, 0.0f0), Vec3(1.0f0, 1.0f0, 0.0f0), Vec3(-0.5f0, -1.0f0, 0.0f0),
             color = rgb(0.2f0, 1.0f0, 0.1f0), reflection = 0.9f0)    
    ]

origin, direction = get_primary_rays(cam)

color = raytrace(origin, direction, scene, light, origin, 0)

img = get_image(color, screen_size.w, screen_size.h)

save("triangle.jpg", img)
