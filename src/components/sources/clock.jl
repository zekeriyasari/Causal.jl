# This file constains the Clock tools for time synchronization of DsSimulator.

import Base: iterate, showerror, take!, setproperty!

Generator(t0::T, dt::T, tf::T) where T <: Real = Channel(channel -> foreach(t -> put!(channel, t), t0:dt:tf), ctype=T)
Generator(t0::Real, dt::Real, tf::Real) = Generator(promote(t0, dt, tf)...)

mutable struct Clock{T}
    t::T
    dt::T
    tf::T
    generator::Channel{T}
    status::Symbol
    callbacks::Vector{Callback}
    name::String
end

function Clock(t::Real, dt::Real, tf::Real; callbacks=Callback[], name=string(uuid4()))
    T = promote_type(typeof(t), typeof(dt), typeof(tf))
    t, dt, tf = promote(t, dt, tf)
    generator = Channel{T}(0)
    Clock(t, dt, tf, generator, :off, callbacks, name)
end

##### Reading from clock

struct ClockTimeoutError <: Exception
    msg::String
end
showerror(io::IO, e::ClockTimeoutError) = print(io, "ClockTimeoutError: " * e.msg)

function setproperty!(clk::Clock, name::Symbol, val)
    if name == :generator 
        setfield!(clk, name, val)
        if isempty(val.putters) 
            setfield!(clk, :status, :off)
            return
        else
            setfield!(clk, :status, :on)
        end
    end
    if name == :t 
        setfield!(clk, name, val) 
        if clk.t >= clk.tf 
            setfield!(clk, :status, :timedout)
        end
    end
end

function take!(clk::Clock)
    isset(clk) || throw(ClockTimeoutError("Ran out of time"))
    if clk.status == :on 
        clk.t = take!(clk.generator)
    end
    clk.callbacks(clk)
    clk.t
end

##### Controlling clock

isset(clk::Clock) = !isempty(clk.generator.putters)

pause!(clk::Clock) = (clk.status = :paused)

set!(clk::Clock, generator::Channel=Generator(zero(clk.t), clk.dt, clk.tf)) = (clk.generator = generator; clk)
set!(clk::Clock, t::Real, dt::Real, tf::Real) = (set!(clk, Generator(t, dt, tf)); clk)
unset!(clk::Clock) = (set!(clk, Channel{typeof(clk.t)}(0)); clk)

iterate(clk::Clock, t=clk.t) = isready(clk.generator) ? (take!(clk), clk.t) : nothing
