@reexport module Models

using UUIDs
using Logging
using JLD2
import ..JuSDL.Utilities: Callback
import ..JuSDL.Connections: launch, isconnected, has_slaves
import ..JuSDL.Components.Base: terminate, drive, AbstractSink
import ..JuSDL.Components.Systems.StaticSystems.Memory
import ..JuSDL.Components.Sinks: Writer, delete_callback
import ..JuSDL.Components.Sources: isset, set!, unset!
import Base.run

abstract type AbstractTaskManager end 
abstract type AbstractModel end 
abstract type AbstractSimulation end 

export TaskManager, checktasks, istaskfailed, istaskrunning, isalive
export Model, adjacency_matrix, inspect, initialize, run, terminate, simulate

include("utils.jl")
include("taskmanager.jl")
include("simulation.jl")
include("model.jl")

end  # module