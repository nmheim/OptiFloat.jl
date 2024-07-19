#!/usr/bin/env julia

# Root of the repository
const repo_root = dirname(@__DIR__)

# Make sure docs environment is active
using Pkg: Pkg
Pkg.activate(@__DIR__)

# Communicate with docs/make.jl that we are running in live mode
push!(ARGS, "liveserver")

# Run LiveServer.servedocs(...)
using LiveServer: LiveServer
LiveServer.servedocs(;
    # Documentation root where make.jl and src/ are located
    foldername=joinpath(repo_root, "docs"),
)
