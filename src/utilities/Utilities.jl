# Utilities module including Callbacks and Buffers.
@reexport module Utilities

# Utility types 
abstract type AbstractBuffer{T, N} <: AbstractArray{T, N} end
abstract type AbstractDoubleBuffer{T, N} <: AbstractBuffer{T, N} end

export Callback, enable!, disable!
export Buffer, write!, isfull, clean!, content, mode, snapshot

include("callbacks.jl")
include("buffers.jl")

end  # module