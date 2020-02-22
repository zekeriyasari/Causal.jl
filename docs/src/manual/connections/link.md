# Links 

```@meta
DocTestSetup  = quote
    using Jusdl
end
```

Links are built on top of  [`Channel`s](https://docs.julialang.org/en/v1/manual/parallel-computing/#Channels-1) of Julia. They are used as communication primitives for [`Task`s](https://docs.julialang.org/en/v1/manual/control-flow/#man-tasks-1) of Julia. A `Link` basically includes a `Channel` and a `Buffer`. The mode of the buffer is `Cyclic`.(see [Buffer Modes](@ref) for information on buffer modes). Every item sent through a `Link` is sent through the channel of the `Link` and written to the `Buffer` so that all the data flowing through a `Link` is recorded.

## Construction of Links 
The construction of a `Link` is very simple: just specify its buffer length and element type.
```@docs 
Link
```

## Connection and Disconnection of Links 
`Link`s can be connected to each other so that data can flow from one link to another. The flows from link `l1` to `l2`, then `l1` is said to *drive* `l2` and `l1` is called as *master* and `l2` is called as `slave`. A `Link` can have more than one slave but can have just one master. When a `Link` is initialized, it has no `master` and `slaves`.

```@docs 
connect 
```

Similarly `Link`s can be disconnected. 

```@docs 
disconnect
```

!!! warning 
    Note that the order of arguments is **important** when the links are connected. `connect(l1, l2)` connects `l1` and `l2` such that `l1` drives `l2`, i.e., data flows from `l1` to `l2`. In other words, `l1` is the master link and `l2` is the slave link. However, the order of arguments is not important when the links are disconnected. `disconnect(l1, l2)` does the same thing with `disconnect(l2, l1)`, i.e., it justs breaks the connection between `l2` and `l1`.

## Data Flow through Links
The data can be read from and written into `Link`s if active tasks are bound to them. Links can be thought of like a pipe. In order to write data to a `Link` from one of its ends, a task that reads written data from the other end must be bounded to the `Link`. Similarly, in order to read data from one of the `Link` from one of its end, a task that writes the read data must be bound to the `Link`. Reading from and writing to `Link` is carried out with [`take!`](@ref) and [`put!`](@ref) functions. For more clarity, let us see some examples. 

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
To terminate the task, we must write `NaN` to `l`.
```@repl link_writing_ex_1
put!(l, NaN)  # Terminate the task 
t   # Show that the `t` is terminated.
```
Note that the data flown through the `l` is written to its `buffer`. 
```@repl link_writing_ex_1
l.buffer.data
```
Whenever the bound task to the `l` is runnable, the data can be written to `l`. That is, the data length that can be written to `l` is not limited by the buffer length of `l`. But, beware that the `buffer` of `Link`s is `Cyclic`. That means, when the `buffer` is full, its data is overwritten.
```@repl link_writing_ex_1
l = Link(5)
t = @async reader(l)
for item in 1. : 10.
    put!(l, item)
    @show l.buffer.data
end
```

The case is very similar to read data from `l`. Again a runnable task is bound the `l` 
```@repl link_reading_ex_1
using Jusdl # hide
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
put!(link::Link, val)
take!(link::Link)
close(link::Link)
isopen(link::Link)
isreadable(link::Link)
iswritable(link::Link)
isfull(link::Link)
isconnected
Connections.hasslaves(link::Link) 
Connections.hasmaster(link::Link)
Connections.getmaster(link::Link) 
Connections.getslaves(link::Link)
Connections.UnconnectedLinkError
Pin
findflow(link1::Link, link2::Link) 
insert(master::Link, slave::Link, new::Link)
release(link::Link)
bind(link::Link, task::Task)
collect(link::Link)
launch(link::Link) 
launch(link::Link, valrange) 
```