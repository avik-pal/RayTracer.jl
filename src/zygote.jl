import Base.getproperty

using Zygote: @adjoint

import Zygote.literal_getproperty

# ---- #
# Vec3 #
# ---- #

@adjoint function dot(a::Vec3, b::Vec3)
    dot(a, b), Δ -> begin 
        t1 = Δ * b
        t2 = Δ * a
        if length(a.x) != length(t1.x)
            t1 = Vec3(sum(t1.x), sum(t1.y), sum(t1.z))
        end
        if length(b.x) != length(t2.x)
            t2 = Vec3(sum(t2.x), sum(t2.y), sum(t2.z))
        end
        return (t1, t2)
    end
end

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

# -------- #
# Material #
# -------- #

@adjoint PlainColor(color::Vec3) = PlainColor(color), Δ -> (Δ.color,)
    
@adjoint literal_getproperty(c::PlainColor, ::Val{f}) where {f} =
    getproperty(c, f), Δ -> (PlainColor(Δ), nothing)

@adjoint CheckeredSurface(color1::Vec3, color2::Vec3) =
    CheckeredSurface(color1, color2), Δ -> (Δ.color1, Δ.color2)
    
@adjoint literal_getproperty(c::CheckeredSurface, ::Val{f}) where {f} =
    getproperty(c, f), Δ -> begin
        if f == :color1
            (CheckeredSurface(Δ, Vec3(similar(Δ.x))), nothing)
        else
            (CheckeredSurface(Vec3(similar(Δ.x)), Δ), nothing)
        end
    end

@adjoint Material(col::S, reflection::R) where {S<:SurfaceColor, R<:Real} =
    Material(col, reflection), Δ -> (Δ.color, Δ.reflection)

@adjoint literal_getproperty(m::Material, ::Val{f}) where {f} =
    getproperty(m, f), Δ -> begin
        if f == :color
            (Material(Δ, 0.0), nothing)
        else
            (Material(typeof(m.color)(), Δ), nothing)
        end
    end

# ------- #
# Objects #
# ------- #

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

@adjoint Triangle(v1, v2, v3, normal, material::Material) =
    Triangle(v1, v2, v3, normal, material),
    Δ -> Triangle(Δ.v1, Δ.v2, Δ.v3, Δ.normal, Δ.material)

@adjoint literal_getproperty(t::Triangle, ::Val{f}) where {f} =
    getproperty(t, f), Δ -> (Triangle(Δ, f), nothing)

