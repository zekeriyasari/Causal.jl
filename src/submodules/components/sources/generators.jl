# This file contains the function generator tools to drive other tools of DsSimulator.

export @def_source, FunctionGenerator, SinewaveGenerator, DampedSinewaveGenerator, SquarewaveGenerator, 
    TriangularwaveGenerator, ConstantGenerator, RampGenerator, StepGenerator, ExponentialGenerator, 
    DampedExponentialGenerator, PCM

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
    `readout` must be a single-argument function, i.e. a fucntion of time `t`.

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
    foreach(nex -> ComponentsBase.appendex!(ex, nex), [
        :( trigger::$TRIGGER_TYPE_SYMBOL = Inpin() ),
        :( handshake::$HANDSHAKE_TYPE_SYMBOL = Outpin{Bool}() ),
        :( callbacks::$CALLBACKS_TYPE_SYMBOL = nothing ),
        :( name::Symbol = Symbol() ),
        :( id::$ID_TYPE_SYMBOL = Sources.uuid4() )
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end


##### Define Sources library
"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

# Example 
```julia 
julia> gen = FunctionGenerator(readout = t -> [t, 2t], output = Outport(2));

julia> gen.readout(1.)
2-element Array{Float64,1}:
 1.0
 2.0
```
"""
@def_source struct FunctionGenerator{RO, OP} <: AbstractSource 
    readout::RO 
    output::OP = Outport{typeof(readout(0.))}()  
end

"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`SinewaveGenerator` generates output of the form
```math 
    x(t) = A sin(2 \\pi f  (t - \\tau) + \\phi) + B
```
where ``A`` is `amplitude`, ``f`` is `frequency`, ``\\tau`` is `delay` and ``\\phi`` is `phase` and ``B`` is `offset`.
"""
@def_source struct SinewaveGenerator{RO, OP} <: AbstractSource
    amplitude::Float64 = 1.
    frequency::Float64 = 1. 
    phase::Float64 = 0. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, amplitude=amplitude, frequency=frequency, delay=delay, offset=offset) ->
        amplitude * sin(2 * pi * frequency * (t - delay) + phase) + offset
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`DampedSinewaveGenerator` generates outputs of the form 
```math 
    x(t) = A e^{\\alpha t} sin(2 \\pi f (t - \\tau) + \\phi) + B
```
where ``A`` is `amplitude`, ``\\alpha`` is `decay`, ``f`` is `frequency`, ``\\phi`` is `phase`, ``\\tau`` is `delay` and ``B`` is `offset`.
"""
@def_source struct DampedSinewaveGenerator{RO, OP} <: AbstractSource
    amplitude::Float64 = 1. 
    decay::Float64 = 0.5 
    frequency::Float64 = 1. 
    phase::Float64 = 0. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, amplitude=amplitude, decay=decay, frequency=frequency, phase=phase, delay=delay, offset=offset) ->
        amplitude * exp(decay * t) * sin(2 * pi * frequency * (t - delay)) + offset
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

    `SquarewaveGenerator` generates output of the form 
```math 
    x(t) = \\left\\{\\begin{array}{lr}
	A_1 + B, &  kT + \\tau \\leq t \\leq (k + \\alpha) T + \\tau \\
	A_2 + B,  &  (k + \\alpha) T + \\tau \\leq t \\leq (k + 1) T + \\tau	
	\\end{array} \\right. \\quad k \\in Z
```
where ``A_1``, ``A_2`` is `level1` and `level2`, ``T`` is `period`, ``\\tau`` is `delay` ``\\alpha`` is `duty`. 
"""
@def_source struct SquarewaveGenerator{OP, RO} <: AbstractSource
    high::Float64 = 1. 
    low::Float64 = 0. 
    period::Float64 = 1. 
    duty::Float64 = 0.5
    delay::Float64 = 0. 
    output::OP = Outport()
    readout::RO = (t, high=high, low=low, period=period, duty=duty, delay=delay) -> 
        t <= delay ? low : ( ((t - delay) % period <= duty * period) ? high : low )
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

    `TriangularwaveGenerator` generates output of the form
```math 
    x(t) = \\begin{cases}
    \\dfrac{A t}{\\alpha T} + B & kT + \\tau \\leq t \\leq (k + \\alpha) T + \\tau \\
    \\dfrac{A (T - t)}{T (1 - \\alpha)} + B & (k + \\alpha) T + \\tau \\leq t \\leq (k + 1) T + \\tau
    \\end{cases} \\quad k \\in Z
```
where ``A`` is `amplitude`, ``T`` is `period`, ``\\tau`` is `delay` ``\\alpha`` is `duty`. 
"""
@def_source struct TriangularwaveGenerator{OP, RO} <: AbstractSource
    amplitude::Float64 =  1. 
    period::Float64 = 1. 
    duty::Float64 = 0.5 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
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
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`ConstantGenerator` generates output of the form
```math 
    x(t) = A
```
where ``A`` is `amplitude.
"""
@def_source struct ConstantGenerator{OP, RO} <: AbstractSource
    amplitude::Float64 = 1. 
    output::OP = Outport()
    readout::RO = (t, amplitude=amplitude) -> amplitude
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`RampGenerator` generates output of the form
```math 
    x(t) = \\alpha (t - \\tau)
```
where ``\\alpha`` is the `scale` and ``\\tau`` is `delay`.
"""
@def_source struct RampGenerator{OP, RO} <: AbstractSource
    scale::Float64 = 1.
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, scale=scale, delay=delay, offset=offset) ->  scale * (t - delay) + offset
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`StepGenerator` generates output of the form 
```math
    x(t) = \\left\\{\\begin{array}{lr}
	B, &  t \\leq \\tau  \\
	A + B,  &  t > \\tau
	\\end{array} \\right.
```
where ``A`` is `amplitude`, ``B`` is the `offset` and ``\\tau`` is the `delay`.
"""
@def_source struct StepGenerator{OP, RO} <: AbstractSource
    amplitude::Float64 = 1. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, amplitude=amplitude, delay=delay, offset=offset) -> 
        t - delay >= 0 ? amplitude + offset : offset
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`ExponentialGenerator` generates output of the form
```math 
    x(t) = A e^{\\alpha (t - \\tau)}
```
where ``A`` is `scale`, ``\\alpha`` is `decay` and ``\\tau`` is `delay`.
"""
@def_source struct ExponentialGenerator{OP, RO} <: AbstractSource
    scale::Float64 = 1. 
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, scale=scale, decay=decay, delay=delay, offset=offset) -> scale * exp(decay * (t - delay)) + offset
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`DampedExponentialGenerator` generates outputs of the form 
```math 
    x(t) = A (t - \\tau) e^{\\alpha (t - \\tau)}
```
where ``A`` is `scale`, ``\\alpha`` is `decay`, ``\\tau`` is `delay`.
"""
@def_source struct DampedExponentialGenerator{OP, RO} <: AbstractSource
    scale::Float64 = 1.
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, scale=scale, decay=decay, delay=delay, offset=offset) -> 
        scale * (t - delay) * exp(decay * (t - delay)) + offset
end

"""
    $(TYPEDEF)

Pulse Code Modulator (PCM) that generates random pulses.

# Fields 

    $(TYPEDFIELDS)

"""
@def_source struct PCM{OP, RO} <: AbstractSource 
    t0::Float64 = 0.
    bits::Vector{Bool} = rand(Bool, 10)
    high::Float64 = 1. 
    low::Float64 = 0. 
    period::Float64 = 1.
    duty::Float64 = 0.5
    output::OP = Outport()
    readout::RO = function pcm(t, t0=t0, bits=bits, high=high, low=low, period=period, duty=duty)
        ti = (t - t0) 
        n = length(bits)
        tf = n * period 
        idx = ti == tf ? n : findlast(ti .≥  (0 : n) * period)
        induty = ti % period ≤ period * duty
        bits[idx] ? (induty ? low : high) : (induty ? high : low)
    end
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
show(io::IO, gen::PCM) = print(io, 
    "PCM(high:$(gen.high), low:$(gen.low), period:$(gen.period), duty:$(gen.duty))")
