# This file includes the Connections module

@reexport module Connections 

using UUIDs
import ..JuSDL.Utilities: Callback, Buffer, write!

# Data transfer types
abstract type AbstractLink end
abstract type AbstractBus end

export Link, isfull, isconnected, snapshot, connect, disconnect, launch
export Bus

include("link.jl")
include("bus.jl")

end