import Base.getproperty
import Base.findmin
import Base.findmax
import Base.push!

using Zygote: @adjoint, @nograd

import Zygote.literal_getproperty

# ---- #
# Vec3 #
# ---- #

# Hack to avoid nothing in the gradient due to typemax
@adjoint bigmul(x::T) where {T} = bigmul(x), Δ -> (zero(T),)

@adjoint Vec3(a, b, c) = Vec3(a, b, c), Δ -> (Δ.x, Δ.y, Δ.z)

@adjoint literal_getproperty(v::Vec3, ::Val{:x}) =
    getproperty(v, :x), Δ -> (Vec3(Δ, zero(v.y), zero(v.z)), nothing)

@adjoint literal_getproperty(v::Vec3, ::Val{:y}) =
    getproperty(v, :y), Δ -> (Vec3(zero(v.x), Δ, zero(v.z)), nothing)

@adjoint literal_getproperty(v::Vec3, ::Val{:z}) =
    getproperty(v, :z), Δ -> (Vec3(zero(v.x), zero(v.y), Δ), nothing)

@adjoint function dot(a::Vec3, b::Vec3)	
    dot(a, b), Δ -> begin	
        Δ = map(x -> isnothing(x) ? zero(eltype(a.x)) : x, Δ)	
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
    
# The purpose of this adjoint is to ensure type inference works
# in the backward pass
@adjoint function cross(a::Vec3{T}, b::Vec3{T}) where {T}
    cross(a, b), Δ -> begin
        ∇a = zero(a)
        ∇b = zero(b)
        x = (Δ.z .* b.y) .- (Δ.y .* b.z)
        y = (Δ.x .* b.z) .- (Δ.z .* b.x)
        z = (Δ.y .* b.x) .- (Δ.x .* b.y)
        if length(a.x) == 1
            ∇a.x .= sum(x)
            ∇a.y .= sum(y)
            ∇a.z .= sum(z)
        else
            ∇a.x .= x
            ∇a.y .= y
            ∇a.z .= z
        end
        x = (Δ.y .* a.z) .- (Δ.z .* a.y)
        y = (Δ.z .* a.x) .- (Δ.x .* a.z)
        z = (Δ.x .* a.y) .- (Δ.y .* a.x)
        if length(b.x) == 1
            ∇b.x .= sum(x)
            ∇b.y .= sum(y)
            ∇b.z .= sum(z)
        else
            ∇b.x .= x
            ∇b.y .= y
            ∇b.z .= z
        end
        return (∇a, ∇b)
    end
end

@adjoint place(a::Vec3, cond) = place(a, cond), Δ -> (Vec3(Δ.x[cond], Δ.y[cond], Δ.z[cond]), nothing)

@adjoint place(a::Array, cond) = place(a, cond), Δ -> (Δ[cond], nothing)

@adjoint place_idx!(a::Vec3, b::Vec3, idx) = place_idx!(a, b, idx), Δ -> (zero(Δ), Vec3(Δ[idx]...), nothing)

# ----- #
# Light #
# ----- #

# -------------- #
# - PointLight - #
# -------------- #

@adjoint PointLight(color::Vec3, intensity, pos::Vec3) =
    PointLight(color, intensity, pos), Δ -> (Δ.color, Δ.intensity, Δ.position)

@adjoint literal_getproperty(p::PointLight, ::Val{:color}) =
    getproperty(p, :color), Δ -> (PointLight(Δ, zero(p.intensity), zero(p.position)), nothing)

@adjoint literal_getproperty(p::PointLight, ::Val{:intensity}) =
    getproperty(p, :intensity), Δ -> (PointLight(zero(p.color), Δ, zero(p.position)), nothing)

@adjoint literal_getproperty(p::PointLight, ::Val{:position}) =
    getproperty(p, :position), Δ -> (PointLight(zero(p.color), zero(p.intensity), Δ), nothing)

# ---------------- #
# - DistantLight - #
# ---------------- #

@adjoint DistantLight(color::Vec3, intensity, direction::Vec3) =
    DistantLight(color, intensity, direction), Δ -> (Δ.color, Δ.intensity, Δ.direction)

@adjoint literal_getproperty(d::DistantLight, ::Val{:color}) =
    getproperty(d, :color), Δ -> (DistantLight(Δ, zero(d.intensity), zero(d.direction)), nothing)

