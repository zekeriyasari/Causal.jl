
"""
`Connections` module including types such as links, pins ans ports to connect the components. 

# Imports

    $(IMPORTS) 

# Exports 

    $(EXPORTS)
"""
module Connections 

using DocStringExtensions
using UUIDs
using Causal.Utilities

import Base: put!, take!, close, isready, eltype, isopen, isreadable, iswritable, bind, collect, iterate,   
    size, getindex, setindex!, display

include("link.jl")
include("pin.jl")
include("port.jl")

end # module 