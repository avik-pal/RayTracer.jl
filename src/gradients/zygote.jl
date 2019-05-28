import Base.getproperty

using Zygote: @adjoint, @nograd

import Zygote.literal_getproperty

# We currently do not optimize the Material of the surface

# ---- #
# Vec3 #
# ---- #

# Hack to avoid nothing in the gradient due to typemax
@adjoint bigmul(x::T) where {T} = bigmul(x), Δ -> (zero(T),)

@adjoint Vec3(a, b, c) = Vec3(a, b, c), Δ -> (Δ.x, Δ.y, Δ.z)

@adjoint function literal_getproperty(v::Vec3, ::Val{f}) where {f}
    return getproperty(v, f), function (Δ)
        z = zero(Δ)
        if f == :x
            return (Vec3(Δ, z, z), nothing)
        elseif f == :y
            return (Vec3(z, Δ, z), nothing)
        elseif f == :z
            return (Vec3(z, z, Δ), nothing)
        else
            error("Undefined Field Name")
        end
    end
end

@adjoint place(a::Vec3, cond) = place(a, cond), Δ -> (Vec3(Δ.x[cond], Δ.y[cond], Δ.z[cond]), nothing)

# ----- #
# Light #
# ----- #

# -------------- #
# - PointLight - #
# -------------- #

@adjoint PointLight(color::Vec3, intensity::I, pos::Vec3) where {I<:AbstractFloat} =
    PointLight(color, intensity, pos), Δ -> (Δ.color, Δ.intensity, Δ.position)

@adjoint literal_getproperty(p::PointLight{I}, ::Val{:color}) where {I} =
    getproperty(p, :color), Δ -> (PointLight(Δ, zero(I), zero(p.position)), nothing)

@adjoint literal_getproperty(p::PointLight, ::Val{:intensity}) =
    getproperty(p, :intensity), Δ -> (PointLight(zero(p.color), Δ, zero(p.position)), nothing)

@adjoint literal_getproperty(p::PointLight{I}, ::Val{:position}) where {I} =
    getproperty(p, :position), Δ -> (PointLight(zero(p.color), zero(I), Δ), nothing)

# ---------------- #
# - DistantLight - #
# ---------------- #

@adjoint DistantLight(color::Vec3, intensity::I, position::Vec3, direction::Vec3) where {I<:AbstractFloat} =
    DistantLight(color, intensity, direction), Δ -> (Δ.color, Δ.intensity, Δ.direction)

@adjoint literal_getproperty(d::DistantLight{I}, ::Val{:color}) where {I} =
    getproperty(d, :color), Δ -> (DistantLight(Δ, zero(I), zero(d.direction)), nothing)

@adjoint literal_getproperty(d::DistantLight, ::Val{:intensity}) =
    getproperty(d, :intensity), Δ -> (DistantLight(zero(d.color), Δ, zero(d.direction)), nothing)

@adjoint literal_getproperty(d::DistantLight{I}, ::Val{:direction}) where {I} =
    getproperty(d, :direction), Δ -> (DistantLight(zero(d.color), zero(I), Δ), nothing)

# ------------ #
# SurfaceColor #
# ------------ #

# -------------- #
# - PlainColor - #
# -------------- #

@adjoint PlainColor(color::Vec3) = PlainColor(color), Δ -> (Δ.color,)
    
@adjoint literal_getproperty(c::PlainColor, ::Val{f}) where {f} =
    getproperty(c, f), Δ -> (PlainColor(Δ), nothing)

# ------------------ #
# - CheckeredColor - #
# ------------------ #

@adjoint CheckeredSurface(color1::Vec3, color2::Vec3) =
    CheckeredSurface(color1, color2), Δ -> (Δ.color1, Δ.color2)
    
@adjoint literal_getproperty(c::CheckeredSurface, ::Val{f}) where {f} =
    getproperty(c, f), Δ -> begin
        if f == :color1
            return (CheckeredSurface(Δ, zero(c.color2)), nothing)
        else
            return (CheckeredSurface(zero(c.color1), Δ), nothing)
        end
    end

# -------- #
# Material #
# -------- #

@adjoint Material(col::S, reflection::R) where {S<:SurfaceColor, R<:Real} =
    Material(col, reflection), Δ -> (Δ.color, Δ.reflection)

@adjoint literal_getproperty(m::Material{S, R}, ::Val{f}) where {S, R, f} =
    getproperty(m, f), Δ -> begin
        if f == :color
            return (Material(Δ, R(0)), nothing)
        else
            return (Material(PlainColor(), Δ), nothing) # PlainColor is the zero for SurfaceColor
        end
    end

