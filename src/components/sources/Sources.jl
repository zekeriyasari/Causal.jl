# This file includes the sources of JuSDL

@reexport module Sources

using UUIDs
import ..Components.Base: AbstractSource
import ....JuSDL.Utilities: Callback
import ....JuSDL.Connections: Link, Bus

export Clock, isrunning, ispaused, isoutoftime, set!, unset!
export FunctionGenerator, SinewaveGenerator, DampedSinewaveGenerator, SquarewaveGenerator, TriangularwaveGenerator, 
    ConstantGenerator, RampGenerator, StepGenerator, ExponentialGenerator, DampedExponentialGenerator

include("clock.jl")
include("generators.jl")

end  # module