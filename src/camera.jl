# ------ #
# Camera #
# ------ #

# NOTE: Need to add a feature to control the orientation of the camera.
#       Currently the camera points to the -z direction.
"""
    get_primary_rays(T, width, height, fov, cam_pos)

Takes the configuration of the screen and the camera position and returns
the origin and the direction of the primary rays. The camera points along
the negative z-axis.

The origin is taken to be the `cam_pos` (camera position). Next we generate
rays going from the `origin` to every single point on the screen.

Example:

`get_primary_rays(Float32, 1024, 512, 60, Vec3(0.0f0, 0.0f0, -0.5f0))`
"""
function get_primary_rays(T, width, height, fov, cam_pos::Vec3)
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