# ------- #
# Objects #
# ------- #

# TODO: Verify correctness
@adjoint function fseelight(n::Int, light_distances)
    res = fseelight(n, light_distances)
    return res, function (Δ)
        ∇res = [zero(i) for i in light_distances]
        ∇res[n] .= res .* Δ
        (nothing, ∇res)
    end
end
    

# ---------- #
# - Sphere - #
# ---------- #

@adjoint Sphere(center, radius, material::Material) =
    Sphere(center, radius, material), Δ -> (Δ.sphere, Δ.radius, Δ.material)

@adjoint literal_getproperty(s::Sphere, ::Val{f}) where {f} =
    getproperty(s, f), Δ -> (Sphere(Δ), nothing)

# ------------ #
# - Cylinder - #
# ------------ #

@adjoint Cylinder(center, radius, axis, length, material::Material) =
    Cylinder(center, radius, axis, length, material),
    Δ -> (Δ.center, Δ.radius, Δ.axis, Δ.length, Δ.material)

@adjoint literal_getproperty(c::Cylinder, ::Val{f}) where {f} =
    getproperty(c, f), Δ -> (Cylinder(Δ, f), nothing)

# ------------ #
# - Triangle - #
# ------------ #

@adjoint Triangle(v1, v2, v3, material::Material) =
    Triangle(v1, v2, v3, material), Δ -> Triangle(Δ.v1, Δ.v2, Δ.v3, Δ.material)

@adjoint literal_getproperty(t::Triangle, ::Val{f}) where {f} =
    getproperty(t, f), Δ -> (Triangle(Δ, f), nothing)

# -------- #
# - Disc - #
# -------- #

@adjoint Disc(c, n, r, material::Material) =
    Disc(c, n, r, material), Δ -> Disc(Δ.center, Δ.normal, Δ.radius, Δ.material)

@adjoint literal_getproperty(t::Disc, ::Val{f}) where {f} =
    getproperty(t, f), Δ -> (Disc(Δ, f), nothing)

# ------ #
# Camera #
# ------ #

# TODO: Correct the adjoints for literal_getproperty. It is special cased
#       for Float32
@adjoint Camera(lf, la, vfov, focus, fp) =
    Camera(lf, la, vfov, focus, fp), Δ -> Camera(Δ.lookfrom, Δ.lookat,
                                                 Δ.vfov, Δ.focus,
                                                 Δ.fixedparams)

@adjoint literal_getproperty(c::Camera, ::Val{:lookfrom}) =
    getproperty(c, :lookfrom), Δ -> (Camera(Δ, Vec3(0.0f0), [0.0f0], [0.0f0],
                                            FixedCameraParams(Vec3(0.0f0), 0, 0)))

@adjoint literal_getproperty(c::Camera, ::Val{:lookat}) =
    getproperty(c, :lookat), Δ -> (Camera(Vec3(0.0f0), Δ, [0.0f0], [0.0f0],
                                          FixedCameraParams(Vec3(0.0f0), 0, 0)))

@adjoint literal_getproperty(c::Camera, ::Val{:vfov}) =
    getproperty(c, :vfov), Δ -> (Camera(Vec3(0.0f0), Vec3(0.0f0), Δ, [0.0f0],
                                        FixedCameraParams(Vec3(0.0f0), 0, 0)))

@adjoint literal_getproperty(c::Camera, ::Val{:focus}) =
    getproperty(c, :focus), Δ -> (Camera(Vec3(0.0f0), Vec3(0.0f0), [0.0f0], Δ,
                                         FixedCameraParams(Vec3(0.0f0), 0, 0)))

@adjoint literal_getproperty(c::Camera, ::Val{:fixedparams}) =
    getproperty(c, :fixedparams), Δ -> (Camera(Δ, Vec3(0.0f0), [0.0f0], [0.0f0], Δ))
    
# ------- #
# ImUtils #
# ------- #

@adjoint function zeroonenorm(x)
    mini, indmin = findmin(x)
    maxi, indmax = findmax(x)
    res = (x .- mini) ./ maxi
    function ∇zeroonenorm(Δ)
        ∇x = similar(x)
        fill!(∇x, 1 / maxi)
        ∇x[indmin] *= -(length(x) - 1)
        res2 = - res ./ maxi
        ∇x[indmax] = sum(res2) - minimum(res2) + mini / (maxi ^ 2)
        return (∇x .* Δ, )
    end
    return res, ∇zeroonenorm
end
