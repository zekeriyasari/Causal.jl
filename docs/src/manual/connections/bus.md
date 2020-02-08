# Busses 

A `Bus` is actually is a bunch of links. Reading from and writing into  data is performed as in the case of [Links](@ref).

## Construction of Bus
A `Bus` is constructed by specifying its element type `T`, number of links `nlinks` and the buffer length of its links.

```@docs 
Bus
```

## Connection and Disconnection of Busses
The `Bus`ses can be connected and disconnected to each other. When connected any data written to the master bus is also written all slave busses. See the following example.

Let us connect two busses and connect them together.
```@repl connection_of_busses 1
using Jusdl # hide
b1 = Bus(2, 5)  # Bus with `2` links with buffer length of `5`.
b2 = Bus(2, 5)  # Bus with `2` links with buffer length of `5`.
connect(b1, b2)
```
Here, `b1` is the master bus and `b2` is the slave bus. That is, data written to `b1` is also written into `b2`.
```@repl connection_of_busses 1
t1 = @async while true
    val = take!(b1)
    all(val .=== NaN) && break
    println("Took " * string(val))
end
t2 = @async while true
    val = take!(b2)
    all(val .=== NaN) && break
    println("Took " * string(val))
end
put!(b1, [5., 10.]);
[b1[i].buffer.data for i = 1 : 2]
[b2[i].buffer.data for i = 1 : 2]
```
Note that the data `[5, 10]` written to `b1` is also written `b2` since they are connected.

The `Bus`ses connected to each other can be disconnected. When disconnected, the data written to master is not written to slaves
```@repl connection_of_busses 1
disconnect(b1, b2)
isconnected(b1, b2)
```

## Data Flow through Busses
Data flow through the `Bus`ses is very similar to the case in `Link`s. See [Data Flow through Links](@ref) for information about data flow through `Link`s. Runnable tasks must be bound to the links of the busses for data flow through the `Bus`. Again, `put!` and `take!` functions are used to write data from a `Bus` and read from data from a `Bus`.
```@docs 
put!(bus::Bus, vals)
take!(bus::Bus)
```
Any data written to a `Bus` is recorded into the buffers of its links.
```
@repl writing_to_busses
using Jusdl # hide
b = Bus(2, 5);
t = @async while true
    val = take!(b)
    all(val .=== NaN) && break
    println("Took " * string(val))
end
put!(b, 1.);
b[1].buffer.data
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
The iteration of `Bus`ses in a loop is also possible. When iterated, the links of the `Bus` is returned.
```@repl 
using Jusdl # hide 
bus = Bus(3)
for link in bus
    @show link
end
```

## Full API 

```@docs 
Connections.hasslaves(bus::Bus)
Connections.hasmaster(bus::Bus)
Connections.close(bus::Bus)
Connections.isfull(bus::Bus)
Connections.isreadable(bus::Bus)
Connections.iswritable(bus::Bus)
Connections.snapshot(bus::Bus)
Connections.launch(bus::Bus)
Connections.launch(bus::Bus, valrange::AbstractVector)
size(bus::Bus)
getindex(bus::Bus, idx::Vararg{Int, N}) where N
setindex!(bus::Bus, item, idx::Vararg{Int, N}) where N
```