# This file constains sink tools for the objects of JuSDL.

@reexport module Sinks

using DataStructures
using Reexport
using Plots
using JLD2
using UUIDs
import Base: write, read, close, setproperty!, mv, cp, open
import FileIO: load
import ....JuSDL.Components.Base: @generic_sink_fields, AbstractSink, update!
import ....JuSDL.Utilities: write!, snapshot, Buffer, Callback, isfull
import ....JuSDL.Connections: Link, Bus
import ....JuSDL.Plugins: process

 
function addplugin(sink::AbstractSink, actionfunc)
    condition(sink) = isfull(sink.databuf) 
    if sink.plugin === nothing
        action = sink -> actionfunc(sink, reverse(snapshot(sink.timebuf), dims=1), 
            reverse(snapshot(sink.databuf), dims=1))
    else
        action = sink -> actionfunc(sink, reverse(snapshot(sink.timebuf), dims=1), 
            process(sink.plugin, reverse(snapshot(sink.databuf), dims=1)))
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
