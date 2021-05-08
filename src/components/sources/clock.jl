# This file constains the Clock tools for time synchronization of DsSimulator.

import Base: iterate, take!, length

mutable struct Clock{T, CB}
    generator::T
    paused::Bool
    callbacks::CB
    name::Symbol
    uuid::UUID
    function Clock(generator::T; callbacks::CB=nothing, name=Symbol()) where {T, CB} 
        if hasmethod(iterate, Tuple{T})
            new{T, CB}(generator, false, callbacks, name, uuid4())
        else 
            error("$gen is not iterable")
        end 
    end 
end
Clock(ti::Real, dt::Real, tf::Real; kwargs...) = Clock(ti:dt:tf; kwargs...)

show(io::IO, clk::Clock) = print(io, "Clock(gen:$(clk.generator), paused:$(clk.paused))")

function iterate(clk::Clock, state...)
    clk.paused && (@warn "Clock is paused"; return nothing)
    iter = iterate(clk.generator, state...)
    applycallbacks(clk) 
    iter 
end

length(clk::Clock) = length(clk.generator)
