"""
Includes clock and generator components

# Imports 

    $(IMPORTS) 

# Exports 

    $(EXPORTS)
"""
module Sources 

using DocStringExtensions
using Causal.Utilities
using Causal.Connections
using Causal.Components.ComponentsBase
using UUIDs
import Base: iterate, take!, length, show
import UUIDs: uuid4

include("clock.jl")
include("generators.jl")

end