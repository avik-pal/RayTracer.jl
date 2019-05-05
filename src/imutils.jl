using Images

export get_image

# ---------- #
# Processing #
# ---------- #

"""
    improcess(color_vector, width, height)

Normalizes the Color Dimension and reshapes it to the given
configuration.
"""
function improcess(x, width, height)
	y = reshape(x, width, height)
	return (y .- minimum(y)) ./ maximum(y)
end

"""
    get_image(image, width, height)

Reshapes and normalizes a Vec3 color format to the RGB format of Images
for easy loading, saving and visualization.

This function is available only if `Images.jl` is loaded.
"""
function get_image(im::Vec3{T}, width, height) where {T}
	low = eltype(T)(0)
	high = eltype(T)(1)
	color_r = improcess(im.x, width, height)
	color_g = improcess(im.y, width, height)
	color_b = improcess(im.z, width, height)

	im_arr = clamp.(permutedims(cat(color_r, color_g, color_b, dims = 3), (3, 2, 1)), low, high)

	return colorview(RGB, im_arr)
end
