# Links 

```@meta
DocTestSetup  = quote
    using Jusdl
end
```

Links are built on top of `Channel`s[https://docs.julialang.org/en/v1/manual/parallel-computing/#Channels-1] of Julia. They are used as communication primitives for `Task`s[https://docs.julialang.org/en/v1/manual/control-flow/#man-tasks-1] of Julia. A `Link` includes a `Channel` and a `Buffer`. The mode of the buffer is `Cyclic`.(see [Buffer Modes][@ref) for information on buffer modes). Every item sent through a `Link` is sent through the channel of the `Link` and written to the `Buffer` so that all the data flowing through a `Link` is recorded. Any type of Julia can be transmitted through a `Link`, even if user-defined types. 

!!! note 
    Since the `Link` type is primarily used to transmit data or message between tasks 