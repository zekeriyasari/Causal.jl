# This file includes the sources of JuSDL

@reexport module Sources

using UUIDs
import ..Components.Base: AbstractSource
import ....JuSDL.Utilities: Callback
import ....JuSDL.Connections: Link, Bus
# export isset, pause!, set!

include("clock.jl")
include("generators.jl")

end  # module