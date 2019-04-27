# This file contains the dynamic systems of JuSDL.

module DynamicSystems

using DifferentialEquations
using Sundials
using UUIDs
import ..Systems: infer_number_of_outputs
import ......JuSDL.Utilities: _get_an_element, Callback, Buffer
import ......JuSDL.Connections: Link, Bus

include("utils.jl")
include("discrete_systems.jl")
include("ode_systems.jl")
include("dae_systems.jl")
include("rode_systems.jl")
include("sde_systems.jl")
include("dde_systems.jl")
include("system_inference.jl")

end  # module