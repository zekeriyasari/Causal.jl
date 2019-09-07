# This file contains the function generator tools to drive other tools of DsSimulator.


import ..Components.Base: @generic_source_fields

struct FunctionGenerator{OF} <: AbstractSource
    @generic_source_fields
end
FunctionGenerator(outputfunc) = FunctionGenerator(outputfunc, Callback[], uuid4())


struct SinewaveGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    frequency::Float64
    phase::Float64
    delay::Float64
    offset::Float64
    function SinewaveGenerator(amplitude, frequency, phase, delay, offset)
        outputfunc(t) = amplitude * sin(2 * pi * frequency * (t - delay)) + offset
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), amplitude, frequency, phase, delay, offset)
    end
end
SinewaveGenerator(;amplitude=1, frequency=1, phase=0, delay=0, offset=0) = SinewaveGenerator(amplitude, frequency, phase, delay, offset)


struct DampedSinewaveGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    decay::Float64
    frequency::Float64
    phase::Float64
    delay::Float64
    offset::Float64
    function DampedSinewaveGenerator(amplitude, decay, frequency, phase, delay, offset)
        outputfunc(t) = amplitude * exp(decay) * sin(2 * pi * frequency * (t - delay)) + offset
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), amplitude, decay,frequency, phase, delay, offset)
    end
end
DampedSineaveGenerator(;amplitude=1, decay=-0.5, frequency=1, phase=0, delay=0, offset=0) = 
    DampedSinewaveGenerator(amplitude, decay, frequency, phase, delay, offset)


struct SquarewaveGenerator{OF} <: AbstractSource
    @generic_source_fields
    high::Float64
    low::Float64
    period::Float64
    duty::Float64
    delay::Float64
    function SquarewaveGenerator(high, low, period, duty, delay)
        function outputfunc(t)
            if t <= delay
                return low
            else
                ((t - delay) % period <= duty * period) ? high : low
            end
        end
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), high, low, period, duty, delay)
    end
end
SquarewaveGenerator(;high=1, low=0, period=1, duty=0.5, delay=0,) = SquarewaveGenerator(high, low, period, duty, delay)


struct TriangularwaveGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    period::Float64
    duty::Float64
    delay::Float64
    offset::Float64
    function TriangularwaveGenerator(amplitude, period, duty, delay, offset)
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
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), amplitude, period, duty, delay, offset)
    end
end
TriangularwaveGenerator(;amplitude=1, period=1, duty=0.5, delay=0, offset=0) = TriangularwaveGenerator(amplitude, period, duty, delay, offset)


struct ConstantGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    function ConstantGenerator(amplitude)
        outputfunc(t) = amplitude
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), amplitude)
    end
end
ConstantGenerator(;amplitude=1) = ConstantGenerator(amplitude)


struct RampGenerator{OF} <: AbstractSource
    @generic_source_fields
    scale::Float64
    function RampGenerator(scale)
        outputfunc(t) = scale * t
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), scale)
    end
end
RampGenerator(;scale=1) = RampGenerator(scale)


struct StepGenerator{OF} <: AbstractSource
    @generic_source_fields
    amplitude::Float64
    delay::Float64
    offset::Float64
    function StepGenerator(amplitude, delay, offset)
        outputfunc(t) =  t - delay >= 0 ? one(t) + offset : zero(t) + offset
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), amplitude, delay, offset)
    end
end
StepGenerator(;amplitude=1, delay=0, offset=0) = StepGenerator(amplitude, delay, offset)


struct ExponentialGenerator{OF} <: AbstractSource
    @generic_source_fields
    scale::Float64
    decay::Float64
    function ExponentialGenerator(scale, decay)
        outputfunc(t) = scale * exp(decay * t)
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), scale, decay)
    end
end
ExponentialGenerator(;scale=1, decay=-1) = ExponentialGenerator(scale, decay)


struct DampedExponentialGenerator{OF} <: AbstractSource
    @generic_source_fields
    scale::Float64
    decay::Float64
    function DampedExponentialGenerator(scale, decay)
        outputfunc(t) = scale * t * exp(decay * t)
        new{typeof(outputfunc)}(outputfunc, Bus(), Link(), Callback[], uuid4(), scale, decay)
    end
end
DampedExponentialGenerator(;scale=1, decay=-1) =  DampedExponentialGenerator(scale, decay)