@adjoint literal_getproperty(d::DistantLight, ::Val{:intensity}) =
    getproperty(d, :intensity), Δ -> (DistantLight(zero(d.color), Δ, zero(d.direction)), nothing)

@adjoint literal_getproperty(d::DistantLight, ::Val{:direction}) =
    getproperty(d, :direction), Δ -> (DistantLight(zero(d.color), zero(d.intensity), Δ), nothing)

# -------- #
# Material #
# -------- #

@adjoint Material(color_ambient, color_diffuse, color_specular, specular_exponent,
                  reflection, texture_ambient, texture_diffuse, texture_specular,
                  uv_coordinates) =
    Material(color_ambient, color_diffuse, color_specular, specular_exponent, reflection,
             texture_ambient, texture_diffuse, texture_specular, uv_coordinates),
    Δ -> (Δ.color_ambient, Δ.color_diffuse, Δ.color_specular, Δ.specular_exponent,
          Δ.reflection, Δ.texture_ambient, Δ.texture_diffuse, Δ.texture_specular,
          Δ.uv_coordinates)

@adjoint literal_getproperty(m::Material, ::Val{:color_ambient}) =
    getproperty(m, :color_ambient), Δ -> (Material(Δ, zero(m.color_diffuse), zero(m.color_specular),
                                                   zero(m.specular_exponent), zero(m.reflection),
                                                   isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient),
                                                   isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse),
                                                   isnothing(m.texture_specular) ? nothing : zero(m.texture_specular),
                                                   isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)),
                                          nothing)

@adjoint literal_getproperty(m::Material, ::Val{:color_diffuse}) =
    getproperty(m, :color_diffuse), Δ -> (Material(zero(m.color_ambient), Δ, zero(m.color_specular),
                                                   zero(m.specular_exponent), zero(m.reflection),
                                                   isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient),
                                                   isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse),
                                                   isnothing(m.texture_specular) ? nothing : zero(m.texture_specular),
                                                   isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)),
                                          nothing)

@adjoint literal_getproperty(m::Material, ::Val{:color_specular}) =
    getproperty(m, :color_specular), Δ -> (Material(zero(m.color_ambient), zero(m.color_diffuse), Δ,
                                                   zero(m.specular_exponent), zero(m.reflection),
                                                   isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient),
                                                   isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse),
                                                   isnothing(m.texture_specular) ? nothing : zero(m.texture_specular),
                                                   isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)),
                                          nothing)
    
@adjoint literal_getproperty(m::Material, ::Val{:specular_exponent}) =
    getproperty(m, :specular_exponent), Δ -> (Material(zero(m.color_ambient), zero(m.color_diffuse),
                                                       zero(m.color_specular), Δ, zero(m.reflection),
                                                       isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient),
                                                       isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse),
                                                       isnothing(m.texture_specular) ? nothing : zero(m.texture_specular),
                                                       isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)),
                                              nothing)

@adjoint literal_getproperty(m::Material, ::Val{:reflection}) =
    getproperty(m, :reflection), Δ -> (Material(zero(m.color_ambient), zero(m.color_diffuse),
                                                zero(m.color_specular), zero(m.specular_exponent), Δ,
                                                isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient),
                                                isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse),
                                                isnothing(m.texture_specular) ? nothing : zero(m.texture_specular),
                                                isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)),
                                       nothing)

@adjoint literal_getproperty(m::Material, ::Val{:texture_ambient}) =
    getproperty(m, :texture_ambient), Δ -> (Material(zero(m.color_ambient), zero(m.color_diffuse),
                                                     zero(m.color_specular), zero(m.specular_exponent),
                                                     zero(m.reflection), Δ,
                                                     isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse),
                                                     isnothing(m.texture_specular) ? nothing : zero(m.texture_specular),
                                                     isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)),
                                            nothing)

@adjoint literal_getproperty(m::Material, ::Val{:texture_diffuse}) =
    getproperty(m, :texture_diffuse), Δ -> (Material(zero(m.color_ambient), zero(m.color_diffuse),
                                                     zero(m.color_specular), zero(m.specular_exponent),
                                                     zero(m.reflection),
                                                     isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient), Δ,
                                                     isnothing(m.texture_specular) ? nothing : zero(m.texture_specular),
                                                     isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)),
                                            nothing)

