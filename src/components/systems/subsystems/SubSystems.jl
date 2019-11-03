@reexport module SubSystems

using UUIDs
using LightGraphs, LinearAlgebra, GraphPlot
import ..Systems: checkandshow
import ..Systems.StaticSystems: Memory, Coupler, StaticSystem
import ....Components.Base: @generic_system_fields, AbstractSubSystem, AbstractDynamicSystem
import ......Jusdl.Connections: Link, Bus, connect
import ......Jusdl.Utilities: Callback

include("subsystem.jl")
include("network.jl")

export SubSystem, Network, uniformconnectivity, cgsconnectivity, clusterconnectivity, coupling, gplot
export deletelink, changeweight, maketimevarying

end