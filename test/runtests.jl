using RayTracer, Test

@testset "Rendering" begin
    include("utils.jl")
    include("mesh_render.jl")
end

@testset "Differentiable Ray Tracing" begin
    @testset "Gradient Checks" begin
        include("gradcheck.jl")
    end
end
