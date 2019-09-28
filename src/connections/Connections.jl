# This file includes the Connections module

@reexport module Connections 

using UUIDs
import ..Jusdl.Utilities: Callback, Buffer, Cyclic, write!, arrow
import Base.show

# Data transfer types
abstract type AbstractLink{T} end
abstract type AbstractBus{T} end

export Link, isconnected, connect, disconnect, launch, Pin
export Bus

include("link.jl")
include("bus.jl")

end