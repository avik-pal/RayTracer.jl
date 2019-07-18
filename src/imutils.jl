export get_image, zeroonenorm

using Zygote: @adjoint

# ---------- #
# Processing #
# ---------- #

"""
    get_image(image, width, height)

Reshapes and normalizes a Vec3 color format to the RGB format of Images
for easy loading, saving and visualization.

### Arguments:

* `image`  - The rendered image in flattened Vec3 format
           (i.e., the output of the raytrace, rasterize, etc.)
* `width`  - Width of the output image
* `height` - Height of the output image
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

!!! note
    This function exists because the version of Zygote we use returns
    incorrect gradient for `1/maximum(x)` function. This has been fixed
    on the latest release of Zygote.
"""
zeroonenorm(x) = (x .- minimum(x)) ./ (maximum(x) - minimum(x))
