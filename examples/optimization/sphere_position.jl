using RayTracer, Zygote, Flux, Images, Metalhead

# Convenience Functions

function create_and_save(color, val)
    img = get_image(color, screen_size.w, screen_size.h)
    save("images/sphere_$(val).jpg", img)
end

# Define the Original Scene Parameters

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0f0), 1000.0f0, Vec3(5.0f0, 5.0f0, -1.0f0))

eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

scene = [
    SimpleSphere(Vec3( 0.75f0,      0.1f0,  1.0f0),     0.6f0, color = rgb(0.0f0, 0.012f0, 1.0f0)),
    SimpleSphere(Vec3(-0.75f0,      0.1f0, 2.25f0),     0.6f0, color = rgb(0.5f0, 0.223f0, 0.5f0)),
    SimpleSphere(Vec3(-2.75f0,      0.1f0,  3.5f0),     0.6f0, color = rgb(1.0f0, 0.572f0, 0.1f0)),
    SimpleSphere(Vec3(  0.0f0, -99999.5f0,  0.0f0), 99999.0f0, color = rgb(0.2f0,   0.6f0, 0.3f0)),
]

origin, direction = get_primary_rays(Float32, 400, 300, 90, eye_pos);

color = raytrace(origin, direction, scene, light, eye_pos, 0)

create_and_save(color, "original")

# Perturb the sphere positions

scene_new = [
    SimpleSphere(Vec3( 1.75f0,      1.1f0,  1.0f0),     0.6f0, color = rgb(0.0f0, 0.012f0, 1.0f0)),
    SimpleSphere(Vec3(-0.25f0,     -0.1f0, 2.90f0),     1.6f0, color = rgb(0.5f0, 0.223f0, 0.5f0)),
    SimpleSphere(Vec3(-1.75f0,      2.1f0,  3.5f0),     0.6f0, color = rgb(1.0f0, 0.572f0, 0.1f0)),
    SimpleSphere(Vec3(  0.0f0, -99999.5f0,  0.0f0), 99999.0f0, color = rgb(0.2f0,   0.6f0, 0.3f0)),
]

# Approach 0:
# Simply compute the pixelwise distance for loss and optimize

function loss_fn(θ)
    rendered_color = raytrace(origin, direction, θ, light, eye_pos, 0)
    loss = sum(abs2.(rendered_color.x .- color.x) .+
               abs2.(rendered_color.y .- color.y) .+
               abs2.(rendered_color.z .- color.z))
    @show loss
    return loss
end

# Approach 1:
# Apply Gaussian Blur on the rendered images before computing loss

#=
function process_image(im::Vec3{T}, width, height) where {T}
    im_arr = reshape(hcat(im.x, im.y, im.z), (width, height, 3))
    im_arr2 = (im_arr .- minimum(im_arr)) ./ maximum(im_arr)
    
    return reshape(im_arr2, (width, height, 3, 1))
end

GaussianFilter = reshape([1,  4,  7,  4, 1,
                          4, 16, 26, 16, 4,
                          7, 26, 41, 26, 7,
                          4, 16, 26, 16, 4,
                          1,  4,  7,  4, 1] ./ 273f0,
                         (5, 5, 1, 1))

GaussianBlur = DepthwiseConv(repeat(GaussianFilter, inner=(1, 1, 1, 3)), [0.0f0], pad = 2)

blurred_original = GaussianBlur(process_image(color, screen_size.w, screen_size.h))

function loss_fn_gaussian_blur(θ)
    rendered_color = raytrace(origin, direction, θ, light, eye_pos, 0)
    rendered_img_blurred = GaussianBlur(process_image(rendered_color, screen_size.w, screen_size.h))
    loss = sum(abs2.(rendered_img_blurred .- blurred_original))
    @show loss
    return loss
end
=#

# Approach 2:
# Load a pretrained Neural Network
# Extract features of the original rendered image
# Compute loss as the mean squared error between the 2 feature vectors

#=
function process_image(im::Vec3{T}, width, height) where {T}
    im_arr = reshape(hcat(im.x, im.y, im.z), (width, height, 3))
    im_arr2 = (im_arr .- minimum(im_arr)) ./ maximum(im_arr)
    μ = reshape([0.485f0, 0.456f0, 0.406f0], (1, 1, 3))
    σ = reshape([0.229f0, 0.224f0, 0.225f0], (1, 1, 3))
    
    return reshape((im_arr2 .- μ) ./ σ, (width, height, 3, 1))
end

model = trained(VGG19).layers[1:5]

target_features = model(process_image(color, screen_size.w, screen_size.h))

function loss_fn_nn(θ)
    rendered_color = raytrace(origin, direction, θ, light, eye_pos, 0)
    rendered_img_features = model(process_image(rendered_color, screen_size.w, screen_size.h))
    loss = sum(abs2.(rendered_img_features .- target_features))
    @show loss
    return loss
end
=#

# Generate the initial guess

color_initial_guess = raytrace(origin, direction, scene_new, light, eye_pos, 0)

create_and_save(color_initial_guess, "initial_guess")

# Define the Optimizer and the Optimization Loop

opt = ADAM(0.01f0)

for iter in 1:10000
    global scene_new
    gs = gradient(loss_fn, scene_new)[1]
    # gs = gradient(loss_fn_gaussian_blur, scene_new)[1]
    # gs = gradient(loss_fn_nn, scene_new)[1]
    [update!(opt, scene_new[i], gs[i]) for i in 1:length(scene_new)]
    if iter % 10 == 0
        @info "$(iter) iterations completed."
        create_and_save(raytrace(origin, direction, scene_new, light, eye_pos, 0), iter)
        display(scene_new)
    end
end

@info "Optimization Completed"
