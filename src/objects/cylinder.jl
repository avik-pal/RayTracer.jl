export Cylinder, SimpleCylinder, CheckeredCylinder

# ------------ #
# - Cylinder - #
# ------------ #

# FIXME: Cylinder rendering behaves wierdly. So its better not to use this
#        currently.
mutable struct Cylinder{C, R<:Real, L<:Real} <: Object
    center::Vec3{C}
    radius::R
    axis::Vec3{C}
    length::L
    material::Material
end

@diffops Cylinder

# The next 3 functions are just convenience functions for handling
# gradients properly for getproperty function
function Cylinder(v::Vec3{T}, sym::Symbol) where {T}
    z = eltype(T)(0)
    mat = Material(PlainColor(rgb(z)), z)
    if sym == :center
        return Cylinder(v, z, Vec3(z), z, mat)
    else # :axis
        return Cylinder(Vec3(z), z, v, z, mat)
    end
end

function Cylinder(v::T, sym::Symbol) where {T<:Real}
    z = T(0)
    mat = Material(PlainColor(rgb(z)), z)
    if sym == :radius
        return Cylinder(Vec3(z), v, Vec3(z), z, mat)
    else # :length
        return Cylinder(Vec3(z), z, Vec3(z), v, mat)
    end
end

# The symbol is not needed but maintains uniformity
# Set material gradient to be 0
function Cylinder(mat::Material{S, R}, ::Symbol) where {S, R}
    z = R(0)
    mat = Material(PlainColor(rgb(z)), z)
    return Cylinder(Vec3(z), z, Vec3(z), z, mat)
end

# TODO: Currently Cylinder means Hollow Cylinder. Generalize for Solid Cylinder
#       The easiest way to do this would be to treat Solid Cylinder as 3 different
#       objects - Hollow Cylinder + 2 Solid Discs
function intersect(cy::Cylinder, origin, direction)
    diff = origin - cy.center
    a_vec = direction - dot(cy.axis, direction) * cy.axis
    c_vec = diff - dot(diff, cy.axis) * cy.axis 
    a = 2 .* l2norm(a_vec) # No point in doing 2 .* a everywhere so doing it here itself
    b = 2 .* dot(a_vec, c_vec)
    c = l2norm(c_vec) .- (cy.radius ^ 2)
    disc = (b .^ 2) .- 2 .* a .* c
    
    sq = sqrt.(max.(disc, 0.0f0))
    h₀ = (-b .- sq) ./ a
    h₁ = (-b .+ sq) ./ a
    zt1 = dot(origin + direction * h₀, cy.axis)
    center_comp = dot(cy.center, cy.axis)[1] # Will return an array
    zmax = center_comp + cy.length / 2
    zmin = center_comp - cy.length / 2
    zt2 = dot(origin + direction * h₁, cy.axis)
    
    function get_intersections(d, z1, z2, zt1, zt2)
        t = bigmul(d + z1 + z2 + zt1 + zt2)
        if d > 0
            if z1 <= 0 && z2 > 0 && zmin <= zt2 <= zmax
                t = z2
            elseif z1 > 0
                if zmin <= zt1 <= zmax
                    t = z1
                elseif z2 > 0 && zmin <= zt2 <= zmax
                    t = z2
                end
            end
        end
        return t
    end
    result = broadcast(get_intersections, disc, h₀, h₁, zt1, zt2)
    return result
end

function get_normal(c::Cylinder, pt, dir)
    pt_c = pt - c.center
    return normalize(pt_c - dot(pt_c, c.axis) * c.axis)
end

# --------------------- #
# -- Helper Function -- #
# --------------------- #

function SimpleCylinder(center, radius, axis; color = rgb(0.5f0), reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Cylinder(center, radius, normalize(axis), l2norm(axis)[1], mat)
end

function SimpleCylinder(center, radius, axis, length; color = rgb(0.5f0),
                        reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Cylinder(center, radius, normalize(axis), length, mat)
end

function CheckeredCylinder(center, radius, axis; color1 = rgb(0.1f0), color2 = rgb(0.9f0),
                           reflection = 0.5f0)
    mat = Material(CheckeredSurface(color1, color2), reflection)
    return Cylinder(center, radius, normalize(axis), l2norm(axis)[1], mat)
end

function CheckeredCylinder(center, radius, axis, length; color1 = rgb(0.1f0),
                          color2 = rgb(0.9f0), reflection = 0.5f0)
    mat = Material(CheckeredSurface(color1, color2), reflection)
    return Cylinder(center, radius, normalize(axis), length, mat)
end

