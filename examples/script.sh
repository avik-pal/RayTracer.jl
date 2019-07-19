#!/bin/bash

# Set up the versions of packages
julia --color=yes -e "using Pkg; Pkg.instantiate()"

WORKDIR=$PWD

# Teapot Rendering
echo "Teapot Rendering Example"

wget https://raw.githubusercontent.com/McNopper/OpenGL/master/Binaries/teapot.obj

julia --project=. --color=yes "teapot_rendering.jl"

# Performance Benchmarks

echo "Performance Benchmarks"

mkdir meshes
cd meshes
wget https://raw.githubusercontent.com/avik-pal/RayTracer.jl/ap/texture/test/meshes/sign_yield.obj
wget https://raw.githubusercontent.com/avik-pal/RayTracer.jl/ap/texture/test/meshes/sign_yield.mtl
cd $WORKDIR

mkdir textures
cd textures
wget https://raw.githubusercontent.com/avik-pal/RayTracer.jl/ap/texture/test/textures/wood_osb.jpg
wget raw.githubusercontent.com/avik-pal/RayTracer.jl/ap/texture/test/textures/sign_yield.png
cd $WORKDIR

julia --project=. --color=yes "performance_benchmarks.jl" -m "./meshes/sign_yield.jl" -g 2

# Inverse Lighting

echo "Inverse Lighting"

cd meshes
wget https://raw.githubusercontent.com/tejank10/Duckietown.jl/master/src/meshes/tree.obj
wget https://raw.githubusercontent.com/tejank10/Duckietown.jl/master/src/meshes/tree.mtl
cd $WORKDIR

julia --project=. --color=yes "inverse_lighting.jl"
julia --project=. --color=yes "optim_compatibility.jl"