@adjoint literal_getproperty(m::Material, ::Val{:texture_specular}) =
    getproperty(m, :texture_specular), Δ -> (Material(zero(m.color_ambient), zero(m.color_diffuse),
                                                      zero(m.color_specular), zero(m.specular_exponent),
                                                      zero(m.reflection),
                                                      isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient),
                                                      isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse), Δ,
                                                      isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)),
                                             nothing)

@adjoint literal_getproperty(m::Material, ::Val{:uv_coordinates}) =
    getproperty(m, :uv_coordinates), Δ -> (Material(zero(m.color_ambient), zero(m.color_diffuse),
                                                    zero(m.color_specular), zero(m.specular_exponent),
                                                    zero(m.reflection),
                                                    isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient),
                                                    isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse),
                                                    isnothing(m.texture_specular) ? nothing : zero(m.texture_specular),
                                                    Δ),
                                             nothing)
# ------- #
# Objects #
# ------- #

# ---------- #
# - Sphere - #
# ---------- #

@adjoint Sphere(center, radius, material::Material) =
    Sphere(center, radius, material), Δ -> (Δ.sphere, Δ.radius, Δ.material)

@adjoint literal_getproperty(s::Sphere, ::Val{:center}) =
    getproperty(s, :center), Δ -> (Sphere(Δ, zero(s.radius), zero(s.material)), nothing)

@adjoint literal_getproperty(s::Sphere, ::Val{:radius}) =
    getproperty(s, :radius), Δ -> (Sphere(zero(s.center), Δ, zero(s.material)), nothing)

@adjoint literal_getproperty(s::Sphere, ::Val{:material}) =
    getproperty(s, :material), Δ -> (Sphere(zero(s.center), zero(s.radius), Δ), nothing)
    
# ------------ #
# - Triangle - #
# ------------ #
  
@adjoint Triangle(v1, v2, v3, material::Material) =
    Triangle(v1, v2, v3, material), Δ -> (Δ.v1, Δ.v2, Δ.v3, Δ.material)

@adjoint literal_getproperty(t::Triangle, ::Val{:v1}) =
    getproperty(t, :v1), Δ -> (Triangle(Δ, zero(t.v2), zero(t.v3), zero(t.material)), nothing)

@adjoint literal_getproperty(t::Triangle, ::Val{:v2}) =
    getproperty(t, :v2), Δ -> (Triangle(zero(t.v1), Δ, zero(t.v3), zero(t.material)), nothing)

@adjoint literal_getproperty(t::Triangle, ::Val{:v3}) =
    getproperty(t, :v3), Δ -> (Triangle(zero(t.v1), zero(t.v2), Δ, zero(t.material)), nothing)

@adjoint literal_getproperty(t::Triangle, ::Val{:material}) =
    getproperty(t, :material), Δ -> (Triangle(zero(t.v1), zero(t.v2), zero(t.v3), Δ), nothing)

# ---------------- #
# - TriangleMesh - #
# ---------------- #

#=
@adjoint TriangleMesh(tm, mat, ftmp) =
    TriangleMesh(tm, mat, ftmp), Δ -> (Δ.triangulated_mesh, Δ.material, Δ.ftmp)

@adjoint function literal_getproperty(t::TriangleMesh, ::Val{:triangulated_mesh})
    tm = getproperty(t, :triangulated_mesh)
    z = eltype(tm[1].v1.x)
    mat = Material(PlainColor(rgb(z)), z)
    return tm, Δ -> (TriangleMesh(Δ, mat, FixedTriangleMeshParams(IdDict(), [Vec3(z)])), nothing)
end

@adjoint function literal_getproperty(t::TriangleMesh, ::Val{:material})
    mat = getproperty(t, :material)
    z = eltype(t.triangulated_mesh[1].v1.x)
    tm = [Triangle([Vec3(z)]...) for _ in 1:length(t.triangulated_mesh)]
    return mat, Δ -> (TriangleMesh(tm, Δ, FixedTriangleMeshParams(IdDict(), [Vec3(z)])), nothing)
end

