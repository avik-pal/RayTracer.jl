using RayTracer, Zygote, Statistics

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0f0), 50.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

light2 = PointLight(Vec3(1.0f0), 50.0f0, Vec3(rand()))

eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, color = rgb(0.0f0, 0.0f0, 1.0f0))
    ]

origin, direction = get_primary_rays(Float32, 400, 300, 30, eye_pos)

color = raytrace(origin, direction, scene, light, eye_pos, 0)

function diff(c1, c2)
    c = c1 - c2
    mean(abs2.(c.x)) + mean(abs2.(c.y)) + mean(abs2.(c.z))
end

function ldiff(lgt)
    color2 = raytrace(origin, direction, scene, lgt, eye_pos, 0)
    loss = diff(color, color2)
end

l = light2

for i in 1:100
    global light2
    g = ldiff'(l)
    l = update(l, g, 1.0f0)
    display(l)
end

