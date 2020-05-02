# Clock

`Jusdl` is a *clocked* simulation environment. That is, model components are evolved in different time intervals, called the *sampling interval*. During the simulation, model components are triggered by these generated time pulses. A `Clock` instance is used to to generate those time pulses. The simulation time settings--the simulation start time, stop time, sampling interval--are configured through the `Clock`.

## Construction of Clock
Construction of `Clock` is done by specifying its start time and final time and the simulation sampling period. 
```@repl clock_example_1
using Jusdl # hide 
Clock(0., 1, 10.)
Clock{Int}(1, 1, 10)
```

## Basic Usage of Clocks 
A `Clock` has a [Callback](@ref) list so that a [`Callback`](@ref) can be constructed to trigger specific events configured with the time settings. See the following case study. 

Let us consider a `Clock` with initial time of `0`, sampling interval of `1` and final time of `10`.
```@repl clk_ex
using Jusdl # hide 
clk = Clock(0., 1., 10.)
```
Notice that `clk` is not *running*, since it is not set. Now, let us set it
```@repl clk_ex
set!(clk)
```
`clk` is ready to run, i.e., to be iterated. The following commands generated clock ticks and shows it on the console.
```@repl clk_ex 
for t in clk 
    @show t 
end
```
At this point, `clk` is out of time. The current time of `clk` does not advance any more. 
```@repl clk_ex
take!(clk)
```

But, `clk` can be reset again.
```@repl clk_ex
set!(clk, 0., 1., 10.)
```
Consider that we want to configure an alarm. For this, let us consider that when the time of `clk` is greater than `5` an alarm message is printed on the console. To this end, we need to construct a [`Callback`](@ref) and add it to the callbacks of `clk`. (When constructed callback list of `clk` is empty.)
```@repl clk_ex 
condition(clk) = clk.t > 5
action(clk) = println("Clock time = ", clk.t)
clk = Clock(0., 1., 10., callbacks=Callback(condition, action))
set!(clk)
```
Now, let us run `clk` by iterating it. 
```@repl clk_ex 
for t in clk 
    @show t 
end 
```
Note that we, constructed a simple callback. It is of course possible to construct more complex callbacks.

## Usage of Clocks with ProgressMeter 
It also possible to iterate the `Clock`s by using a progress meter. See [ProgressMeter](https://github.com/timholy/ProgressMeter.jl) for further information for progress meter.

```julia
using Jusdl
using ProgressMeter
clk = Clock(0., 0.01, 1.)
set!(clk)
@showprogress for t in clk 
end 
```
Note that `clk` is just iterated.

## Full API
```@docs 
Clock 
take!(clk::Clock)
isrunning
ispaused
isoutoftime
set!
stop!
pause!
iterate(clk::Clock)
```

