using RayTracer, Zygote, Statistics

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0f0), 50.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

light2 = PointLight(Vec3(1.0f0), 50.0f0, Vec3(rand(Float32)))

eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, color = rgb(0.0f0, 0.0f0, 1.0f0))
    ]

origin, direction = get_primary_rays(Float32, 400, 300, 30, eye_pos)

color = raytrace(origin, direction, scene, light, eye_pos, 0)

function diff(c1, c2)
    c = c1 - c2
    sum(abs2.(c.x)) + sum(abs2.(c.y)) + sum(abs2.(c.z))
end

function ldiff(lgt)
    color2 = raytrace(origin, direction, scene, lgt, eye_pos, 0)
    loss = diff(color, color2)
end

l = light2

update(l, g, η) = PointLight(l.color - η * g.color, l.intensity - η * g.intensity, l.position - η * g.position)

for i in 1:100
    global l
    y, back = Zygote._forward(ldiff, l)
    println("Loss = $y")
    g = back(1.0f0)[2]
    l = update(l, g, 1.0f0)
    display(l)
end
