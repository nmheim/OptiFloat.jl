using Documenter, DocumenterVitepress

using OptiFloat

makedocs(;
    modules=[OptiFloat],
    authors="Niklas Heim",
    repo="https://github.com/nmheim/OptiFloat.jl",
    sitename="OptiFloat.jl",
    format=DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/nmheim/OptiFloat.jl",
        devurl = "dev",
        deploy_url = "nmheim.github.io/OptiFloat.jl",
    ),
    pages=[
        "Home" => "index.md",
    ],
    warnonly = true,
)

deploydocs(;
    repo="github.com/nmheim/OptiFloat.jl",
    push_preview=true,
)
