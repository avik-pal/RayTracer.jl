export get_image, zeroonenorm

using Zygote: @adjoint

# ---------- #
# Processing #
# ---------- #

"""
    get_image(image, width, height)

Reshapes and normalizes a Vec3 color format to the RGB format of Images
for easy loading, saving and visualization.
"""
function get_image(im::Vec3{T}, width, height) where {T}
    low = eltype(T)(0)
    high = eltype(T)(1)
    color_r = reshape(im.x, width, height)
    color_g = reshape(im.y, width, height)
    color_b = reshape(im.z, width, height)

    im_arr = zeroonenorm(permutedims(reshape(hcat(color_r, color_g, color_b), (width, height, 3)), (3, 2, 1)))

    return colorview(RGB, im_arr)
end

"""
    zeroonenorm(x::AbstractArray)

Normalizes the elements of the array to values between `0` and `1`.
"""
zeroonenorm(x) = (x .- minimum(x)) ./ (maximum(x) - minimum(x))
