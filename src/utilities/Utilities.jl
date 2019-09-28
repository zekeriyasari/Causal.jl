# Utilities module including Callbacks and Buffers.
@reexport module Utilities

using UUIDs

import Base.show 
const arrow = "  \u21B3"

# Utility types 
abstract type AbstractBuffer{T} end
# abstract type AbstractBuffer{T} <: AbstractVector{T} end
# abstract type AbstractDoubleBuffer{T, N} <: AbstractBuffer{T, N} end

export Callback, enable!, disable!, addcallback, deletecallback, isenabled
export Buffer, Normal, Cyclic, Fifo, Lifo, write!, isfull, content, mode, snapshot

include("callbacks.jl")
include("buffers.jl")

end  # module