module Systems 

using Reexport 

include("staticsystems/StaticSystems.jl")
include("dynamicalsystems/DynamicalSystems.jl")

@reexport using .StaticSystems
@reexport using .DynamicalSystems

end 