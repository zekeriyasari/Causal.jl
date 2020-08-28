module Utilities  

using UUIDs 
import Base: read, setproperty!, getindex, setindex!, size, isempty

include("buffer.jl")
include("callback.jl")

end # module  