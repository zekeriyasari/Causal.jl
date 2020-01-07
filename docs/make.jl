using Documenter, Jusdl

DocMeta.setdocmeta!(Jusdl, :DocTestSetup, :(using Jusdl); recursive=true)

makedocs(
    modules = [Jusdl], 
    sitename = "Jusdl.jl",
    pages = [
        "Utilities" => [
            "manual/utilities/callback.md",
            "manual/utilities/buffers.md"]
        , 
        "Connections" => [
        "manual/connections/link.md",
        "manual/connections/bus.md",
        ]
    ]
)
