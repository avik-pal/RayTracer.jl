using Documenter, RayTracer

makedocs(modules=[RayTracer],
         doctest = false,
         sitename = "RayTracer",
         authors = "Avik Pal",
         # Uncomment below for local build
         format = Documenter.HTML(prettyurls = false,
                                  assets = ["assets/documenter.css"]),
         pages = ["Home" => "index.md",
                  "Getting Started" => [
                      "Rendering" => "getting_started/rendering.md",
                      "Inverse Rendering" => "getting_started/optimization.md"],
                  "API Documentation" => "api.md"])

deploydocs(repo = "github.com/avik-pal/RayTracer.jl.git")
