using Documenter, Jusdl
# using DocumenterLaTeX

DocMeta.setdocmeta!(Jusdl, :DocTestSetup, :(using Jusdl); recursive=true)

makedocs(
    modules=[Jusdl], 
    sitename="Jusdl",
    pages=[
        "Home" => "index.md",
        "Modeling and Simulation in Jusdl" => [
            "modeling_and_simulation/modeling.md",
            "modeling_and_simulation/simulation.md",
        ],
        "Tutorials" => [
            "Model Construction" => "tutorials/model_construction.md",
            "Model Simulation" => "tutorials/model_simulation.md",
            "Algebraic Loops" => "tutorials/algebraic_loops.md",
            "Enlarging The Library" => "tutorials/defining_new_components.md",
            "Coupled Systems" => "tutorials/coupled_systems.md",
        ],
        "Manual" => [
            "Utilities" => [
                "manual/utilities/callback.md",
                "manual/utilities/buffers.md"
            ], 
            "Connections" => [
                "manual/connections/link.md",
                "manual/connections/pin.md",
                "manual/connections/port.md",
            ],
            "Components" => [
                "ComponentsBase" => [
                    "manual/components/componentsbase/hierarchy.md",
                    "manual/components/componentsbase/evolution.md",
                    "manual/components/componentsbase/interpolation.md",
                ],
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
                "Systems" => [
                    "StaticSystems" => [
                        "StaticSystems" => "manual/components/systems/staticsystems/staticsystems.md",
                        # "Subsystem" => "manual/components/systems/staticsystems/subsystem.md",
                    ],
                    "DynamicSystems" => [
                        "DiscreteSystem" => "manual/components/systems/dynamicsystems/discretesystem.md",
                        "ODESystem" => "manual/components/systems/dynamicsystems/odesystem.md",
                        "DAESystem" => "manual/components/systems/dynamicsystems/daesystem.md",
                        "RODESystem" => "manual/components/systems/dynamicsystems/rodesystem.md",
                        "SDESystem" => "manual/components/systems/dynamicsystems/sdesystem.md",
                        "DDESystem" => "manual/components/systems/dynamicsystems/ddesystem.md",
                    ],
                ]
            ],
            "Models" => [
                "manual/models/taskmanager.md",
                "manual/models/simulation.md",
                "manual/models/model.md",
            ],
            "Plugins" => "manual/plugins/plugins.md",
        ]   
    ]
)

deploydocs(;
    repo="github.com/zekeriyasari/Jusdl.jl.git",
    devbranch = "master",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#", "v#.#.#"]
)
