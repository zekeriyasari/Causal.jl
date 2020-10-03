# This file contains the function generator tools to drive other tools of DsSimulator.

export @def_source, FunctionGenerator, SinewaveGenerator, DampedSinewaveGenerator, SquarewaveGenerator, 
    TriangularwaveGenerator, ConstantGenerator, RampGenerator, StepGenerator, ExponentialGenerator, 
    DampedExponentialGenerator

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
# """
#     $(TYPEDEF)

# # Fields 

#     $(TYPEDFIELDS)

# # Example 
# ```julia 
# julia> gen = FunctionGenerator(readout = t -> [t, 2t], output = Outport(2));

# julia> gen.readout(1.)
# 2-element Array{Float64,1}:
#  1.0
#  2.0
# ```
# """
# @def_source struct FunctionGenerator{RO, OP} <: AbstractSource 
#     readout::RO 
#     output::OP = Outport{typeof(readout(0.))}()  
# end

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
@def_source mutable struct SinewaveGenerator{OP} <: AbstractSource
    amplitude::Float64 = 1.
    frequency::Float64 = 1. 
    phase::Float64 = 0. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end
function readout(gen::SinewaveGenerator, t)
    gen.amplitude * sin(2 * pi * gen.frequency * (t - gen.delay) + gen.phase) + gen.offset
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
@def_source mutable struct DampedSinewaveGenerator{OP} <: AbstractSource
    amplitude::Float64 = 1. 
    decay::Float64 = 0.5 
    frequency::Float64 = 1. 
    phase::Float64 = 0. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end
function readout(gen::DampedSinewaveGenerator, t)
    gen.amplitude * exp(gen.decay * t) * sin(2 * pi * gen.frequency * (t - gen.delay)) + gen.offset
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
@def_source mutable struct SquarewaveGenerator{OP} <: AbstractSource
    high::Float64 = 1. 
    low::Float64 = 0. 
    period::Float64 = 1. 
    duty::Float64 = 0.5
    delay::Float64 = 0. 
    output::OP = Outport()
end
function readout(gen::SquarewaveGenerator, t)
    t <= gen.delay ? gen.low : ( ((t - gen.delay) % gen.period <= gen.duty * gen.period) ? gen.high : gen.low )
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
@def_source mutable struct TriangularwaveGenerator{OP} <: AbstractSource
    amplitude::Float64 =  1. 
    period::Float64 = 1. 
    duty::Float64 = 0.5 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end
function readout(gen::TriangularwaveGenerator, t)
    if t <= gen.delay
        return gen.offset
    else
        t = (t - gen.delay) % gen.period 
        if t <= gen.duty * gen.period
            gen.amplitude / (gen.duty * gen.period) * t + gen.offset
        else
            (gen.amplitude * (gen.period - t)) / (gen.period * (1 - gen.duty)) + gen.offset
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
@def_source mutable struct ConstantGenerator{OP} <: AbstractSource
    amplitude::Float64 = 1. 
    output::OP = Outport()
end
readout(gen::ConstantGenerator, t) =  gen.amplitude


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
@def_source mutable struct RampGenerator{OP} <: AbstractSource
    scale::Float64 = 1.
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::RampGenerator, t) =  gen.scale * (t - gen.delay) + gen.offset


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
@def_source mutable struct StepGenerator{OP} <: AbstractSource
    amplitude::Float64 = 1. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::StepGenerator, t) = t - gen.delay >= 0 ? gen.amplitude + gen.offset : gen.offset


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
@def_source mutable struct ExponentialGenerator{OP} <: AbstractSource
    scale::Float64 = 1. 
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::ExponentialGenerator, t) = gen.scale * exp(gen.decay * (t - gen.delay)) + gen.offset


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
@def_source mutable struct DampedExponentialGenerator{OP} <: AbstractSource
    scale::Float64 = 1.
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::DampedExponentialGenerator, t) =  gen.scale*(t - gen.delay) * exp(gen.decay*(t - gen.delay)) + gen.offset

##### Pretty-Printing of generators.

# show(io::IO, gen::FunctionGenerator) = print(io, 
#     "FunctionGenerator(readout:$(gen.readout),  output:$(gen.output))")
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
