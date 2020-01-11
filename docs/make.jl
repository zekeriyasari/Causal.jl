using Documenter, Jusdl
using DocumenterLaTeX

DocMeta.setdocmeta!(Jusdl, :DocTestSetup, :(using Jusdl); recursive=true)

makedocs(
    modules = [Jusdl], 
    sitename = "Jusdl.jl",
    pages = [
        "Home" => "index.md",
        "Utilities" => [
            "manual/utilities/callback.md",
            "manual/utilities/buffers.md"
            ], 
        "Connections" => [
            "manual/connections/link.md",
            "manual/connections/bus.md",
            ],
        "Components" => [
            "Sources" => [
                "manual/components/sources/clock.md",
                "manual/components/sources/generators.md",
            ],
            "Sinks" => [
                "manual/components/sinks/sinks.md",
                "manual/components/sinks/writer.md",
                "manual/components/sinks/printer.md",
                "manual/components/sinks/scope.md",
            ],
            "Plugins" => "manual/plugins/plugins.md",
        ]
    ],
    # format=DocumenterLaTeX.LaTeX()  # Uncomment this option to generate pdf output.
)  # end makedocs
