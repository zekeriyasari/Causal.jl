# This file contains the function generator tools to drive other tools of DsSimulator.

import UUIDs: uuid4

"""
    @def_source

Used to define new type of source. Usage is as follows:
```
@def_source struct MySource{T1, T2, T3, OP, RO} <: AbstractSource
    param1::T1 = param1_default
    param2::T2 = param2_default
    param3::T3 = param3_default
        ⋮
    output::OP = output_default
    readout::RO = readout_function
end
```
"""
macro def_source(ex) 
    fields = quote
        trigger::TR = Inpin()
        handshake::HS = Outpin{Bool}()
        callbacks::CB = nothing
        name::Symbol = Symbol()
        id::ID = Jusdl.uuid4()
    end, [:TR, :HS, :CB, :ID]
    _append_common_fields!(ex, fields...)
    deftype(ex)
end


##### Define Sources library

 @doc raw"""
    SinewaveGenerator(;amplitude=1., frequency=1., phase=0., delay=0., offset=0.)

Constructs a `SinewaveGenerator` with output of the form
```math 
    x(t) = A sin(2 \pi f  (t - \tau) + \phi) + B
```
where ``A`` is `amplitude`, ``f`` is `frequency`, ``\tau`` is `delay` and ``\phi`` is `phase` and ``B`` is `offset`.
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


@doc raw"""
    DampedSinewaveGenerator(;amplitude=1., decay=-0.5, frequency=1., phase=0., delay=0., offset=0.)

Constructs a `DampedSinewaveGenerator` which generates outputs of the form 
```math 
    x(t) = A e^{\alpha t} sin(2 \pi f (t - \tau) + \phi) + B
```
where ``A`` is `amplitude`, ``\alpha`` is `decay`, ``f`` is `frequency`, ``\phi`` is `phase`, ``\tau`` is `delay` and ``B`` is `offset`.
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


@doc raw"""
    ConstantGenerator(;amplitude=1.)

Constructs a `ConstantGenerator` with output of the form
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


@doc raw"""
    RampGenerator(;scale=1, delay=0.)

Constructs a `RampGenerator` with output of the form
```math 
    x(t) = \alpha (t - \tau)
```
where ``\alpha`` is the `scale` and ``\tau`` is `delay`.
"""
@def_source struct RampGenerator{OP, RO} <: AbstractSource
    scale::Float64 = 1.
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, scale=scale, delay=delay, offset=offset) ->  scale * (t - delay) + offset
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
@def_source struct StepGenerator{OP, RO} <: AbstractSource
    amplitude::Float64 = 1. 
    delay::Float64 = 0. 
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, amplitude=amplitude, delay=delay, offset=offset) -> 
        t - delay >= 0 ? one(t) + offset : zero(t) + offset
end


@doc raw"""
    ExponentialGenerator(;scale=1, decay=-1, delay=0.)

Constructs an `ExponentialGenerator` with output of the form
```math 
    x(t) = A e^{\alpha (t - \tau)}
```
where ``A`` is `scale`, ``\alpha`` is `decay` and ``\tau`` is `delay`.
"""
@def_source struct ExponentialGenerator{OP, RO} <: AbstractSource
    scale::Float64 = 1. 
    decay::Float64 = -1. 
    delay::Float64 = 0.
    offset::Float64 = 0.
    output::OP = Outport()
    readout::RO = (t, scale=scale, decay=decay, delay=delay, offset=offset) -> scale * exp(decay * (t - delay)) + offset
end


@doc raw"""
    DampedExponentialGenerator(;scale=1, decay=-1, delay=0.)

Constructs an `DampedExponentialGenerator` with outpsuts of the form 
```math 
    x(t) = A (t - \tau) e^{\alpha (t - \tau)}
```
where ``A`` is `scale`, ``\alpha`` is `decay`, ``\tau`` is `delay`.
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
