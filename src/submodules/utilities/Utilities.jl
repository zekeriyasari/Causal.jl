
"""
Utilities module that include primitive structures of `Causal`. 

# Exports 
    $(EXPORTS) 

# Imports 
    $(IMPORTS)
"""
module Utilities  

using DocStringExtensions
using UUIDs 
import Base: read, setproperty!, getindex, setindex!, size, isempty

include("buffer.jl")
include("callback.jl")

end # module  