using Documenter
using DocumenterVitepress
using OptiFloat

# in repl:
# V

makedocs(;
    sitename="OptiFloat.jl",
    authors="Niklas Heim",
    modules=[OptiFloat],
    warnonly=true,
    checkdocs=:all,
    repo="https://github.com/nmheim/OptiFloat.jl",
    format=DocumenterVitepress.MarkdownVitepress(;
        repo="https://github.com/nmheim/OptiFloat.jl", devbranch="main", devurl="dev"
    ),
    draft=false,
    source="src",
    build="build",
    pages=[
        "Home" => "index.md"
        "Developer Documentation" => "dev.md"
        "API" => "api.md"
    ],
)

deploydocs(;
    repo="github.com/nmheim/OptiFloat.jl",
    target="build",
    branch="gh-pages",
    devbranch="main",
    push_preview=true,
)
