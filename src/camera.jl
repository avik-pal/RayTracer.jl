# ------ #
# Camera #
# ------ #

# NOTE: Need to add a feature to control the orientation of the camera.
#       Currently the camera points to the -z direction.
function get_primary_rays(T, width, height, fov, cam_pos)
    aspect_ratio = T(width / height)
    scale = tan(deg2rad(fov / 2))
    origin = cam_pos
    
    x_part = T.((2 .* (collect(0:(width - 1)) .+ 0.5) ./ width .- 1) .*
                aspect_ratio .* scale)
    y_part = T.((1 .- 2 .* (collect(0:(height - 1)) .+ 0.5) ./ height) .* scale)
    
    x = repeat(x_part, outer = height)
    y = repeat(y_part, inner = width)
    
    Q = Vec3(x, y, repeat(origin.z .+ 1, inner = length(x)))
    direction = normalize(Q - origin)

    return origin, direction
end
