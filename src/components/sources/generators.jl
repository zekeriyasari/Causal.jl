# This file contains the function generator tools to drive other tools of DsSimulator.

#= 
Define common generator. To define new generator the following is sufficient 
```
    @def_source struct MyNewGen <: AbstractSource 
        param1::T1 = val1
        param1::T2 = val2 
        ⋮
        output::OP = val3
    end
    readout(gen::MyNewGen, t) = …
```
=#

 @doc raw"""
    SinewaveGenerator(;amplitude=1., frequency=1., phase=0., delay=0., offset=0.)

Constructs a `SinewaveGenerator` with output of the form
```math 
    x(t) = A sin(2 \pi f  (t - \tau) + \phi) + B
```
where ``A`` is `amplitude`, ``f`` is `frequency`, ``\tau`` is `delay` and ``\phi`` is `phase` and ``B`` is `offset`.
"""
@def_source struct SinewaveGenerator{OP} <: AbstractSource
    amplitude::Float64 = 1.
    frequency::Float64 = 1. 
    phase::Float64 = 0. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::SinewaveGenerator, t) = 
    gen.amplitude * sin(2 * pi * gen.frequency * (t - gen.delay) + gen.phase) + gen.offset 

@doc raw"""
    DampedSinewaveGenerator(;amplitude=1., decay=-0.5, frequency=1., phase=0., delay=0., offset=0.)

Constructs a `DampedSinewaveGenerator` which generates outputs of the form 
```math 
    x(t) = A e^{\alpha t} sin(2 \pi f (t - \tau) + \phi) + B
```
where ``A`` is `amplitude`, ``\alpha`` is `decay`, ``f`` is `frequency`, ``\phi`` is `phase`, ``\tau`` is `delay` and ``B`` is `offset`.
"""
@def_source struct DampedSinewaveGenerator{OP} <: AbstractSource
    amplitude::Float64 = 1. 
    decay::Float64 = 0.5 
    frequency::Float64 = 1. 
    phase::Float64 = 0. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::DampedSinewaveGenerator, t) = 
    gen.amplitude * exp(gen.decay * t) * sin(2 * pi * gen.frequency * (t - gen.delay)) + gen.offset

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
@def_source struct SquarewaveGenerator{OP} <: AbstractSource
    high::Float64 = 1. 
    low::Float64 = 0. 
    period::Float64 = 1. 
    duty::Float64 = 0.5
    delay::Float64 = 0. 
    output::OP = Outport()
end

function readout(gen::SquarewaveGenerator, t)
    if t <= gen.delay
        return gen.low
    else
        ((t - gen.delay) % gen.period <= gen.duty * gen.period) ? gen.high : gen.low
    end
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
@def_source struct TriangularwaveGenerator{OP} <: AbstractSource
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


@doc raw"""
    ConstantGenerator(;amplitude=1.)

Constructs a `ConstantGenerator` with output of the form
```math 
    x(t) = A
```
where ``A`` is `amplitude.
"""
@def_source struct ConstantGenerator{OP} <: AbstractSource
    amplitude::Float64 = 1. 
    output::OP = Outport()
end
readout(gen::ConstantGenerator, t) = gen.amplitude

@doc raw"""
    RampGenerator(;scale=1, delay=0.)

Constructs a `RampGenerator` with output of the form
```math 
    x(t) = \alpha (t - \tau)
```
where ``\alpha`` is the `scale` and ``\tau`` is `delay`.
"""
@def_source struct RampGenerator{OP} <: AbstractSource
    scale::Float64 = 1.
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::RampGenerator, t) = gen.scale * (t - gen.delay) + gen.offset


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
@def_source struct StepGenerator{OP} <: AbstractSource
    amplitude::Float64 = 1. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::StepGenerator, t) = t - gen.delay >= 0 ? one(t) + gen.offset : zero(t) + gen.offset


@doc raw"""
    ExponentialGenerator(;scale=1, decay=-1, delay=0.)

Constructs an `ExponentialGenerator` with output of the form
```math 
    x(t) = A e^{\alpha (t - \tau)}
```
where ``A`` is `scale`, ``\alpha`` is `decay` and ``\tau`` is `delay`.
"""
@def_source struct ExponentialGenerator{OP} <: AbstractSource
    scale::Float64 = 1. 
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::ExponentialGenerator, t) = gen.scale * exp(gen.decay * (t - gen.delay)) + gen.offset


@doc raw"""
    DampedExponentialGenerator(;scale=1, decay=-1, delay=0.)

Constructs an `DampedExponentialGenerator` with outpsuts of the form 
```math 
    x(t) = A (t - \tau) e^{\alpha (t - \tau)}
```
where ``A`` is `scale`, ``\alpha`` is `decay`, ``\tau`` is `delay`.
"""
@def_source struct DampedExponentialGenerator{OP} <: AbstractSource
    scale::Float64 = 1.
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
end
readout(gen::DampedExponentialGenerator, t) = 
    gen.scale * (t - gen.delay) * exp(gen.decay * (t - gen.delay)) + gen.offset


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
