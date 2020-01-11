# This file includes the sources of Jusdl

@reexport module Sources

using UUIDs
import ..Components.ComponentsBase: AbstractSource
import ....Jusdl.Utilities: Callback
import ....Jusdl.Connections: Link, Bus
import Base.show

export Clock, isrunning, ispaused, isoutoftime, set!, stop!, pause!
export FunctionGenerator, SinewaveGenerator, DampedSinewaveGenerator, SquarewaveGenerator, TriangularwaveGenerator, 
    ConstantGenerator, RampGenerator, StepGenerator, ExponentialGenerator, DampedExponentialGenerator

include("clock.jl")
include("generators.jl")

end  # module