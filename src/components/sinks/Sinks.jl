# This file constains sink tools for the objects of Causal.

"""
Includes sink components that sinks data such as writer, scope, printer.

# Imports 

    $(IMPORTS) 

# Exports 

    $(EXPORTS)
"""
module Sinks 

using DocStringExtensions
using Plots, JLD2, DataStructures, UUIDs
using Causal.Utilities
using Causal.Connections 
using Causal.Components.ComponentsBase
import Base: show, print, close, open, read, mv, cp
import Causal.Utilities: write!
import FileIO: load
import UUIDs.uuid4

export @def_sink

"""
    @def_sink ex 

where `ex` is the expression to define to define a new AbstractSink component type. The usage is as follows:
```julia
@def_sink struct MySink{T1,T2,T3,...,TN, A} <: AbstractSink
    param1::T1 = param1_default     # optional field 
    param2::T2 = param2_default     # optional field 
    param3::T3 = param3_default     # optional field
        ⋮
    paramN::TN = paramN_default     # optional field 
    action::A = action_function     # mandatory field
end
```
Here, `MySink` has `N` parameters and `action` function

!!! warning 
    `action` function must have a method `action(sink::MySink, t, u)` where `t` is the time data and `u` is the data flowing into the sink.

!!! warning 
    New static system must be a subtype of `AbstractSink` to function properly.

# Example 
```julia 
julia> @def_sink struct MySink{A} <: AbstractSink 
       action::A = actionfunc
       end

julia> actionfunc(sink::MySink, t, u) = println(t, u)
actionfunc (generic function with 1 method)

julia> sink = MySink();

julia> sink.action(sink, ones(2), ones(2) * 2)
[1.0, 1.0][2.0, 2.0]
```
"""
macro def_sink(ex) 
    ex.args[2].head == :(<:) && ex.args[2].args[2] == :AbstractSink || 
        error("Invalid usage. The type should be a subtype of AbstractSink.\n$ex")
    foreach(nex -> ComponentsBase.appendex!(ex, nex), [
        :( trigger::$TRIGGER_TYPE_SYMBOL = Inpin() ),
        :( handshake::$HANDSHAKE_TYPE_SYMBOL = Outpin{Bool}() ),
        :( callbacks::$CALLBACKS_TYPE_SYMBOL = nothing ),
        :( name::Symbol = Symbol() ),
        :( id::$ID_TYPE_SYMBOL = Sinks.uuid4() ),
        :( input::$INPUT_TYPE_SYMBOL = Inport() ),
        :( buflen::Int = 64 ), 
        :( plugin::$PLUGIN_TYPE_SYMBOL = nothing ), 
        :( timebuf::$TIMEBUF_TYPE_SYMBOL = Buffer(buflen)  ), 
        :( databuf::$DATABUF_TYPE_SYMBOL = Buffer(datatype(input), buflen)  ), 
        :( sinkcallback::$SINK_CALLBACK_TYPE_SYMBOL = plugin === nothing ? 
            Callback(sink->ishit(databuf), sink->action(sink, timebuf.output, databuf.output), true, id) :
            Callback(sink->ishit(databuf), sink->action(sink, timebuf.output, plugin.process(databuf.output)), true, 
            id) ), 
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end

include("writer.jl")
include("printer.jl")
include("scope.jl")

end # module 