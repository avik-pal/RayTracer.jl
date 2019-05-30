using RayTracer, Zygote, Flux, Images, Statistics

impath = "light_position_optimization"

mkpath(impath)

function create_and_save(color, val)
    img = get_image(color, screen_size.w, screen_size.h)
    save("$(impath)/triangle_$(val).jpg", img)
end

screen_size = (w = 200, h = 200)

# Correct Position of Light
light = PointLight(Vec3(1.0, 1.0, 0.0), 20000.0, Vec3(5.0, 5.0, -10.0))

# Perturbing the light. This acts as our first guess and we refine it
# to finally match the position of `light`.
light_perturbed = PointLight(Vec3(1.0, 1.0, 0.0), 20000.0, Vec3(1.0, 2.0, -7.0))

# Scene contains a single triangle
scene = [
    Triangle(Vec3(-1.7, 1.0, 0.0), Vec3(1.0, 1.0, 0.0), Vec3(-0.5, -1.0, 0.0),
             color = rgb(0.0, 1.0, 0.0), reflection = 0.5)    
    ]

# Camera configuration 
cam = Camera(Vec3(0.0f0, 0.0f0, -5.0f0), Vec3(0.0f0), Vec3(0.0f0, 1.0f0, 0.0f0),
             45.0f0, 1.0f0, screen_size...)

origin, direction = get_primary_rays(cam)

# Original/Target Image
color = raytrace(origin, direction, scene, light, origin, 0)

create_and_save(color, "original")

# Initial Guess Image
color_guess = raytrace(origin, direction, scene, light_perturbed, origin, 0)

create_and_save(color_guess, "initial_guess")

# Gets the rendered color into the proper shape and normalizes it
function process_image(im::Vec3{T}, width, height) where {T}
    im_arr = reshape(hcat(im.x, im.y, im.z), (width, height, 3))

    return RayTracer.zeroonenorm(reshape(im_arr, (width, height, 3, 1)))
end

# Mean Squared Loss Function
function loss_fn(θ, img)
    rendered_color = raytrace(origin, direction, scene, θ, origin, 0)
    rendered_img = process_image(rendered_color, screen_size.w, screen_size.h)
    loss = mean(abs2.(rendered_img .- img))
    @show loss
    return loss
end

# Target image in proper shape
image = process_image(color, screen_size...)

# Training Loop
opt = ADAM(0.05)

@info "Starting Optimization Loop"

for i in 1:500
    gs = gradient(x -> loss_fn(x, image), light_perturbed)[1]
    update!(opt, light_perturbed.position, gs.position)
    if i % 10 == 0
        @info "$i iterations completed"
        create_and_save(raytrace(origin, direction, scene, light_perturbed, origin, 0), i)
        @show light_perturbed
    end
end

@info "Light Position Optimized"

