# This file contains the function generator tools to drive other tools of DsSimulator.

macro defgen(ex) 
    nex = ex.head == :macrocall ? ex.args[end] : ex 
    defgen(nex) |> esc
end

function defgen(ex) 
    head = ex.head
    ismutable, name, args = ex.args
    if ismutable
        if name isa Symbol 
            return quote 
                Base.@kwdef mutable struct $name{TR, HS, CB} <: AbstractSource
                    $args
                    @genericfields
                end 
            end
        else 
            return quote 
                Base.@kwdef mutable struct $(name.args[1]){$(name.args[2:end]...), TR, HS, CB} <: AbstractSource
                    $args
                    @genericfields
                end 
            end
        end
    else 
        if name isa Symbol
            return quote 
                Base.@kwdef struct $name{TR, HS, CB} <: AbstractSource
                    $args
                    @genericfields
                end 
            end
        else
            return quote 
                Base.@kwdef struct $(name.args[1]){$(name.args[2:end]...), TR, HS, CB} <: AbstractSource
                    $args
                    @genericfields
                end 
            end
        end
    end 
end


##### Common generator types.

 @doc raw"""
    SinewaveGenerator(;amplitude=1., frequency=1., phase=0., delay=0., offset=0.)

Constructs a `SinewaveGenerator` with output of the form
```math 
    x(t) = A sin(2 \pi f  (t - \tau) + \phi) + B
```
where ``A`` is `amplitude`, ``f`` is `frequency`, ``\tau`` is `delay` and ``\phi`` is `phase` and ``B`` is `offset`.
"""
@defgen Base.@kwdef struct SinewaveGenerator{OP}
    amplitude::Float64 = 1.
    frequency::Float64 = 1. 
    phase::Float64 = 0. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end

@doc raw"""
    DampedSinewaveGenerator(;amplitude=1., decay=-0.5, frequency=1., phase=0., delay=0., offset=0.)

Constructs a `DampedSinewaveGenerator` which generates outputs of the form 
```math 
    x(t) = A e^{\alpha t} sin(2 \pi f (t - \tau) + \phi) + B
```
where ``A`` is `amplitude`, ``\alpha`` is `decay`, ``f`` is `frequency`, ``\phi`` is `phase`, ``\tau`` is `delay` and ``B`` is `offset`.
"""
@defgen Base.@kwdef struct DampedSinewaveGenerator{OP}
    amplitude::Float64 = 1. 
    decay::Float64 = 0.5 
    frequency::Float64 = 1. 
    phase::Float64 = 0. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end


@doc raw"""
    SquarewaveGenerator(;level1=1., level2=0., period=1., duty=0.5, delay=0.)

Constructs a `SquarewaveGenerator` with output of the form 
```math 
    x(t) = \left\{\begin{array}{lr}
	A_1 + B, &  kT + \tau \leq t \leq (k + \alpha) T + \tau \\
	A_2 + B,  &  (k + \alpha) T + \tau \leq t \leq (k + 1) T + \tau	
	\end{array} \right. \quad k \in Z
```
where ``A_1``, ``A_2`` is `level1` and `level2`, ``T`` is `period`, ``\tau`` is `delay` ``\alpha`` is `duty`. 
"""
@defgen Base.@kwdef struct SquarewaveGenerator{OP}
    high::Float64 = 1. 
    low::Float64 = 0. 
    period::Float64 = 1. 
    duty::Float64 = 0.5
    delay::Float64 = 0. 
    output::OP = Outport()
end


