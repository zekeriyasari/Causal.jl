# Utilities module including Callbacks and Buffers.
@reexport module Utilities

using UUIDs

import Base.show 

# Utility types 
export Callback, enable!, disable!, addcallback, deletecallback, isenabled
export Buffer, Normal, Cyclic, Fifo, Lifo, write!, isfull, content, mode, snapshot

include("callbacks.jl")
include("buffers.jl")

end  # module