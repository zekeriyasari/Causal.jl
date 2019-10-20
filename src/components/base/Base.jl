# This file contains the Base module of Plugins module.

@reexport module Base 

# Type hierarhcy
abstract type AbstractComponent end
abstract type AbstractSource <: AbstractComponent end
abstract type AbstractSystem <: AbstractComponent end
abstract type AbstractSink <: AbstractComponent end 

abstract type AbstractStaticSystem <: AbstractSystem end
abstract type AbstractDynamicSystem <: AbstractSystem end
abstract type AbstractSubSystem <: AbstractSystem end
abstract type AbstractMemory <: AbstractStaticSystem end
abstract type AbstractDiscreteSystem <: AbstractDynamicSystem end
abstract type AbstractODESystem <: AbstractDynamicSystem end
abstract type AbstractRODESystem <: AbstractDynamicSystem end
abstract type AbstractDAESystem <: AbstractDynamicSystem end
abstract type AbstractSDESystem <: AbstractDynamicSystem end
abstract type AbstractDDESystem <: AbstractDynamicSystem end

include("utils.jl")
include("genericfields.jl")
include("takestep.jl")


export AbstractComponent, AbstractSource, AbstractSystem, AbstractSink,
    AbstractStaticSystem, AbstractDynamicSystem, AbstractSubSystem, AbstractMemory, 
    AbstractDiscreteSystem, AbstractODESystem, AbstractRODESystem, AbstractDAESystem,
    AbstractSDESystem, AbstractDDESystem

export @generic_source_fields, @generic_system_fields, @generic_sink_fields, @generic_system_fields, 
    @generic_static_system_fields, @generic_dynamic_system_fields

end # module