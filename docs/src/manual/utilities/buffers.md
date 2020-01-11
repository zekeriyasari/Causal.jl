# Buffer

```@meta
DocTestSetup  = quote
    using Jusdl
    import Utilities: BufferMode, LinearMode, CyclicMode
end
```

`Buffer` is a primitive to *buffer* the data. Data can be of any Julia type. Data can be read from and written into a buffer, and the mode of the buffer determines the way to read from and write into the buffers. 

## Buffer Modes 

Buffer mode determines the way the data is read from and written into a `Buffer`. 

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

!!! warning 
    Note that `Buffer` is one dimensional. That is, the length of the data must be specified when constructing a `Buffer`. 

!!! warning 
    Note that when a `Buffer` is initialized, the internal data of the `Buffer` is of `missing`. 

Let us try some examples. Here are some simple buffer construction.
```@repl
using Jusdl # hide
buf1 = Buffer{Normal}(Float64, 5)   # Buffer of length `5` with mode `Normal` and element type of `Float64`. 
buf2 = Buffer{Fifo}(Int, 3)       # Buffer of length `5` with mode `Fifo` and element type of `Int`. 
buf3 = Buffer(Vector{Int}, 3)       # Buffer of length `5` with mode `Cyclic` and element type of `Vector{Int}`. 
buf4 = Buffer(Matrix{Float64}, 5)    # Buffer of length `5` with mode `Cyclic` and element type of `Matrix{Float64}`. 
buf5 = Buffer(5)                    # Buffer of length `5` with mode `Cyclic` and element type of `Float64`.
```
Note that the element type of `Buffer` can be any Julia type, even any user-defined type. Note the following example, 
```@repl 
using Jusdl #hide 
struct Object end       # Define a dummy type. 
buf = Buffer{Normal}(Object, 4)  # Buffer of length `4` with element type `Object`.
```

## Writing Data into Buffers 
Writing data into a `Buffer` is done with `write!` function.

```@docs
write!
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

!!! warning 
    Since when a `Buffer` is constructed, it is empty, no data is written to it. But it is initialized with `missing` data. Thus, the element type of buffer of type `Buffer{M, T} where {M, T}` is `Union{Missing, T} where T`. Benchmarks that has been carried out shows that there is no performance bottle neck is such design since Julia's compiler can compile optimized code for such a small unions. Therefore it is possible to write `missing` into a buffer of type `Buffer{M,T} where {M,T}`.

## Reading Data from Buffers 
Reading data from a `Buffer` is done with `read` function.

```@docs 
read
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
```
