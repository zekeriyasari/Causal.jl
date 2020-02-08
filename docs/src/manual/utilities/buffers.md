# Buffer

```@meta
DocTestSetup  = quote
    using Jusdl
    import Utilities: BufferMode, LinearMode, CyclicMode
end
```

`Buffer` is a primitive to *buffer* the data. Data can be read from and written into a buffer. The mode of the buffer determines the way to read from and write into the buffers. 

## Buffer Modes 

Buffer mode determines the way the data is read from and written into a `Buffer`. Basically, there are four buffer modes: `Normal`, `Cyclic`, `Fifo` and `Lifo`. `Normal`, `Fifo` and `Lifo` are  subtypes of `LinearMode` and `Cyclic` is subtype of `CyclicMode`.

```@docs 
Utilities.BufferMode 
Utilities.LinearMode 
Utilities.CyclicMode
``` 

There are four different buffer modes.

```@docs 
Normal
Cyclic
Lifo 
Fifo
```

## Buffer Constructors 

The `Buffer` construction is very similar to the construction of arrays in Julia. Just specify the mode, element type and length of the buffer. Here are the main `Buffer` constructors: 

```@docs 
Buffer
``` 

## Writing Data into Buffers 
Writing data into a `Buffer` is done with `write!` function.

```@docs
write!(buf::Buffer, val)
```

Recall that when the buffer is full, no more data can be written into the buffer if the buffer mode is of type `LinearMode`. 

```@repl
using Jusdl # hide
normalbuf = Buffer{Normal}(3)
fill!(normalbuf, 1.)
normalbuf.data 
write!(normalbuf, 1.)
```
This situation is the same for `Lifo` and `Fifo` buffers, but not the case for `Cyclic` buffer. 
```@repl
using Jusdl # hide
normalbuf = Buffer{Cyclic}(3)
fill!(normalbuf, 1.)
normalbuf.data 
write!(normalbuf, 3.)
write!(normalbuf, 4.)
```

## Reading Data from Buffers 
Reading data from a `Buffer` is done with `read` function.

```@docs 
read(buf::Buffer)
```

## AbstractArray Interface of Buffers

A `Buffer` can be indexed using the similar syntax of arrays in Julia. That is, `getindex` and `setindex!` methods can be used with known Julia syntax. i.e. `getindex(buf, idx)` is equal to `buf[idx]` and `setindex(buf, val, idx)` is equal to `buf[idx] = val`.

```@repl
using Jusdl  # hide
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
```@docs 
fill!
isempty
isfull
content
mode
snapshot
```
