# Utilities module including Callbacks and Buffers.
@reexport module Utilities

using UUIDs

# Utility types 
abstract type AbstractBuffer{T, N} <: AbstractArray{T, N} end
abstract type AbstractDoubleBuffer{T, N} <: AbstractBuffer{T, N} end

export Callback, enable!, disable!
export Buffer, write!, isfull, content, mode, snapshot

include("callbacks.jl")
include("buffers.jl")

end  # module