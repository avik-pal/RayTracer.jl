using RayTracer, Images

screen_size = (w = 256, h = 256)

light = PointLight(Vec3(1.0f0), 200.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

eye_pos = Vec3(0.0f0, 0.0f0, -5.0f0)

scene = [
    Triangle(Vec3(-1.7f0, 1.0f0, 0.0f0), Vec3(1.0f0, 1.0f0, 0.0f0), Vec3(-0.5f0, -1.0f0, 0.0f0),
             color = rgb(0.5f0, 0.9f0, 0.1f0), reflection = 0.9f0)    
    ]

origin, direction = get_primary_rays(Float32, screen_size.w, screen_size.h, 45, eye_pos);

color = raytrace(origin, direction, scene, light, eye_pos, 0)

img = get_image(color, screen_size.w, screen_size.h)

save("triangle.jpg", img)