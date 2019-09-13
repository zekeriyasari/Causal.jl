# This file contains the function generator tools to drive other tools of DsSimulator.


import ..Components.Base: @generic_source_fields

struct FunctionGenerator{OF, OB} <: AbstractSource
    @generic_source_fields
end
FunctionGenerator(outputfunc) = FunctionGenerator(outputfunc, Bus{typeof(outputfunc(0.))}(), Link(), Callback[], uuid4())


struct SinewaveGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    amplitude::S
    frequency::S
    phase::S
    delay::S
    offset::S
end
function SinewaveGenerator(;amplitude=1., frequency=1., phase=0., delay=0., offset=0., nout::Int=0)
    if nout == 0
        outputfunc = t -> amplitude * sin(2 * pi * frequency * (t - delay)) + offset
    else
        outputfunc = t -> fill(amplitude * sin(2 * pi * frequency * (t - delay)) + offset, nout)
    end
    output = Bus{typeof(outputfunc(0.))}()
    SinewaveGenerator(outputfunc, output, Link(), Callback[], uuid4(), promote(amplitude, frequency, phase, delay, offset)...)
end


struct DampedSinewaveGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    amplitude::S
    decay::S
    frequency::S
    phase::S
    delay::S
    offset::S
end
function DampedSinewaveGenerator(;amplitude=1., decay=-0.5, frequency=1., phase=0., delay=0., offset=0., mout::Int=1)
    outputfunc(t) = fill(amplitude * exp(decay) * sin(2 * pi * frequency * (t - delay)) + offset, nout)
    output = Bus{typeof(outputfunc(0.))}(nout)
    DampedSineaveGenerator(outputfunc, Bus(), Link(), Callback[], uuid4(), promote(amplitude, decay,frequency, phase, delay, offset)...)
end


struct SquarewaveGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    high::S
    low::S
    period::S
    duty::S
    delay::S
end
function SquarewaveGenerator(;high=1., low=0., period=1., duty=0.5, delay=0., nout::Int=1)
    function _outputfunc(t)
        if t <= delay
            return low
        else
            ((t - delay) % period <= duty * period) ? high : low
        end
    end
    outputfunc(t) = fill(_outputfunc(t), nout)
    output = Bus{typeof(outputfunc(0.))}(nout)
    SinewaveGenerator(outputfunc, output, Link(), Callback[], uuid4(), promote(high, low, period, duty, delay)...)
end


struct TriangularwaveGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    amplitude::S
    period::S
    duty::S
    delay::S
    offset::S
end
function TriangularwaveGenerator(;amplitude=1, period=1, duty=0.5, delay=0, offset=0, nout::Int=1)
    function _outputfunc(t)
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
    outputfunc(t) = fill(_outputfunc(t), nout)
    output = Bus{typeof(outputfunc(0.))}(nout)
    TriangularwaveGenerator(outputfunc, output, Link(), Callback[], uuid4(), promote(amplitude, period, duty, delay, offset)...)
end


struct ConstantGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    amplitude::S
end
function ConstantGenerator(;amplitude=1., nout::Int=1)
    outputfunc(t) = fill(amplitude, nout)
    output = Bus{typeof(outputfunc(0.))}(nout)
    ConstantGenerator(outputfunc, output, Link(), Callback[], uuid4(), amplitude)
end


struct RampGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    scale::S
end
function RampGenerator(;scale=1, nout::Int=1)
    outputfunc(t) = fill(scale * t, nout)
    output = Bus{typeof(outputfunc(0.))}(nout)
    RampGenerator(outputfunc, output, Link(), Callback[], uuid4(), scale)
end


struct StepGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    amplitude::S
    delay::S
    offset::S
end
function StepGenerator(;amplitude=1, delay=0, offset=0, nout::Int=1)
    _outputfunc(t) =  t - delay >= 0 ? one(t) + offset : zero(t) + offset
    outputfunc(t) = fill(_outputfunc(t), nout)
    output = Bus{typeof(outputfunc(0.))}(nout)
    StepGenerator(outputfunc, output, Link(), Callback[], uuid4(), promote(amplitude, delay, offset)...)
end


struct ExponentialGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    scale::S
    decay::S
end
function ExponentialGenerator(;scale=1, decay=-1, nout::Int=1)
    outputfunc(t) = fill(scale * exp(decay * t), nout)
    output = Bus{typeof(outputfunc(0.))}(nout)
    ExponentialGenerator(outputfunc, output, Link(), Callback[], uuid4(), promote(scale, decay)...)
end


struct DampedExponentialGenerator{OF, OB, S} <: AbstractSource
    @generic_source_fields
    scale::S
    decay::S
end
function DampedExponentialGenerator(;scale=1, decay=-1, nout::Int=1)
    outputfunc(t) = fill(scale * t * exp(decay * t), nout)
    output = Bus{typeof(outputfunc(0.))}(nout)
    DampedExponentialGenerator(outputfunc, output, Link(), Callback[], uuid4(), scale, decay)
end
