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

include("submodules/utilities/Utilities.jl")
include("submodules/plugins/Plugins.jl")
include("submodules/connections/Connections.jl")   
include("submodules/components/Components.jl")

@reexport using .Utilities
@reexport using .Plugins
@reexport using .Connections
@reexport using .Components

import .Utilities: clean!
import .Components: righthandside, readout, action 

include("modeling/model.jl")
include("modeling/defmodel.jl")
include("modeling/modification.jl")
include("modeling/visualization.jl")

include("simulation/taskmanager.jl")
include("simulation/simulation.jl")
include("simulation/simulate.jl")
include("simulation/troubleshoot.jl")
include("simulation/stages/inspect.jl")
include("simulation/stages/initialize.jl")
include("simulation/stages/run.jl")
include("simulation/stages/terminate.jl")

end  # module
