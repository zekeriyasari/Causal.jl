using Documenter, Jusdl

DocMeta.setdocmeta!(Jusdl, :DocTestSetup, :(using Jusdl); recursive=true)

makedocs(modules = [Jusdl], sitename = "Jusdl.jl")
