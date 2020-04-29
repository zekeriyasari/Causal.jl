# Links 

[`Link`](@ref)s are built on top of  [`Channel`s](https://docs.julialang.org/en/v1/manual/parallel-computing/#Channels-1) of Julia. They are used as communication primitives for [`Task`s](https://docs.julialang.org/en/v1/manual/control-flow/#man-tasks-1) of Julia. A [`Link`](@ref) basically includes a `Channel` and a `Buffer`. The mode of the buffer is `Cyclic`.(see [Buffer Modes](@ref) for information on buffer modes). Every item sent through a [`Link`](@ref) is sent through the channel of the [`Link`](@ref) and written to the [`Buffer`](@ref) so that all the data flowing through a [`Link`](@ref) is recorded.

## Construction of Links 
The construction of a `Link` is very simple: just specify its buffer length and element type.
```@repl 
using Jusdl # hide 
Link{Bool}(5)
Link{Int}(10)
Link(5) 
Link()
```

## Data Flow through Links
The data can be read from and written into [`Link`](@ref)s if active tasks are bound to them. [`Link`](@ref)s can be thought of like a pipe. In order to write data to a [`Link`](@ref) from one of its ends, a task that reads written data from the other end must be bounded to the [`Link`](@ref). Similarly, in order to read data from one of the [`Link`](@ref) from one of its end, a task that writes the read data must be bound to the [`Link`](@ref). Reading from and writing to [`Link`](@ref) is carried out with [`take!`](@ref) and [`put!`](@ref) functions. For more clarity, let us see some examples. 

Let us first construct a `Link`,
```@repl link_writing_ex_1
using Jusdl # hide
l = Link(5)
```
`l` is a `Link` with a buffer length of `5` and element type of `Float64`. Not that the `l` is open, but it is not ready for data reading or writing. To write data, we must bound a task that reads the written data.
```@repl link_writing_ex_1
function reader(link::Link)  # Define job.
    while true
        val = take!(link)
        val === NaN && break  # Poison-pill the tasks to terminate safely.
    end
end
t = @async reader(l)
```
The `reader` is defined such that the data written from one end of `l` is read until the data is `NaN`. Now, we have runnable a task `t`. This means the `l` is ready for data writing. 
```@repl link_writing_ex_1
put!(l, 1.)
put!(l, 2.)
```
Note that the data flown through the `l` is written to its `buffer`. 
```@repl link_writing_ex_1
l.buffer
```
To terminate the task, we must write `NaN` to `l`.
```@repl link_writing_ex_1
put!(l, NaN)  # Terminate the task 
t   # Show that the `t` is terminated.
```
Whenever the bound task to the `l` is runnable, the data can be written to `l`. That is, the data length that can be written to `l` is not limited by the buffer length of `l`. But, beware that the `buffer` of `Link`s is `Cyclic`. That means, when the `buffer` is full, its data is overwritten.
```@repl link_writing_ex_1
l = Link(5)
t = @async reader(l)
for item in 1. : 10.
    put!(l, item)
    @show outbuf(l.buffer)
end
```

The case is very similar to read data from `l`. Again, a runnable task is bound the `l` 
```@repl link_reading_ex_1
l = Link(5)
function writer(link::Link, vals)
    for val in vals
        put!(link, val)
    end
end
t = @async writer(l, 1.:5.)
bind(l, t)
take!(l)
take!(l)
```
It is possible to read data from `l` until `t` is active. To read all the data at once, `collect` can be used. 
```@repl link_reading_ex_1
t   
collect(l)
t  # Show that `t` is terminated.
```

## Full API 

```@docs  
Link
put!(link::Link, val)
take!(link::Link)
close(link::Link)
isopen(link::Link)
isreadable(link::Link)
iswritable(link::Link)
isfull(link::Link)
snapshot(link::Link
bind(link::Link, task::Task)
collect(link::Link)
```