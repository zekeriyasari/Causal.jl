# This file includes the Connections module

@reexport module Connections 

using UUIDs
import ..JuSDL.Utilities: Callback, Buffer, write!

# Data transfer types
abstract type AbstractLink end
abstract type AbstractBus end

export Link, isconnected, connect, disconnect, launch
export Bus

include("link.jl")
include("bus.jl")

end