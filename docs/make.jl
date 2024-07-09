using Documenter, DocumenterVitepress

using OptiFloat

makedocs(;
    sitename="OptiFloat.jl",
    authors="Niklas Heim",
    modules=[OptiFloat],
    warnonly=true,
    repo="https://github.com/nmheim/OptiFloat.jl",
    format=DocumenterVitepress.MarkdownVitepress(;
        repo="https://github.com/nmheim/OptiFloat.jl",
        devurl="dev",
        deploy_url="nmheim.github.io/OptiFloat.jl",
    ),
    build="build",
    pages=["Home" => "index.md"],
)

deploydocs(; repo="github.com/nmheim/OptiFloat.jl", target="build", push_preview=true)
