module Causal

using DocStringExtensions

"""
    A modeling and simulation framework a causal models.

# Exports 
    $(EXPORTS)

# Imports
    $(IMPORTS)
"""
Causal

using Reexport 
using UUIDs
using JLD2
using Logging 
using Dates 
using NLsolve
using LightGraphs, GraphPlot    
import Base: show
import ProgressMeter: @showprogress
import DifferentialEquations: reinit!

include("utilities/Utilities.jl")
include("connections/Connections.jl")   
include("components/Components.jl")
include("plugins/Plugins.jl")

@reexport using .Utilities
@reexport using .Connections
@reexport using .Components
@reexport using .Plugins

import .Utilities: clean!

include("utils.jl")
include("taskmanager.jl")
include("simulation.jl")
include("model.jl")

end  # module
