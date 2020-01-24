@reexport module Models

using UUIDs
using Logging
using JLD2
import ..Jusdl.Utilities: Callback
import ..Jusdl.Connections: launch, isconnected, hasslaves, release
import ..Jusdl.Components.ComponentsBase: terminate, drive, AbstractSink, AbstractComponent, AbstractSubSystem, approve
import ..Jusdl.Components.Systems.StaticSystems.Memory
import ..Jusdl.Components.Sinks: Writer, deleteplugin
import ..Jusdl.Components.Sources: Clock, isrunning, set!, stop!
import Base: run, show

export ComponentTask
export TaskManager, checktaskmanager, istaskfailed, istaskrunning
export Model, adjacency_matrix, inspect, initialize, run, terminate, simulate
export findin, addcomponent

include("utils.jl")
include("taskmanager.jl")
include("simulation.jl")
include("model.jl")

end  # module