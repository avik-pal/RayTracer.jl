export load_obj

# ---------------- #
# - Polygon Mesh - #
# ---------------- #

# Return a vector of triangles
function load_obj(filename)
    # Ignore texture coordinates for now
    object = load(filename)
    scene = [Triangle(Vec3(object.vertices[face[1]]...),
                      Vec3(object.vertices[face[2]]...),
                      Vec3(object.vertices[face[3]]...)) for face in object.faces]
    return scene
end
