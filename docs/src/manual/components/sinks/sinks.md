# Sinks 

`Sink`s are used to simulation data flowing through the connections of the model. The data processing is done online during the simulation. `Sink` type is a subtype of `AbstractSink`. An `AbstractSink` is also a subtype of `AbstractComponent` (see [Components](@ref)),  so an `AbstractSink` instance has a `trigger` link to be triggered and a `handshake` link to signal that evolution is succeeded. In addition, an `AbstractSink` has an input buffer `inbuf` whose mode is [`Cyclic`](@ref). When an `AbstractSink` instance is triggered through its trigger link, it basically reads its incoming data and writes to its input buffer `inbuf`. When its input buffer `inbuf` is full, the data in `inbuf` is processed according to the type of `AbstractSink`. `Jusdl` provides three concrete subtypes of `AbstractSink` which are [Writer](@ref), [Printer](@ref) and [Scope](@ref). As the operation of an `AbstractSink` just depends on incoming data, an `AbstractSink` does not have an output.

## Full API 
```@docs 
@def_sink
```