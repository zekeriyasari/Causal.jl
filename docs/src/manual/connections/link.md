# Links 

```@meta
DocTestSetup  = quote
    using Jusdl
end
```

Links are built on top of `Channel`s[https://docs.julialang.org/en/v1/manual/parallel-computing/#Channels-1] of Julia. They are used as communication primitives for `Task`s[https://docs.julialang.org/en/v1/manual/control-flow/#man-tasks-1] of Julia. A `Link` includes a `Channel` and a `Buffer`. The mode of the buffer is `Cyclic`.(see [Buffer Modes][@ref) for information on buffer modes). Every item sent through a `Link` is sent through the channel of the `Link` and written to the `Buffer` so that all the data flowing through a `Link` is recorded. Any type of Julia can be transmitted through a `Link`, even if user-defined types. 

A `Link` has a buffer to record flowing data and channel to transmit data between tasks. The `Link`s can be connected to each other. To manage connection of the `Links`, `Pin` types are used. Thus, a `Link` has one pair of pin: `leftpin` and `rightpin`. When connected, a link has a `master` link and `slaves` links. Let us assume that links `l1` and `l2` are connected to each other and data flows from `l1` to `l2`. Then, `l1` is the master link of `l2`, similarly, `l2` is the slave links of `l1`. 


# Construction of Links 
The construction of a `Link` is very simple. See the main constructor. 

```@docs 
Link
```

That is, to construct a `Link`, just specify the its buffer length and the type of element to be flow through the `Link`. See the examples. 

```@repl
using Jusdl # hide 
l1 = Link{Int}(5)   # A `Link` with buffer size of `5` and `Int` buffer element type.
l2 = Link{Matrix{Float64}}(10)   # A `Link` with buffer size of `10` and `Matrix{Float64}` buffer element type.
```

Note that when initialized, a `Link` has no `master` and `slaves`. The `Lin` is not readable and writable since there is no active tasks bound ot `Link`.

!!! warning
    Since the `Link` type is primarily used to transmit data or message between tasks in order there must be active tasks bound the `Link`. 

Similar to the case of `Buffer`s, the data type that can flow the `Link` can be any Julia type, even a user-defined type. 
```@repl 
using Jusdl # hide
struct Object
    x::Int 
end 
l = Link{Object}(3)     # A `Link` that with element type `Object` with buffer size `3`.
```

## Connection of Links 
The `Link`s can be connected to each other. For that, `connect` function is used. 

```@docs 
connect 
```

## Full API 

```@docs  
Connections.put!
Connections.take!
Connections.close
Connections.isopen
Connections.isreadable
Connections.iswritable
Connections.isfull 
Connections.isconnected
Connections.hasslaves 
Connections.hasmaster 
Connections.getmaster 
Connections.getslaves 
Connections.snapshot 
Connections.Connections.UnconnectedLinkError
Connections.Connections.Pin
Connections.findflow 
Connections.disconnect 
Connections.insert 
Connections.release
Connections.launch 
```