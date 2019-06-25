using RayTracer, Test

@testset "Rendering" begin
    @testset "Mesh Rendering" begin
        include("mesh_render.jl")
    end
end

@testset "Differentiable Ray Tracing" begin
    @testset "Gradient Checks" begin
        # Numerical Gradients are presently broken
        # include("gradcheck.jl")
    end
end
