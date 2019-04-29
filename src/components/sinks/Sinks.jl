# This file constains sink tools for the objects of JuSDL.

@reexport module Sinks

using Reexport
using Plots
using JLD2
import Base: write, read, close, setproperty!, mv, cp, open
import FileIO: load
import UUIDs: uuid4
import ....JuSDL.Components.Base: @generic_sink_fields, AbstractSink, update!
import ....JuSDL.Utilities: write!, snapshot, Buffer, Callback, isfull
import ....JuSDL.Connections: Link, Bus
import ....JuSDL.Plugins: process


function add_callback(sink::AbstractSink, actionfunc)
    condition(sink) = isfull(sink.databuf) 
    if sink.plugin == nothing
        action = sink -> actionfunc(sink, reverse(snapshot(sink.timebuf), dims=1), 
            reverse(snapshot(sink.databuf), dims=1))
    else
        action = sink -> actionfunc(sink, reverse(snapshot(sink.timebuf), dims=1), 
            process(sink.plugin, reverse(snapshot(sink.databuf), dims=1)))
    end
    push!(sink.callbacks, Callback(condition, action, name=sink.name))
    sink
end

delete_callback(sink::AbstractSink) = deleteat!(sink.callbacks, [clb.name == sink.name for clb in sink.callbacks])

export Writer, Printer, Scope, write!, fwrite, fread

include("writer.jl")
include("printer.jl")
include("scope.jl")

end  # module