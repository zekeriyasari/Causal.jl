# This file contains the function generator tools to drive other tools of DsSimulator.


import ..Components.Base: @generic_source_fields


##### Generic Function Generator
mutable struct FunctionGenerator{OF, L, OB} <: AbstractSource
    @generic_source_fields
    function FunctionGenerator(outputfunc)
        output =  Bus{typeof(outputfunc(0.))}()
        trigger = Link()
        new{typeof(outputfunc), typeof(trigger), typeof(output)}(outputfunc, output, trigger, Callback[], uuid4())
    end
end

##### Common generator types.
mutable struct SinewaveGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    frequency::Float64
    phase::Float64
    delay::Float64
    offset::Float64
    function SinewaveGenerator(amplitude=1., frequency=1., phase=0., delay=0., offset=0.)
        outputfunc(t) =  amplitude * sin(2 * pi * frequency * (t - delay)) + offset
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, trigger, Callback[], uuid4(), 
            amplitude, frequency, phase, delay, offset)
    end
end


mutable struct DampedSinewaveGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    decay::Float64
    frequency::Float64
    phase::Float64
    delay::Float64
    offset::Float64
    function DampedSinewaveGenerator(amplitude=1., decay=-0.5, frequency=1., phase=0., delay=0., offset=0.)
        outputfunc(t) = amplitude * exp(decay) * sin(2 * pi * frequency * (t - delay)) + offset
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, trigger, Callback[], uuid4(), 
            amplitude, decay,frequency, phase, delay, offset)
    end
end



mutable struct SquarewaveGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    high::Float64
    low::Float64
    period::Float64
    duty::Float64
    delay::Float64
    function SquarewaveGenerator(high=1., low=0., period=1., duty=0.5, delay=0.)
        function outputfunc(t)
            if t <= delay
                return low
            else
                ((t - delay) % period <= duty * period) ? high : low
            end
        end
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, trigger, Callback[], uuid4(), high,
            low, period, duty, delay)
    end
end


mutable struct TriangularwaveGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    period::Float64
    duty::Float64
    delay::Float64
    offset::Float64
    function TriangularwaveGenerator(amplitude=1, period=1, duty=0.5, delay=0, offset=0)
        function outputfunc(t)
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
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, trigger, Callback[], uuid4(), 
            amplitude, period, duty, delay, offset)
    end
end


mutable struct ConstantGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    function ConstantGenerator(amplitude=1.)
        outputfunc(t) = amplitude
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, trigger, Callback[], uuid4(), 
            amplitude)
    end
end


mutable struct RampGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    scale::Float64
    function RampGenerator(scale=1)
        outputfunc(t) = scale * t
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, trigger, Callback[], uuid4(), 
            scale)
    end
end


mutable struct StepGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    delay::Float64
    offset::Float64
    function StepGenerator(amplitude=1, delay=0, offset=0)
        outputfunc(t) = t - delay >= 0 ? one(t) + offset : zero(t) + offset
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, Link(), Callback[], uuid4(), 
            amplitude, delay, offset)
    end
end


mutable struct ExponentialGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    scale::Float64
    decay::Float64
    function ExponentialGenerator(scale=1, decay=-1)
        outputfunc(t) = scale * exp(decay * t)
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, trigger, Callback[], uuid4(), 
            scale, decay)
    end
end


mutable struct DampedExponentialGenerator{OF, OB, L} <: AbstractSource
    @generic_source_fields
    scale::Float64
    decay::Float64
    function DampedExponentialGenerator(;scale=1, decay=-1)
        outputfunc(t) = scale * t * exp(decay * t)
        output = Bus()
        trigger = Link()
        new{typeof(outputfunc), typeof(output), typeof(trigger)}(outputfunc, output, trigger, Callback[], uuid4(), 
            scale, decay)
    end
end


##### Pretty-Printing of generators.
show(io::IO, gen::FunctionGenerator) = print(io, 
    "FunctionGenerator(outputfunc:$(gen.outputfunc), nout:$(length(gen.output)))")
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
    "ConstantGenerator(amp:$(gen.amplitude)")
show(io::IO, gen::RampGenerator) = print(io, "RampGenerator(scale:$(gen.scale))")
show(io::IO, gen::StepGenerator) = print(io, 
    "StepGenerator(amp:$(gen.amplitude), delay:$(gen.delay), offset:$(gen.offset))")
show(io::IO, gen::ExponentialGenerator) = print(io, 
    "ExponentialGenerator(scale:$(gen.scale), decay:$(gen.decay))")
show(io::IO, gen::DampedExponentialGenerator) = print(io, 
    "DampedExponentialGenerator(scale:$(gen.scale), decay:$(gen.decay))")
