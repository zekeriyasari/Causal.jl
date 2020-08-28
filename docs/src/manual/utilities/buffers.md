# Buffer

A [`Buffer`](@ref) is a used to *buffer* the data flowing the connections of a model. Data can be read from and written into a buffer. The mode of the buffer determines the way to read from and write into the buffers. 

## Buffer Modes 

[`BufferMode`](@ref) determines the way the data is read from and written into a [`Buffer`](@ref). Basically, there are four buffer modes: [`Normal`](@ref), [`Cyclic`](@ref), [`Fifo`](@ref) and [`Lifo`](@ref). `Normal`, `Fifo` and `Lifo` are  subtypes of [`LinearMode`](@ref) and `Cyclic` is a subtype of [`CyclicMode`](@ref).

## Buffer Constructors 

The [`Buffer`](@ref) construction is very similar to the construction of arrays in Julia. Just specify the mode, element type and length of the buffer. Here are some examples: 

```@repl 
using Causal # hide 
Buffer{Fifo}(2, 5)
Buffer{Cyclic}(2, 10)
Buffer{Lifo}(Bool, 2, 5)
Buffer(5)
``` 

## Writing Data into Buffers 
Writing data into a [`Buffer`](@ref) is done with [`write!`](@ref) function. Recall that when the buffer is full, no more data can be written into the buffer if the buffer mode is of type `LinearMode`. 

```@repl
using Causal # hide
normalbuf = Buffer{Normal}(3)
foreach(item -> write!(normalbuf, item), 1:3)
normalbuf
write!(normalbuf, 4.)
```
This situation is the same for `Lifo` and `Fifo` buffers, but not the case for `Cyclic` buffer. 
```@repl
using Causal # hide
cyclicbuf = Buffer{Cyclic}(3)
foreach(item -> write!(cyclicbuf, item), 1:3)
cyclicbuf
write!(cyclicbuf, 3.)
write!(cyclicbuf, 4.)
```

## Reading Data from Buffers 
Reading data from a `Buffer` is done with [`read`](@ref) function.

```@repl
using Causal # hide 
nbuf, cbuf, fbuf, lbuf = Buffer{Normal}(5), Buffer{Cyclic}(5), Buffer{Lifo}(5), Buffer{Fifo}(5)
foreach(buf -> foreach(item -> write!(buf, item), 1 : 5), [nbuf, cbuf, fbuf, lbuf])
for buf in [nbuf, cbuf, fbuf, lbuf]
    @show buf 
    for i in 1 : 5 
        @show read(buf)
    end
end
```

## AbstractArray Interface of Buffers

A `Buffer` can be indexed using the similar syntax of arrays in Julia. That is, `getindex` and `setindex!` methods can be used with known Julia syntax. i.e. `getindex(buf, idx)` is equal to `buf[idx]` and `setindex(buf, val, idx)` is equal to `buf[idx] = val`.

```@repl
using Causal  # hide
buf = Buffer(5)
size(buf)
length(buf)
for val in 1 : 5 
    write!(buf, 2val)
end 
buf[1]
buf[3:4]
buf[[3, 5]]
buf[end]
buf[1] = 5 
buf[3:5] = [7, 8, 9]
```

## Full API
```@autodocs
Modules = [Causal.Utilities]
Pages   = ["buffer.jl"]
Order = [:type, :function]
```