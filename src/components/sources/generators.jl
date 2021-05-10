# This file contains the function generator tools to drive other tools of DsSimulator.

import UUIDs: uuid4

"""
    @def_source ex 

where `ex` is the expression to define to define a new AbstractSource component type. The usage is as follows:
```julia
@def_source struct MySource{T1,T2,T3,...,TN,OP, RO} <: AbstractSource
    param1::T1 = param1_default     # optional field 
    param2::T2 = param2_default     # optional field 
    param3::T3 = param3_default     # optional field
        ⋮
    paramN::TN = paramN_default     # optional field 
    output::OP = output_default     # mandatory field 
    readout::RO = readout_function  # mandatory field
end
```
Here, `MySource` has `N` parameters, an `output` port and a `readout` function.

!!! warning 
    `output` and `readout` are mandatory fields to define a new source. The rest of the fields are the parameters of the source.

!!! warning 
    `readout` must be a single-argument function, i.e. a function of time `t`.

!!! warning 
    New source must be a subtype of `AbstractSource` to function properly.

# Example 
```julia 
julia> @def_source struct MySource{OP, RO} <: AbstractSource
       a::Int = 1 
       b::Float64 = 2. 
       output::OP = Outport() 
       readout::RO = t -> (a + b) * sin(t)
       end

julia> gen = MySource();

julia> gen.a 
1

julia> gen.output
1-element Outport{Outpin{Float64}}:
 Outpin(eltype:Float64, isbound:false)
```
"""
macro def_source(ex) 
    ex.args[2].head == :(<:) && ex.args[2].args[2] == :AbstractSource || 
        error("Invalid usage. The type should be a subtype of AbstractSource.\n$ex")
    foreach(nex -> appendex!(ex, nex), [
        :( trigger::$TRIGGER_TYPE_SYMBOL = Inpin() ),
        :( handshake::$HANDSHAKE_TYPE_SYMBOL = Outpin{Bool}() ),
        :( callbacks::$CALLBACKS_TYPE_SYMBOL = nothing ),
        :( name::Symbol = Symbol() ),
        :( id::$ID_TYPE_SYMBOL = Causal.uuid4() )
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end


##### Define Sources library
"""
    $TYPEDEF

Constructs a generic function generator with `readout` function and `output` port.

# Fields 

    $TYPEDFIELDS

# Example 
```jldoctest 
julia> gen = FunctionGenerator(readout = t -> [t, 2t], output = Outport(2));

julia> gen.readout(1.)
2-element Array{Float64,1}:
 1.0
 2.0
```
"""
@def_source struct FunctionGenerator{RO, OP<:Outport} <: AbstractSource 
    "Readout function"
    readout::RO 
    "Output port"
    output::OP = Outport(1)    
end

 """
    $SIGNATURES

Constructs a `SinewaveGenerator` with output of the form
```math 
    x(t) = A sin(2 \\pi f  (t - \\tau) + \\phi) + B
```
where ``A`` is `amplitude`, ``f`` is `frequency`, ``\\tau`` is `delay` and ``\\phi`` is `phase` and ``B`` is `offset`.

# Fields 

    $TYPEDFIELDS
"""
@def_source struct SinewaveGenerator{T1 <: Real, 
                                     T2 <: Real, 
                                     T3 <: Real, 
                                     T4 <: Real, 
                                     T5 <: Real, 
                                     OP <: Outport,
                                     RO} <: AbstractSource
   "Amplitude"
    amplitude::T1 = 1.
    "Frequency"
    frequency::T2 = 1. 
    "Phase"
    phase::T3 = 0. 
    "Delay in seconds"
    delay::T4 = 0. 
    "Offset"
    offset::T5 = 0.
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (t, amplitude=amplitude, frequency=frequency, delay=delay, offset=offset) ->
        amplitude * sin(2 * pi * frequency * (t - delay) + phase) + offset 
end

"""
    $TYPEDEF

Constructs a `DampedSinewaveGenerator` which generates outputs of the form 
```math 
    x(t) = A e^{\\alpha t} sin(2 \\pi f (t - \\tau) + \\phi) + B
```
where ``A`` is `amplitude`, ``\\alpha`` is `decay`, ``f`` is `frequency`, ``\\phi`` is `phase`, ``\\tau`` is `delay` 
and ``B`` is `offset`.

# Fields 

    $TYPEDFIELDS
"""
@def_source struct DampedSinewaveGenerator{T1 <: Real,
                                           T2 <: Real, 
                                           T3 <: Real, 
                                           T4 <: Real, 
                                           T5 <: Real, 
                                           T6 <: Real, 
                                           OP <: Outport, 
                                           RO} <: AbstractSource
    "Amplitude"
    amplitude::T1 = 1. 
    "Attenuation rate"
    decay::T2 = 0.5 
    "Frequency"
    frequency::T3 = 1. 
    "Phase"
    phase::T4 = 0. 
    "Delay in seconds"
    delay::T5 = 0. 
    "Offset"
    offset::T6 = 0.
    "Output port"
    output::OP = Outport()
    "Readout funtion"
    readout::RO = (t, amplitude=amplitude, decay=decay, frequency=frequency, phase=phase, delay=delay, offset=offset) ->
        amplitude * exp(decay * t) * sin(2 * pi * frequency * (t - delay)) + offset
end


"""
    $TYPEDEF

Constructs a `SquarewaveGenerator` with output of the form 
```math 
    x(t) = \\left\\{\\begin{array}{lr}
	A_1 + B, &  kT + \\tau \\leq t \\leq (k + \\alpha) T + \\tau \\\\
	A_2 + B,  &  (k + \\alpha) T + \\tau \\leq t \\leq (k + 1) T + \\tau	
	\\end{array} \\right. \\quad k \\in Z
```
where ``A_1``, ``A_2`` is `level1` and `level2`, ``T`` is `period`, ``\\tau`` is `delay` ``\\alpha`` is `duty`. 

# Fields 

    $TYPEDFIELDS
"""
@def_source struct SquarewaveGenerator{T1 <: Real, 
                                       T2 <: Real, 
                                       T3 <: Real, 
                                       T4 <: Real, 
                                       T5 <: Real, 
                                       OP <: Outport, 
                                       RO} <: AbstractSource
    "High level"
    high::T1 = 1. 
    "Low level"
    low::T2 = 0. 
    "Period"
    period::T3 = 1. 
    "Duty cycle given in range (0, 1)"
    duty::T4 = 0.5
    "Delay in seconds"
    delay::T5 = 0. 
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (t, high=high, low=low, period=period, duty=duty, delay=delay) -> 
        t <= delay ? low : ( ((t - delay) % period <= duty * period) ? high : low )
end


"""
    $TYPEDEF

Constructs a `TriangularwaveGenerator` with output of the form
```math 
    x(t) = \\left\\{\\begin{array}{lr}
	\\dfrac{A t}{\\alpha T} + B, &  kT + \\tau \\leq t \\leq (k + \\alpha) T + \\tau \\\\[0.25cm]
	\\dfrac{A (T - t)}{T (1 - \\alpha)} + B,  &  (k + \\alpha) T + \\tau \\leq t \\leq (k + 1) T + \\tau	
	\\end{array} \\right. \\quad k \\in Z
```
where ``A`` is `amplitude`, ``T`` is `period`, ``\\tau`` is `delay` ``\\alpha`` is `duty`. 

# Fields 

    $TYPEDFIELDS
"""
@def_source struct TriangularwaveGenerator{T1 <: Real, 
                                           T2 <: Real, 
                                           T3 <: Real, 
                                           T4 <: Real, 
                                           T5 <: Real, 
                                           OP <: Outport, 
                                           RO} <: AbstractSource
    "Amplitude"
    amplitude::T1 =  1. 
    "Period"
    period::T2 = 1. 
    "Duty cycle"
    duty::T3 = 0.5 
    "Delay in seconds"
    delay::T4 = 0. 
    "Offset"
    offset::T5 = 0.
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (t, amplitude=amplitude, period=period, duty=duty, delay=delay, offset=offset) -> begin 
        if t <= delay
            return offset
        else
            t = (t - delay) % period 
            if t <= duty * period
                amplitude / (duty * period) * t + offset
            else
                (amplitude * (period - t)) / (period * (1 - duty)) + offset
            end
        end
    end
end


"""
    $TYPEDEF

Constructs a `ConstantGenerator` with output of the form
```math 
    x(t) = A
```
where ``A`` is `amplitude.

# Fields 

    $TYPEDFIELDS
"""
@def_source struct ConstantGenerator{T1 <: Real, OP <: Outport, RO} <: AbstractSource
    "Amplitude"
    amplitude::T1 = 1. 
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (t, amplitude=amplitude) -> amplitude
end


"""
    $TYPEDEF

Constructs a `RampGenerator` with output of the form
```math 
    x(t) = \\alpha (t - \\tau)
```
where ``\\alpha`` is the `scale` and ``\\tau`` is `delay`.

# Fields 

    $TYPEDFIELDS
"""
@def_source struct RampGenerator{T1 <: Real, 
                                 T2 <: Real, 
                                 T3 <: Real, 
                                 OP <: Outport, 
                                 RO} <: AbstractSource
    "Scale"
    scale::T1 = 1.
    "Delay in seconds"
    delay::T2 = 0.
    "Offset"
    offset::T3 = 0.
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (t, scale=scale, delay=delay, offset=offset) ->  scale * (t - delay) + offset
end


"""
    $TYPEDEF

Constructs a `StepGenerator` with output of the form 
```math
    x(t) = \\left\\{\\begin{array}{lr}
	B, &  t \\leq \\tau  \\\\
	A + B,  &  t > \\tau
	\\end{array} \\right.
```
where ``A`` is `amplitude`, ``B`` is the `offset` and ``\\tau`` is the `delay`.

# Fields 

    $TYPEDFIELDS
"""
@def_source struct StepGenerator{T1 <: Real, 
                                 T2 <: Real, 
                                 T3 <: Real,
                                 OP <: Outport, 
                                 RO} <: AbstractSource
    "Amplitude"
    amplitude::T1 = 1. 
    "Delay in seconds"
    delay::T2 = 0. 
    "Offset"
    offset::T3 = 0.
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (t, amplitude=amplitude, delay=delay, offset=offset) -> 
        t - delay >= 0 ? amplitude + offset : offset
end


"""
    $TYPEDEF

Constructs an `ExponentialGenerator` with output of the form
```math 
    x(t) = A e^{\\alpha (t - \\tau)}
```
where ``A`` is `scale`, ``\\alpha`` is `decay` and ``\\tau`` is `delay`.

# Fields 

    $TYPEDFIELDS
"""
@def_source struct ExponentialGenerator{T1 <: Real, 
                                        T2 <: Real, 
                                        T3 <: Real,
                                        T4 <: Real,
                                        OP <: Outport, 
                                        RO} <: AbstractSource
    "Scale"
    scale::T1 = 1. 
    "Attenuation decay"
    decay::T2 = -1. 
    "Delay in seconds"
    delay::T3 = 0.
    "Offset"
    offset::T4 = 0.
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (t, scale=scale, decay=decay, delay=delay, offset=offset) -> scale * exp(decay * (t - delay)) + offset
end


"""
    $TYPEDEF 

Constructs an `DampedExponentialGenerator` with outpsuts of the form 
```math 
    x(t) = A (t - \\tau) e^{\\alpha (t - \\tau)}
```
where ``A`` is `scale`, ``\\alpha`` is `decay`, ``\\tau`` is `delay`.

# Fields 

    $TYPEDFIELDS
"""
@def_source struct DampedExponentialGenerator{T1 <: Real, 
                                              T2 <: Real, 
                                              T3 <: Real,
                                              T4 <: Real,
                                              OP <: Outport, 
                                              RO} <: AbstractSource
    "Scale"
    scale::T1 = 1.
    "Attenuation rate"
    decay::T2 = -1. 
    "Delay in seconds"
    delay::T3 = 0.
    "Offet"
    offset::T4 = 0.
    "Output port"
    output::OP = Outport()
    "Reaodout function"
    readout::RO = (t, scale=scale, decay=decay, delay=delay, offset=offset) -> 
        scale * (t - delay) * exp(decay * (t - delay)) + offset
end


##### Pretty-Printing of generators.

show(io::IO, gen::FunctionGenerator) = print(io, 
    "FunctionGenerator(readout:$(gen.readout),  output:$(gen.output))")
show(io::IO, gen::SinewaveGenerator) = print(io, 
    "SinewaveGenerator(amp:$(gen.amplitude), freq:$(gen.frequency), phase:$(gen.phase), ",
    "offset:$(gen.offset), delay:$(gen.delay))")
show(io::IO, gen::DampedSinewaveGenerator) = print(io, 
    "DampedSinewaveGenerator(amp:$(gen.amplitude), decay:$(gen.delay), freq:$(gen.frequency), ", 
    "phase:$(gen.phase), delay:$(gen.delay), offset:$(gen.offset))")
show(io::IO, gen::SquarewaveGenerator) = print(io, 
    "SquarewaveGenerator(high:$(gen.high), low:$(gen.low), period:$(gen.period), duty:$(gen.duty), ",   
    "delay:$(gen.delay))")
show(io::IO, gen::TriangularwaveGenerator) = print(io, 
    "TriangularwaveGenerator(amp:$(gen.amplitude), period:$(gen.period), duty:$(gen.duty), ", 
    "delay:$(gen.delay), offset:$(gen.offset))")
show(io::IO, gen::ConstantGenerator) = print(io, 
    "ConstantGenerator(amp:$(gen.amplitude))")
show(io::IO, gen::RampGenerator) = print(io, "RampGenerator(scale:$(gen.scale), delay:$(gen.delay))")
show(io::IO, gen::StepGenerator) = print(io, 
    "StepGenerator(amp:$(gen.amplitude), delay:$(gen.delay), offset:$(gen.offset))")
show(io::IO, gen::ExponentialGenerator) = print(io, 
    "ExponentialGenerator(scale:$(gen.scale), decay:$(gen.decay), delay:$(gen.delay))")
show(io::IO, gen::DampedExponentialGenerator) = print(io, 
    "DampedExponentialGenerator(scale:$(gen.scale), decay:$(gen.decay), delay:$(gen.delay))")
