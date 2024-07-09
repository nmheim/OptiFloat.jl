using Pkg

Pkg.activate("docs")
Pkg.add("Documenter")
Pkg.add("DocumenterVitepress")
Pkg.add(url="https://github.com/nmheim/Metatheory.jl.git#ale/3.0")
Pkg.status()
Pkg.add(url="https://github.com/nmheim/DynamicExpressions.jl.git#nh/early-exit")
Pkg.develop(".")
