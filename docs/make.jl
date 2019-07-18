using Documenter, RayTracer

makedocs(
    modules = [RayTracer],
    doctest = true,
    sitename = "RayTracer",
    authors = "Avik Pal",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    pages = [
        "Home"              => "index.md",
        "Getting Started"   => [
            "Introduction to Rendering" => "getting_started/teapot_rendering.md",
        ],
        "API Documentation" => [
            "General Utilities"         => "api/utilities.md",
            "Differentiation"           => "api/differentiation.md",
            "Scene Configuration"       => "api/scene.md",
            "Renderers"                 => "api/renderers.md",
            "Optimization"              => "api/optimization.md",
            "Acceleration Structures"   => "api/accelerators.md",
        ],
    ],
)

deploydocs(
    repo = "github.com/avik-pal/RayTracer.jl.git"
)
