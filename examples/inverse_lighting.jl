# # Inverse Lighting Tutorial
#
# In this tutorial we shall explore the inverse lighting problem.
# Here, we shall try to reconstruct a target image by optimizing
# the parameters of the light source (using gradients).

using RayTracer, Images, Zygote, Flux, Statistics

# Reduce the screen_size if the optimization is taking a bit long
screen_size = (w = 300, h = 300)
