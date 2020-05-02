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
            "Models and Graphs" => "tutorials/models_and_graphs.md",
            "Simple Model Simulation" => "tutorials/simple_model.md",
            "Breaking Algebraic Loops" => "tutorials/breaking_algebraic_loops.md",
            "Constuction and Simulation of Subsystems" => "tutorials/construction_and_simulation_of_subsystems.md",
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
                        "Subsystem" => "manual/components/systems/staticsystems/subsystem.md",
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
            "Plugins" => "manual/plugins/plugins.md",
            "Models" => [
                "manual/models/taskmanager.md",
                "manual/models/simulation.md",
                "manual/models/model.md",
            ],
        ]   
    ]
)

# makedocs(
#     modules = [Jusdl], 
#     sitename = "Jusdl",
#     pages = [
#         "Home" => "index.md",
#         "Modeling and Simulation in Jusdl" => [
#             "modeling_and_simulation/modeling.md",
#             "modeling_and_simulation/simulation.md",
#             ],
#         "Manual" => [
#             "Utilities" => [
#                 "manual/utilities/callback.md",
#                 "manual/utilities/buffers.md"
#                 ], 
#             "Connections" => [
#                 "manual/connections/link.md",
#                 "manual/connections/pin.md",
#                 "manual/connections/port.md",
#                 ],
#             "Components" => [
#                 "ComponentsBase" => [
#                     "manual/components/componentsbase/evolution.md",
#                     ],
#                 "Sources" => [
#                     "manual/components/sources/clock.md",
#                     "manual/components/sources/generators.md",
#                     ],
#                 "Sinks" => [
#                     "manual/components/sinks/sinks.md",
#                     "manual/components/sinks/writer.md",
#                     "manual/components/sinks/printer.md",
#                     "manual/components/sinks/scope.md",
#                     ],
#                 "Systems" => [
#                     "StaticSystems" => [
#                         "StaticSystems" => "manual/components/systems/staticsystems/staticsystems.md",
#                         "Subsystem" => "manual/components/systems/staticsystems/subsystem.md",
#                         # "Network" => "manual/components/systems/staticsystems/network.md",
#                         ],
#                     "DynamicSystems" => [
#                         "DiscreteSystem" => "manual/components/systems/dynamicsystems/discretesystem.md",
#                         "ODESystem" => "manual/components/systems/dynamicsystems/odesystem.md",
#                         "DAESystem" => "manual/components/systems/dynamicsystems/daesystem.md",
#                         "RODESystem" => "manual/components/systems/dynamicsystems/rodesystem.md",
#                         "SDESystem" => "manual/components/systems/dynamicsystems/sdesystem.md",
#                         "DDESystem" => "manual/components/systems/dynamicsystems/ddesystem.md",
#                         ],
#                     ],
#                 ],
#             "Plugins" => "manual/plugins/plugins.md",
#             "Models" => [
#                 "manual/models/taskmanager.md",
#                 "manual/models/simulation.md",
#                 "manual/models/model.md",
#                 ],
#             ],
        # "Tutorials" => [
        #     "Simple Model Simulation" => "tutorials/simple_model.md",
        #     "Breaking Algebraic Loops" => "tutorials/breaking_algebraic_loops.md",
        #     "Constuction and Simulation of Subsystems" => "tutorials/construction_and_simulation_of_subsystems.md",
        #     "Constuction and Simulation of Networks" => "tutorials/construction_and_simulation_of_networks.md",
        # ],
    # ],
    # format=DocumenterLaTeX.LaTeX()  # Uncomment this option to generate pdf output.
# )  # end makedocs

# deploydocs(repo = "github.com/zekeriyasari/Jusdl.jl.git")
