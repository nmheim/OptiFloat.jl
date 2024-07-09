using Pkg

Pkg.activate("docs")
Pkg.status()
Pkg.add("Documenter")
Pkg.add("DocumenterVitepress")
Pkg.add(url="https://github.com/nmheim/Metatheory.jl.git", rev="ale/3.0")
Pkg.add(url="https://github.com/nmheim/DynamicExpressions.jl.git", rev="nh/early-exit")
Pkg.develop(path=".")
