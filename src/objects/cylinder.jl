export Cylinder

# ------------ #
# - Cylinder - #
# ------------ #

# FIXME: Cylinder rendering behaves wierdly. So its better not to use this
#        currently.
struct Cylinder{C, P, Q, R, S, T, U} <: Object
    center::Vec3{C}
    radius::C
    axis::Vec3{C}
    length::C
    material::Material{P, Q, R, S, T, U}
end

show(io::IO, c::Cylinder) =
    print(io, "Cylinder Object:\n    Center - ", c.center, "\n    Radius - ", c.radius[],
          "\n    Axis - ", c.axis, "\n    Length - ", c.length[], "\n    ", c.material)

@diffops Cylinder

# TODO: Currently Cylinder means Hollow Cylinder. Generalize for Solid Cylinder
#       The easiest way to do this would be to treat Solid Cylinder as 3 different
#       objects - Hollow Cylinder + 2 Solid Discs
function intersect(cy::Cylinder, origin, direction)
    diff = origin - cy.center
    a_vec = direction - dot(cy.axis, direction) * cy.axis
    c_vec = diff - dot(diff, cy.axis) * cy.axis 
    a = 2 .* l2norm(a_vec) # No point in doing 2 .* a everywhere so doing it here itself
    b = 2 .* dot(a_vec, c_vec)
    c = l2norm(c_vec) .- (cy.radius[] ^ 2)
    disc = (b .^ 2) .- 2 .* a .* c
    
    sq = sqrt.(max.(disc, 0.0f0))
    h₀ = (-b .- sq) ./ a
    h₁ = (-b .+ sq) ./ a
    zt1 = dot(origin + direction * h₀, cy.axis)
    center_comp = dot(cy.center, cy.axis)[1] # Will return an array
    zmax = center_comp + cy.length[] / 2
    zmin = center_comp - cy.length[] / 2
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

