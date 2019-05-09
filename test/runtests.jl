using RayTracer, Test

@testset "Differentiable Ray Tracing" begin

    @testset "Gradient Checks" begin
        include("gradcheck.jl")
    end

end
