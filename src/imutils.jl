using Images

export get_image

# ---------- #
# Processing #
# ---------- #

function improcess(x, width, height)
	y = reshape(x, width, height)
	return (y .- minimum(y)) ./ maximum(y)
end

function get_image(im::Vec3, width, height)
	color_r = improcess(im.x, width, height)
	color_g = improcess(im.y, width, height)
	color_b = improcess(im.z, width, height)

	im_arr = permutedims(cat(color_r, color_g, color_b, dims = 3), (3, 2, 1))

	return colorview(RGB, im_arr)
end
