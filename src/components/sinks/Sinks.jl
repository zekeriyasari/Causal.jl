# This file constains sink tools for the objects of Jusdl.

@reexport module Sinks

using DataStructures
using Reexport
using Plots
using JLD2
using UUIDs
import Base: write, read, close, setproperty!, mv, cp, open, show
import FileIO: load
import ....Jusdl.Components.Base: @generic_sink_fields, AbstractSink, update!
import ....Jusdl.Utilities: write!, snapshot, Buffer, Callback, isfull
import ....Jusdl.Connections: Link, Bus
import ....Jusdl.Plugins: process

 
function addplugin(sink::AbstractSink, actionfunc)
    condition(sink) = isfull(sink.databuf) 
    if sink.plugin === nothing
        action = sink -> actionfunc(sink, snapshot(sink.timebuf), snapshot(sink.databuf))
    else
        action = sink -> actionfunc(sink, snapshot(sink.timebuf), process(sink.plugin, snapshot(sink.databuf)))
    end
    clb = Callback(condition, action)
    clb.id = sink.id
    push!(sink.callbacks, clb)
    sink
end

deleteplugin(sink::AbstractSink) = deleteat!(sink.callbacks, [clb.id == sink.id for clb in sink.callbacks])

export Writer, Printer, Scope, write!, fwrite, fread, flatten

include("writer.jl")
include("printer.jl")
include("scope.jl")

end  # module
