@reexport module Models

using UUIDs
using Logging
using JLD2
import ..Jusdl.Utilities: Callback
import ..Jusdl.Connections: launch, isconnected, hasslaves
import ..Jusdl.Components.Base: terminate, drive, AbstractSink
import ..Jusdl.Components.Systems.StaticSystems.Memory
import ..Jusdl.Components.Sinks: Writer, deleteplugin
import ..Jusdl.Components.Sources: Clock, isrunning, set!, unset!
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