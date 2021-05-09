# This file constains the Clock tools for time synchronization of DsSimulator.

import Base: iterate, take!, length

"""
    $TYPEDEF 

`Clock` generates time instants to sample the systems. A `Clock` is an iterable 

# Fields 
    $TYPEDFIELDS

# Example 
```jldoctest
julia> clk = Clock(0 : 2) 
Clock(gen:0:2, paused:false)

julia> for t in clk 
       @show t 
       end 
t = 0
t = 1
t = 2
```
"""
mutable struct Clock{T, CB}
    "Internal generator. Can be any iterable"
    generator::T
    "If true, clock iteration is halted"
    paused::Bool
    "Callback set. See [`Callback`](@ref)"
    callbacks::CB
    "Name of clock"
    name::Symbol
    "Identiy number of clock"
    uuid::UUID
    function Clock(generator::T; callbacks::CB=nothing, name=Symbol()) where {T, CB} 
        if hasmethod(iterate, Tuple{T})
            new{T, CB}(generator, false, callbacks, name, uuid4())
        else 
            error("$gen is not iterable")
        end 
    end 
end

# Backward compatibility
Clock(ti::Real, dt::Real, tf::Real; kwargs...) = Clock(ti:dt:tf; kwargs...)

show(io::IO, clk::Clock) = print(io, "Clock(gen:$(clk.generator), paused:$(clk.paused))")

##### Iteration 
function iterate(clk::Clock, state...)
    clk.paused && (@warn "Clock is paused"; return nothing)
    iter = iterate(clk.generator, state...)
    applycallbacks(clk) 
    iter 
end

""" 
    $SIGNATURES

Pauses `clk`. When paused, the iteration of clock is halted. 
# Example 
```jldoctest 
julia> clk = Clock(0 : 5)
Clock(gen:0:5, paused:false)

julia> iterate(clk) 
(0, 0)

julia> iterate(clk, 1)
(2, 2)

julia> pause!(clk) 
Clock(gen:0:5, paused:true)

julia> iterate(clk, 1)
┌ Warning: Clock is paused
└ @ Causal ~/.julia/dev/Causal/src/components/sources/clock.jl:41
```
"""
pause!(clk::Clock) = (clk.paused = true; clk)

length(clk::Clock) = length(clk.generator)
