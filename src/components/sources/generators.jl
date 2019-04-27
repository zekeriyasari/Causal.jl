# This file contains the function generator tools to drive other tools of DsSimulator.


import ..Components.Base: @generic_source_fields

struct FunctionGenerator{OF} <: AbstractSource
    @generic_source_fields
    FunctionGenerator(outputfunc, callbacks, name) = 
        new{typeof(outputfunc)}(outputfunc, Bus(length(outputfunc(0))), Link(), callbacks, name)
end
FunctionGenerator(outputfunc; callbacks=Callback[], name=string(uuid4())) = 
    FunctionGenerator(outputfunc, callbacks, name)

struct SinewaveGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    frequency::Float64
    phase::Float64
    delay::Float64
    offset::Float64
    function SinewaveGenerator(amplitude, frequency, phase, delay, offset, callbacks, name)
        outputfunc(t) = amplitude * sin(2 * pi * frequency * (t - delay)) + offset
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, amplitude, frequency, phase, delay, offset)
    end
end
SinewaveGenerator(;amplitude=1, frequency=1, phase=0, delay=0, offset=0, callbacks=Callback[], name=string(uuid4())) = 
    SinewaveGenerator(amplitude, frequency, phase, delay, offset, callbacks, name)

struct DampedSinewaveGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    decay::Float64
    frequency::Float64
    phase::Float64
    delay::Float64
    offset::Float64
    function DampedSinewaveGenerator(amplitude, decay, frequency, phase, delay, offset, callbacks, name)
        outputfunc(t) = amplitude * exp(decay) * sin(2 * pi * frequency * (t - delay)) + offset
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, amplitude, decay,frequency, phase, delay, 
        offset)
    end
end
DampedSineaveGenerator(;amplitude=1, decay=-0.5, frequency=1, phase=0, delay=0, offset=0, callbacks=Callback[], 
    name=string(uuid4())) = DampedSinewaveGenerator(amplitude, decay, frequency, phase, delay, offset, callbacks, name)

struct SquarewaveGenerator{OF} <: AbstractSource
    @generic_source_fields
    high::Float64
    low::Float64
    period::Float64
    duty::Float64
    delay::Float64
    function SquarewaveGenerator(high, low, period, duty, delay, callbacks, name)
        function outputfunc(t)
            if t <= delay
                return low
            else
                ((t - delay) % period <= duty * period) ? high : low
            end
        end
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, high, low, period, duty, delay)
    end
end
SquarewaveGenerator(;high=1, low=0, period=1, duty=0.5, delay=0, callbacks=Callback[], name=string(uuid4())) = 
    SquarewaveGenerator(high, low, period, duty, delay, callbacks, name)

struct TriangularwaveGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    period::Float64
    duty::Float64
    delay::Float64
    offset::Float64
    function TriangularwaveGenerator(amplitude, period, duty, delay, offset, callbacks, name)
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
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, amplitude, period, duty, delay, offset)
    end
end
TriangularwaveGenerator(;amplitude=1, period=1, duty=0.5, delay=0, offset=0, callbacks=Callback[], 
    name=string(uuid4())) = TriangularwaveGenerator(amplitude, period, duty, delay, offset, callbacks, name)

struct ConstantGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    function ConstantGenerator(amplitude, callbacks, name)
        outputfunc(t) = amplitude
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, amplitude)
    end
end
ConstantGenerator(;amplitude=1, callbacks=Callback[], name=string(uuid4())) = 
    ConstantGenerator(amplitude, callbacks, name)

struct RampGenerator{OF} <: AbstractSource
    @generic_source_fields
    scale::Float64
    function RampGenerator(scale, callbacks, name)
        outputfunc(t) = scale * t
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, scale)
    end
end
RampGenerator(;scale=1, callbacks=Callback[], name=string(uuid4())) = RampGenerator(scale, callbacks, name)

struct StepGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    delay::Float64
    offset::Float64
    function StepGenerator(amplitude, delay, offset, callbacks, name)
        outputfunc(t) =  t - delay >= 0 ? one(t) + offset : zero(t) + offset
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, amplitude, delay, offset)
    end
end
StepGenerator(;amplitude=1, delay=0, offset=0, callbacks=Callback[], name=string(uuid4())) = 
    StepGenerator(amplitude, delay, offset, callbacks, name)

struct ExponentialGenerator{OF} <: AbstractSource
    @generic_source_fields
    scale::Float64
    decay::Float64
    function ExponentialGenerator(scale, decay, callbacks, name)
        outputfunc(t) = scale * exp(decay * t)
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, scale, decay)
    end
end
ExponentialGenerator(;scale=1, decay=-1, callbacks=Callback[], name=string(uuid4())) = 
    ExponentialGenerator(scale, decay, callbacks, name)

struct DampedExponentialGenerator{OF} <: AbstractSource
    @generic_source_fields
    scale::Float64
    decay::Float64
    function DampedExponentialGenerator(scale, decay, callbacks, name)
        outputfunc(t) = scale * t * exp(decay * t)
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), callbacks, name, scale, decay)
    end
end
DampedExponentialGenerator(;scale=1, decay=-1, callbacks=Callback[], name=string(uuid4())) = 
    DampedExponentialGenerator(scale, decay, callbacks, name)
