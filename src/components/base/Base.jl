module Base 

# Type hierarhcy
abstract type AbstractComponent end
abstract type AbstractSource <: AbstractComponent end
abstract type AbstractSystem <: AbstractComponent end
abstract type AbstractSink <: AbstractComponent end 

abstract type AbstractStaticSystem <: AbstractSystem end
abstract type AbstractDynamicSystem <: AbstractSystem end
abstract type AbstractMemory <: AbstractStaticSystem end
abstract type AbstractDiscreteSystem <: AbstractDynamicSystem end
abstract type AbstractODESystem <: AbstractDynamicSystem end
abstract type AbstractRODESystem <: AbstractDynamicSystem end
abstract type AbstractDAESystem <: AbstractDynamicSystem end
abstract type AbstractSDESystem <: AbstractDynamicSystem end
abstract type AbstractDDESystem <: AbstractDynamicSystem end

include("utils.jl")
include("generic_fields.jl")
include("take_step.jl")

end # module