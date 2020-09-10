function compute_diffuse_lighting(normals::AbstractArray{T, 3},
                                  colors::AbstractArray{T, 2},
                                  directions::AbstractArray{T, 2}) where T
    # normals --> 3 x F x N
    # colors --> 3 x (N / 1)
    # directions --> 3 x (N / 1)
    colors = reshape(colors, 3, 1, size(colors, 2))  # 3 x 1 x (N / 1)
    directions = reshape(directions, 3, 1, size(directions, 2))  # 3 x 1 x (N / 1)
    normals = _normalize(normals, 1)
    directions = _normalize(directions, 1)
    return compute_diffuse_lighting(normals, colors, directions)
end

function compute_diffuse_lighting(normals::AbstractArray{T, 3},
                                  colors::AbstractArray{T, 2},
                                  directions::AbstractArray{T, 3}) where T
    # normals --> 3 x F x N
    # colors --> 3 x (N / 1)
    # directions --> 3 x (F / 1) x (N / 1)
    colors = reshape(colors, 3, 1, size(colors, 2))  # 3 x 1 x (N / 1)
    normals = _normalize(normals, 1)
    directions = _normalize(directions, 1)
    return compute_diffuse_lighting(normals, colors, directions)
end


function compute_diffuse_lighting(normals::AbstractArray{T, 3},
                                  colors::AbstractArray{T, 3},
                                  directions::AbstractArray{T, 3}) where T
    # normals --> 3 x F x N
    # colors --> 3 x 1 x (N / 1)
    # directions --> 3 x 1 x (N / 1)
    # Assumes normalized versions of normals and directions
    angle = relu.(sum(normals .* directions, dims = 1))  # 1 x F x N
    return colors .* angle  # 3 x F x N
end


function compute_specular_lighting(points::AbstractArray{T, 3},
                                   normals::AbstractArray{T, 3},
                                   colors::AbstractArray{T, 2},
                                   directions::AbstractArray{T, 2},
                                   camera_positions::AbstractArray{T, 2},
                                   specular_exponents::AbstractArray{T, 1}) where T
    # points --> 3 x P x N
    # normals --> 3 x P x N
    # colors --> 3 x (N / 1)
    # directions --> 3 x (N / 1)
    # camera_positions --> 3 x (N / 1)
    # specular_exponents --> (N / 1)
    colors = reshape(colors, 3, 1, size(colors, 2))
    directions = reshape(directions, 3, 1, size(directions, 2))
    camera_positions = reshape(camera_positions, 3, 1, size(camera_positions, 2))
    specular_exponents = reshape(specular_exponents, 1, 1, length(specular_exponents))
    normals = _normalize(normals, 1)
    directions = _normalize(directions, 1)

    return compute_specular_lighting(points, normals, colors, directions,
                                     camera_positions, specular_exponents)
end

function compute_specular_lighting(points::AbstractArray{T, 3},
                                   normals::AbstractArray{T, 3},
                                   colors::AbstractArray{T, 2},
                                   directions::AbstractArray{T, 3},
                                   camera_positions::AbstractArray{T, 2},
                                   specular_exponents::AbstractArray{T, 1}) where T
    # points --> 3 x P x N
    # normals --> 3 x P x N
    # colors --> 3 x (N / 1)
    # directions --> 3 x (P / 1) x (N / 1)
    # camera_positions --> 3 x (N / 1)
    # specular_exponents --> (N / 1)
    colors = reshape(colors, 3, 1, size(colors, 2))
    camera_positions = reshape(camera_positions, 3, 1, size(camera_positions, 2))
    specular_exponents = reshape(specular_exponents, 1, 1, length(specular_exponents))
    normals = _normalize(normals, 1)
    directions = _normalize(directions, 1)

    return compute_specular_lighting(points, normals, colors, directions,
                                     camera_positions, specular_exponents)
end


function compute_specular_lighting(points::AbstractArray{T, 3},
                                   normals::AbstractArray{T, 3},
                                   colors::AbstractArray{T, 3},
                                   directions::AbstractArray{T, 3},
                                   camera_positions::AbstractArray{T, 3},
                                   specular_exponents::AbstractArray{T, 3}) where T
    # points --> 3 x P x N
    # normals --> 3 x P x N
    # colors --> 3 x 1 x (N / 1)
    # directions --> 3 x 1 x (N / 1)
    # camera_positions --> 3 x 1 x (N / 1)
    # specular_exponents --> 1 x 1 x (N / 1)
    cos_angle = sum(normals .* directions, dims = 1)  # 1 x P x N
    mask = cos_angle .> 0  # 1 x P x N

    view_direction = _normalize(camera_positions .- points, 1)  # 3 x P x N
    reflect_direction = -directions .+ 2 .* cos_angle .* normals  # 3 x P x N

    α = relu.(sum(view_direction .* reflect_direction, dims = 1)) .* mask  # 1 x P x N
    return colors .* (α .^ specular_exponents)  # 3 x P x N
end


struct DirectionalLight{A, D, S, V}
    ambient_color::A
    diffuse_color::D
    specular_color::S
    direction::V
end

@functor DirectionalLight

function compute_diffuse_lighting(d::DirectionalLight;
                                  normals::AbstractArray{T, 3},
                                  points::AbstractArray{T, 3}) where T
    return compute_diffuse_lighting(normals, d.diffuse_color, d.direction)
end

function compute_specular_lighting(d::DirectionalLight;
                                   normals::AbstractArray{T, 3},
                                   points::AbstractArray{T, 3},
                                   camera_positions::AbstractArray{T, 2},
                                   specular_exponents::AbstractArray{T, 1}) where T
    return compute_specular_lighting(points, normals, d.specular_color,
                                     d.direction, camera_positions,
                                     specular_exponents)
end


struct PointLight{A, D, S, P}
    ambient_color::A
    diffuse_color::D
    specular_color::S
    position::P
end

@functor PointLight

function compute_diffuse_lighting(p::PointLight;
                                  normals::AbstractArray{T, 3},
                                  points::AbstractArray{T, 3}) where T
    return compute_diffuse_lighting(normals, p.diffuse_color, p.position .- points)
end

function compute_specular_lighting(p::PointLight;
                                   normals::AbstractArray{T, 3},
                                   points::AbstractArray{T, 3},
                                   camera_positions::AbstractArray{T, 2},
                                   specular_exponents::AbstractArray{T, 1}) where T
    return compute_specular_lighting(points, normals, p.specular_color,
                                     p.position .- points, camera_positions,
                                     specular_exponents)
end