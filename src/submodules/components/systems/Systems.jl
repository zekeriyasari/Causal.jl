"""
Includes static and dynamic system components.

# Imports 
    $(IMPORTS) 

# Exports 

    $(EXPORTS)
"""
module Systems 

using DocStringExtensions
using Reexport 

include("staticsystems/StaticSystems.jl")
include("dynamicalsystems/DynamicalSystems.jl")

@reexport using .StaticSystems
@reexport using .DynamicalSystems

end 