function _get_look_at_transform_rotation(camera_positions::AbstractMatrix{T},  # 3 x N
                                         look_at::AbstractMatrix{T},  # 3 x (N / 1)
                                         up::AbstractMatrix{T}) where T  # 3 x (N / 1)
    @assert size(camera_positions, 1) == size(look_at, 1) == size(up, 1) == 3

    nbatch = size(camera_positions, 2)
    z_ = reshape(_normalize(look_at .- camera_position, 1), 3, 1, nbatch)
    x_ = reshape(_normalize(_cross(up, z_), 1), 3, 1, nbatch)
    y_ = reshape(_normalize(_cross(z_, x_), 1), 3, 1, nbatch)

    return hcat(x_, y_, z_)  # 3 x 3 x N
end


function look_at_view_transform(eye::AbstractMatrix{T},
                                look_at::AbstractMatrix{T},
                                up::AbstractMatrix{T}) where T
    camera_positions = eye .+ look_at
    rot_mat = _get_look_at_transform_rotation(camera_positions, look_at, up)
    translate = -batched_mul(permutedims(rot_mat, (2, 1, 3)),
                             repeat(reshape(camera_positions,
                                            size(camera_positions, 1),
                                            size(camera_positions, 2),
                                            1),
                                    1, 1, size(rot_mat, 3)))[1, :, :]
    return rot_mat, translate
end