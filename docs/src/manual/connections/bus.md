# Busses 

A `Bus` is actually is a bunch of links. Reading from and writing into  data is performed as in the case of [Links](@ref).

## Construction of Bus
A `Bus` is constructed by specifying its element type `T`, number of links `nlinks` and the buffer length of its links.

```@docs 
Bus
```

## Data Flow through Busses
Data flow through the `Bus`ses is very similar to the case in `Link`s. See [Data Flow through Links](@ref) for information about data flow through `Link`s. Runnable tasks must be bound to the links of the busses for data flow through the `Bus`. Again, `put!` and `take!` functions are used to write data from a `Bus` and read from data from a `Bus`.
```@docs 
Connections.put!(bus::Bus, vals)
Connections.take!(bus::Bus)
```

## Indexing and Iteration of Busses 

Busses can be indexed similarly to the arrays in Julia. When indexed, corresponding link of the bus is returned.
```@repl bus_indexing_ex_1
using Jusdl # hide 
b = Bus(3) 
b[1]
b[end] 
b[:]
b[1] = Link()
b[1:2] = [Link(), Link()]
```

## Full API 

```@docs 
Connections.iterate
Connections.eltype
Connections.length
Connections.getindex
Connections.setindex!
```