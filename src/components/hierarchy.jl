# This file contains the Base module of Plugins module.

# Type hierarchy
"""
    $(TYPEDEF)

Abstract type of all components 
"""
abstract type AbstractComponent end

"""
    $(TYPEDEF) 

Abstract typeof all source components
"""
abstract type AbstractSource <: AbstractComponent end

"""
    $(TYPEDEF)

Abstract type of all system components
"""
abstract type AbstractSystem <: AbstractComponent end

"""
    $(TYPEDEF)

Abstract type of all sink components 
"""
abstract type AbstractSink <: AbstractComponent end 

"""
    $(TYPEDEF)

Abstract type of all static systems
"""
abstract type AbstractStaticSystem <: AbstractSystem end

"""
    $(TYPEDEF)

Abstract type of all dynamic system components
"""
abstract type AbstractDynamicSystem <: AbstractSystem end

"""
    $(TYPEDEF)

Abstract type of all subsystem components 
"""
abstract type AbstractSubSystem <: AbstractSystem end

"""
    $(TYPEDEF)

Abstract type of all memory components
"""
abstract type AbstractMemory <: AbstractStaticSystem end

"""
    $(TYPEDEF)

Abstract type of all dynamic systems modelled by dicrete difference equations.
"""
abstract type AbstractDiscreteSystem <: AbstractDynamicSystem end

"""
    $(TYPEDEF)

Abstract type of all dynamical systems modelled by ordinary differential equations.
"""
abstract type AbstractODESystem <: AbstractDynamicSystem end

"""
    $(TYPEDEF)

Abstract type of all dynamical systems modelled by random ordinary differential equations.
"""
abstract type AbstractRODESystem <: AbstractDynamicSystem end

"""
    $(TYPEDEF)

Abstract type of all dynamical systems modelled by differential algebraic equations
"""
abstract type AbstractDAESystem <: AbstractDynamicSystem end

"""
    $(TYPEDEF)

Abstract type of all dynamical systems modelled by stochastic differential equations.
"""
abstract type AbstractSDESystem <: AbstractDynamicSystem end

"""
    $(TYPEDEF)

Abstract type of all dynamical systems modlled by delay dynamical systems.
"""
abstract type AbstractDDESystem <: AbstractDynamicSystem end
