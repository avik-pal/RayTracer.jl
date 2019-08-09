@testset "Basic Vec3 Functionality" begin
    # Check the constructors
    a = Vec3(1.0)

    @test a.x[] == 1.0 && a.y[] == 1.0 && a.z[] == 1.0

    a = Vec3([1.0, 1.0])

    @test a.x == [1.0, 1.0] && a.y == [1.0, 1.0] && a.z == [1.0, 1.0]

    # Operators +, -, * | Both Vec3
    for op in (:+, :-, :*)
        len = rand(1:25)

        a1 = rand(len)
        b1 = rand(len)
        c1 = rand(len)

        a2 = rand(len)
        b2 = rand(len)
        c2 = rand(len)

        vec3_1 = Vec3(a1, b1, c1)
        vec3_2 = Vec3(a2, b2, c2)

        res = @eval $(op)($vec3_1, $vec3_2)
        res_x = @eval broadcast($(op), $a1, $a2)
        res_y = @eval broadcast($(op), $b1, $b2)
        res_z = @eval broadcast($(op), $c1, $c2)

        @test res.x == res_x && res.y == res_y && res.z == res_z
    end

    # Operators +, -, *, /, % | Only 1 Vec3
    for op in (:+, :-, :*, :/, :%)
        len = rand(1:25)

        a = rand(len)
        b = rand(len)
        c = rand(len)

        num = rand()

        vec3_1 = Vec3(a, b, c)

        res1 = @eval $(op)($vec3_1, $num)
        res1_x = @eval broadcast($(op), $a, $num)
        res1_y = @eval broadcast($(op), $b, $num)
        res1_z = @eval broadcast($(op), $c, $num)

        @test res1.x == res1_x && res1.y == res1_y && res1.z == res1_z

        res2 = @eval $(op)($num, $vec3_1)
        res2_x = @eval broadcast($(op), $a, $num)
        res2_y = @eval broadcast($(op), $b, $num)
        res2_z = @eval broadcast($(op), $c, $num)

        @test res2.x == res2_x && res2.y == res2_y && res2.z == res2_z
    end

    # Other Operators
    a_vec = Vec3(1.0, 2.0, 3.0)
    b_vec = Vec3(4.0, 5.0, 6.0)
    neg_a_vec = - a_vec
    cross_prod = RayTracer.cross(a_vec, b_vec)
    b_clamped = clamp(b_vec, 4.5, 5.5)

    @test neg_a_vec.x[] == -1.0 && neg_a_vec.y[] == -2.0 && neg_a_vec.z[] == -3.0
    @test RayTracer.dot(a_vec, b_vec)[] == 32.0
    @test RayTracer.l2norm(a_vec)[] == 14.0
    @test RayTracer.l2norm(RayTracer.normalize(a_vec))[] == 1.0
    @test maximum(a_vec) == 3.0
    @test minimum(a_vec) == 1.0
    @test size(a_vec) == (1,)
    @test getindex(a_vec, 1) == (x = 1.0, y = 2.0, z = 3.0)
    @test cross_prod.x[] == -3.0 && cross_prod.y[] == 6.0 && cross_prod.z[] == -3.0
    @test b_clamped.x[] == 4.5 && b_clamped.y[] == 5.0 && b_clamped.z[] == 5.5 

end