@adjoint function literal_getproperty(t::TriangleMesh, ::Val{:ftmp})
    z = eltype(t.triangulated_mesh[1].v1.x)
    mat = Material(PlainColor(rgb(z)), z)
    tm = [Triangle([Vec3(z)]...) for _ in 1:length(t.triangulated_mesh)]
    return getproperty(t, :ftmp), Δ -> (TriangleMesh(tm, mat, Δ), nothing)
end

@adjoint FixedTriangleMeshParams(isect, n) =
    FixedTriangleMeshParams(isect, n), Δ -> (Δ.isect, Δ.n)

# The gradients for this params are never used so fill them with anything as long
# as they are consistent with the types
@adjoint literal_getproperty(ftmp::FixedTriangleMeshParams, ::Val{f}) where {f} =
    getproperty(ftmp, f), Δ -> (FixedTriangleMeshParams(IdDict(), ftmp.normals[1:1]))
=#

# ------ #
# Camera #
# ------ #

@adjoint Camera(lf, la, vfov, focus, fp) =
    Camera(lf, la, vfov, focus, fp), Δ -> (Δ.lookfrom, Δ.lookat, Δ.vfov,
                                           Δ.focus, Δ.fixedparams)

@adjoint literal_getproperty(c::Camera, ::Val{:lookfrom}) =
    getproperty(c, :lookfrom), Δ -> (Camera(Δ, zero(c.lookat), zero(c.vfov), zero(c.focus),
                                            zero(c.fixedparams)), nothing)

@adjoint literal_getproperty(c::Camera, ::Val{:lookat}) =
    getproperty(c, :lookat), Δ -> (Camera(zero(c.lookfrom), Δ, zero(c.vfov), zero(c.focus),
                                          zero(c.fixedparams)), nothing)

@adjoint literal_getproperty(c::Camera, ::Val{:vfov}) =
    getproperty(c, :vfov), Δ -> (Camera(zero(c.lookfrom), zero(c.lookat), Δ, zero(c.focus),
                                        zero(c.fixedparams)), nothing)

@adjoint literal_getproperty(c::Camera, ::Val{:focus}) =
    getproperty(c, :focus), Δ -> (Camera(zero(c.lookfrom), zero(c.lookat), zero(c.vfov), Δ,
                                         zero(c.fixedparams)), nothing)                     

@adjoint literal_getproperty(c::Camera, ::Val{:fixedparams}) =
    getproperty(c, :fixedparams), Δ -> (Camera(zero(c.lookfrom), zero(c.lookat), zero(c.vfov),
                                               zero(c.focus), Δ), nothing)                     

@adjoint FixedCameraParams(vup, w, h) =
    FixedCameraParams(vup, w, h), Δ -> (Δ.vup, Δ.width, Δ.height)

@adjoint literal_getproperty(fcp::FixedCameraParams, ::Val{f}) where {f} =
    getproperty(fcp, f), Δ -> (zero(fcp), nothing)
  
# ------- #	
# ImUtils #	
# ------- #	

@adjoint function zeroonenorm(x)	
    mini, indmin = findmin(x)	
    maxi, indmax = findmax(x)	
    res = (x .- mini) ./ (maxi - mini)	
    function ∇zeroonenorm(Δ)	
        ∇x = similar(x)	
        fill!(∇x, 1 / (maxi - mini))
        res1 = (x .- maxi) ./ (maxi - mini)^2
        ∇x[indmin] = sum(res1) - minimum(res1) 
        res2 = - res ./ (maxi - mini)  
        ∇x[indmax] = sum(res2) - minimum(res2)
        return (∇x .* Δ, )	
    end	
    return res, ∇zeroonenorm	
end

# ----------------- #
# General Functions #
# ----------------- #

for func in (:findmin, :findmax)
    @eval begin
        @adjoint function $(func)(xs::AbstractArray; dims = :)
            y = $(func)(xs, dims = dims)
            function dfunc(Δ)
                res = zero(xs)
                res[y[2]] .= Δ[1]
                return (res, nothing)
            end
            return y, dfunc
        end
    end
end

@adjoint reducehcat(x) = reduce(hcat, x), Δ -> ([Δ[:, i] for i in 1:length(x)], )

@adjoint push!(arr, val) = push!(arr, val), Δ -> (Δ[1:end-1], Δ[end])

@nograd fill

@nograd function update_index!(arr, i, j, val)
    arr[i, j] = val
end 
