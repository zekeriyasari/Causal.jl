# This file includes the sources of JuSDL

@reexport module Sources

using UUIDs
import ..Components.Base: AbstractSource
import ....JuSDL.Utilities: Callback
import ....JuSDL.Connections: Link, Bus

export Clock, isset, pause!, set!
export FunctionGenerator, SinewaveGenerator, DampedSinewaveGenerator, SquarewaveGenerator, TrianuglarwaveGenerator, 
    ConstantGenerator, RampGenerator, StepGenerator, ExponentialGenerator, DampedExponentialGenerator

include("clock.jl")
include("generators.jl")

end  # module