@doc raw"""
    TriangularwaveGenerator(;amplitude=1, period=1, duty=0.5, delay=0, offset=0)

Constructs a `TriangularwaveGenerator` with output of the form
```math 
    x(t) = \left\{\begin{array}{lr}
	\dfrac{A t}{\alpha T} + B, &  kT + \tau \leq t \leq (k + \alpha) T + \tau \\[0.25cm]
	\dfrac{A (T - t)}{T (1 - \alpha)} + B,  &  (k + \alpha) T + \tau \leq t \leq (k + 1) T + \tau	
	\end{array} \right. \quad k \in Z
```
where ``A`` is `amplitude`, ``T`` is `period`, ``\tau`` is `delay` ``\alpha`` is `duty`. 
"""
@defgen Base.@kwdef struct TriangularwaveGenerator{OP}
    amplitude::Float64 =  1. 
    period::Float64 = 1. 
    duty::Float64 = 0.5 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end


@doc raw"""
    ConstantGenerator(;amplitude=1.)

Constructs a `ConstantGenerator` with output of the form
```math 
    x(t) = A
```
where ``A`` is `amplitude.
"""
@defgen Base.@kwdef struct ConstantGenerator{OP}
    amplitude::Float64 = 1. 
    output::OP = Outport()
end


@doc raw"""
    RampGenerator(;scale=1, delay=0.)

Constructs a `RampGenerator` with output of the form
```math 
    x(t) = \alpha (t - \tau)
```
where ``\alpha`` is the `scale` and ``\tau`` is `delay`.
"""
@defgen Base.@kwdef struct RampGenerator{OP}
    scale::Float64 = 1.
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end


@doc raw"""
    StepGenerator(;amplitude=1, delay=0, offset=0)

Constructs a `StepGenerator` with output of the form 
```math
    x(t) = \left\{\begin{array}{lr}
	B, &  t \leq \tau  \\
	A + B,  &  t > \tau
	\end{array} \right.
```
where ``A`` is `amplitude`, ``B`` is the `offset` and ``\tau`` is the `delay`.
"""
@defgen Base.@kwdef struct StepGenerator{OP}
    amplitude::Float64 = 1. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end


@doc raw"""
    ExponentialGenerator(;scale=1, decay=-1, delay=0.)

Constructs an `ExponentialGenerator` with output of the form
```math 
    x(t) = A e^{\alpha (t - \tau)}
```
where ``A`` is `scale`, ``\alpha`` is `decay` and ``\tau`` is `delay`.
"""
@defgen Base.@kwdef struct ExponentialGenerator{OP}
    scale::Float64 = 1. 
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end


@doc raw"""
    DampedExponentialGenerator(;scale=1, decay=-1, delay=0.)

Constructs an `DampedExponentialGenerator` with outpsuts of the form 
```math 
    x(t) = A (t - \tau) e^{\alpha (t - \tau)}
```
where ``A`` is `scale`, ``\alpha`` is `decay`, ``\tau`` is `delay`.
"""
@defgen Base.@kwdef struct DampedExponentialGenerator{OP}
    scale::Float64 = 1.
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end

##### Define readout of generators
function readout(gen::SinewaveGenerator, t)
    gen.amplitude * sin(2 * pi * gen.frequency * (t - gen.delay) + gen.phase) + gen.offset
end 

function readout(gen::DampedSinewaveGenerator, t)
    gen.amplitude * exp(gen.decay * t) * sin(2 * pi * gen.frequency * (t - gen.delay)) + gen.offset
end 

function readout(gen::SquarewaveGenerator, t)
    if t <= gen.delay
        return gen.low
    else
        ((t - gen.delay) % gen.period <= gen.duty * gen.period) ? gen.high : gen.low
    end
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

function readout(gen::ConstantGenerator, t)
    gen.amplitude
end 

function readout(gen::RampGenerator, t)
    gen.scale * (t - gen.delay) + gen.offset
end 

function readout(gen::StepGenerator,  t)
    t - gen.delay >= 0 ? one(t) + gen.offset : zero(t) + gen.offset
end 

function readout(gen::ExponentialGenerator, t)
    gen.scale * exp(gen.decay * (t - gen.delay)) + gen.offset
end

function readout(gen::DampedExponentialGenerator, t)
    gen.scale * (t - gen.delay) * exp(gen.decay * (t - gen.delay)) + gen.offset
end

##### Pretty-Printing of generators.
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
