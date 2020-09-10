# Previously we were using `Vec3` type as the base type for all our
# operations. However, this is pretty difficult to maintain and
# is not feature complete. A better design choice would be to use
# `AbstractArray` of size 3 x N directly, where N is the batch size

# Batched Implementation of a few common functions
_dot(x::AbstractArray{T, N}, y::AbstractArray{T, N}) where {T, N} =
    sum(x .* y, dims = 1)

function _cross(a::Array{T, 2}, b::Array{T, 2}) where T
    a_x = @view a[1:1, :]
    a_y = @view a[2:2, :]
    a_z = @view a[3:3, :]
    b_x = @view b[1:1, :]
    b_y = @view b[2:2, :]
    b_z = @view b[3:3, :]

    return vcat(a_x .* b_z .- a_z .* b_y,
                a_z .* b_x .- a_x .* b_z,
                a_x .* b_y .- a_y .* b_x)
end

# CuArray gives messed up type inference if used with @view
function _cross(a::CuArray{T, 2}, b::CuArray{T, 2}) where T
    a_x = a[1:1, :]
    a_y = a[2:2, :]
    a_z = a[3:3, :]
    b_x = b[1:1, :]
    b_y = b[2:2, :]
    b_z = b[3:3, :]

    return vcat(a_x .* b_z .- a_z .* b_y,
                a_z .* b_x .- a_x .* b_z,
                a_x .* b_y .- a_y .* b_x)
end

_normalize(x::AbstractArray{T}, dim::Int) where T =
    x ./ sqrt.(sum(abs2, x, dims = dim) .+ eps(T))


function spherical_to_cartesian(distance::AbstractVector{T},
                                elevation::AbstractVector{T},
                                azimuth::AbstractVector{T},
                                in_degree::Bool = false) where T
    if in_degree
        elevation = deg2rad.(elevation)
        azimuth = deg2rad.(azimuth)
    end
    l = size(distance, 1)
    x = reshape(distance .* cos.(elevation) .* sin.(azimuth), 1, l)
    y = reshape(distance .* sin.(elevation), 1, l)
    z = reshape(distance .* cos.(elevation) .* cos.(azimuth), 1, l)
    return vcat(x, y, z)
end