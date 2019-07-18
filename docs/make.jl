using Documenter, RayTracer

makedocs(modules=[RayTracer],
         doctest = false,
         sitename = "RayTracer",
         authors = "Avik Pal",
         format = Documenter.HTML(prettyurls = true,
                                  assets = ["assets/documenter.css"]),
         pages = ["Home" => "index.md",
                  "Getting Started" => [
                      "Introduction to Rendering" => "getting_started/teapot_rendering.md"],
                  "API Documentation" => "api.md"])

deploydocs(repo = "github.com/avik-pal/RayTracer.jl.git")
