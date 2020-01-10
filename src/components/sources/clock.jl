# This file constains the Clock tools for time synchronization of DsSimulator.

import Base: iterate, take!, length

Generator(t0::Real, dt::Real, tf::Real) = 
    Channel(channel -> foreach(t -> put!(channel, t), t0:dt:tf), ctype=promote_type(typeof(t0), typeof(dt), typeof(tf)))

"""
    Clock(t::Real, dt::Real, tf::Real)

Constructs a `Clock` with starting time `t`, final time `tf` and sampling inteval `dt`. When iterated, the `Clock` returns its current time. 

!!! warning 
    When constructed, `Clock` is not running. To take clock ticks from `Clock`, the `Clock` must be setted. See [`take!(clk::Clock)`](@ref) and [`set!`](@ref) 
"""
mutable struct Clock{T<:Real}
    t::T
    dt::T
    tf::T
    generator::Channel{T}
    paused::Bool
    callbacks::Vector{Callback}
    id::UUID
end
Clock(t::Real, dt::Real, tf::Real) = 
    Clock(promote(t, dt, tf)..., Channel{promote_type(typeof(t),typeof(dt),typeof(tf))}(0), false, Callback[], uuid4())

show(io::IO, clk::Clock) = print(io, 
    "Clock(t:$(clk.t), dt:$(clk.dt), tf:$(clk.tf), paused:$(clk.paused), isrunning:$(isrunning(clk)))")

##### Reading from clock
"""
    take!(clk::Clock)

Takes a values from `clk`.

# Example 
```jldocstest
ulia> clk = Clock(0., 0.1, 0.5)
Clock(t:0.0, dt:0.1, tf:0.5, paused:false, isrunning:false)

julia> set!(clk)
Clock(t:0.0, dt:0.1, tf:0.5, paused:false, isrunning:true)

julia> for i = 0 : 5 
       @show take!(clk)
       end
take!(clk) = 0.0
take!(clk) = 0.1
take!(clk) = 0.2
take!(clk) = 0.3
take!(clk) = 0.4
take!(clk) = 0.5
```
"""
function take!(clk::Clock)
    if ispaused(clk)
        @warn "Clock is paused."
        return clk.t
    end
    if isoutoftime(clk)
        @warn "Clock is out of time."
        return clk.t
    end
    if !isrunning(clk)
        @warn "Clock is not running."
        return clk.t
    end
    clk.t = take!(clk.generator)
    clk.callbacks(clk)
    clk.t
end

##### Clock state check 
"""
    isrunning(clk::Clock)

Returns `true` if `clk` if `clk` is running.
"""
isrunning(clk::Clock) = isready(clk.generator)

"""
    ispaused(clk::Clock)

Returns `true` if `clk` is paused. When paused, the currnent time of `clk` is not advanced. See also [`pause!(clk::Clock)`](@ref)
"""
ispaused(clk::Clock) = clk.paused

"""
    isoutoftime(clk::Clock)

Returns `true` if `clk` is out of time, i.e., the current time of `clk` exceeds its final time. 
"""
isoutoftime(clk::Clock) = clk.t >= clk.tf

##### Controlling clock.
"""
    set(clk::Clock, t::Real, dt::Real, tf::Real)

Sets `clk` for current clock time `t`, sampling time `dt` and final time `tf`. After the set,  it is possible to take clock tick from `clk`. See also [`take!(clk::Clock)`](@ref)

# Example 
```jldocstest
julia> clk = Clock(0., 0.1, 0.5)
Clock(t:0.0, dt:0.1, tf:0.5, paused:false, isrunning:false)

julia> take!(clk)
┌ Warning: Clock is not running.
└ @ Jusdl.Components.Sources ~/.julia/dev/Jusdl/src/components/sources/clock.jl:47
0.0

julia> set!(clk)
Clock(t:0.0, dt:0.1, tf:0.5, paused:false, isrunning:true)

julia> take!(clk)
0.0
```
"""
function set!(clk::Clock, t::Real, dt::Real, tf::Real)
    set!(clk, Generator(t, dt, tf))
    clk.t = t 
    clk.dt = dt 
    clk.tf = tf
    clk
end
function set!(clk::Clock, generator::Channel=Generator(clk.t, clk.dt, clk.tf)) 
    clk.generator = generator
    clk.paused=false
    clk
end

"""
    stop!(clk::Clock)

Unsets `clk`. After the stpp, it is possible to take clock ticks from `clk`. See also [`take!(clk::Clock)`](@ref)

# Example
```jldocstest
julia> clk
Clock(t:0.0, dt:0.1, tf:0.5, paused:false, isrunning:false)

julia> set!(clk)
Clock(t:0.0, dt:0.1, tf:0.5, paused:false, isrunning:true)

julia> take!(clk)
0.0

julia> stop!(clk)
Clock(t:0.0, dt:0.1, tf:0.5, paused:false, isrunning:false)

julia> take!(clk)
┌ Warning: Clock is not running.
└ @ Jusdl.Components.Sources ~/.julia/dev/Jusdl/src/components/sources/clock.jl:47
0.0
```
"""
function stop!(clk::Clock)
    set!(clk, Channel{typeof(clk.t)}(0)) 
    clk
end

""" 
    pause!(clk::Clock)

Pauses `clk`. When paused, the current time of `clk` does not advance.

# Example
```jldocstest
julia> clk = Clock(0., 0.1, 0.5);

julia> set!(clk);

julia> for i = 1 : 5
       i > 3 && pause!(clk)
       @show take!(clk)
       end

take!(clk) = 0.0
take!(clk) = 0.1
take!(clk) = 0.2
┌ Warning: Clock is paused.
└ @ Jusdl.Components.Sources ~/.julia/dev/Jusdl/src/components/sources/clock.jl:58
take!(clk) = 0.2
┌ Warning: Clock is paused.
└ @ Jusdl.Components.Sources ~/.julia/dev/Jusdl/src/components/sources/clock.jl:58
take!(clk) = 0.2
```
"""
pause!(clk::Clock) = (clk.paused = true; clk)

##### Iterating clock.
"""
    iterate(clk::Clock[, t=clk.t)

Iterationk interface for `clk`. `clk` can be iterated in a loop.

# Example
```jldocstest
julia> clk = Clock(0., 0.1, 0.3);

julia> set!(clk)
Clock(t:0.0, dt:0.1, tf:0.3, paused:false, isrunning:true)

julia> for t in clk
       @show t 
       end
t = 0.0
t = 0.1
t = 0.2
t = 0.3
```
"""
iterate(clk::Clock, t=clk.t) = isready(clk.generator) ? (take!(clk), clk.t) : nothing

##### ProgressMeter interface.
### This `length` method is implemented for [ProgressMeter](https://github.com/timholy/ProgressMeter.jl)
length(clk::Clock) = length(clk.t:clk.dt:clk.tf)
