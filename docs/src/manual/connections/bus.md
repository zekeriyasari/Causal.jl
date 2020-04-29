 # Ports

A `Port` is actually is a bunch of pins. Reading from and writing into  data is performed as in the case of [Links](@ref).

## Construction of Ports
A `Port` is constructed by specifying its element type `T`, the number of pins `npins` and the buffer length of its pins.

```@docs 
Outport
Inport
```

## Connection and Disconnection of Ports
The `Ports`ses can be connected to and disconnected from each other. When connected any data written to the master port is also written all slave ports. See the following example.

Let us connect two ports and connect them together.
```@repl connection_of_busses 1
using Jusdl # hide
op = Outport(2)  # Port with `2` pins with buffer length of `5`.
ip = Inport(2)  # Port with `2` pins with buffer length of `5`.
ls = connect(op, ip)
```
Here, `op` is the master port and `ip` is the slave port. That is, data written to `op` is also written into `ip`.
```@repl connection_of_busses 1
t1 = @async while true
    val = take!(ip)
    all(val .=== NaN) && break
    println("Took " * string(val))
end
put!(op, [5., 10.]);
[outbuf(pin.link.buffer) for pin in ip]
```
Note that the data `[5, 10]` written to `op` is also written `ip` since they are connected.

The `Port`ses connected to each other can be disconnected. When disconnected, the data written to master is not written to slaves
```@repl connection_of_busses 1
disconnect(op, ip)
isconnected(op, ip)
```

## Data Flow through Ports
Data flow through the `Port`ses is very similar to the case in `Link`s. See [Data Flow through Links](@ref) for information about data flow through `Link`s. Runnable tasks must be bound to the pins of the ports for data flow through the `Port`. Again, `put!` and `take!` functions are used to write data from a `Port` and read from data from a `Port`.
```@docs 
put!(outport::Outport, vals)
take!(inport::Inport)
```
Any data written to a `Port` is recorded into the buffers of its pins.
```
@repl writing_to_busses
using Jusdl # hide
op, ip = Outport(2), Inport(2);
t = @async while true
    val = take!(ip)
    all(val .=== NaN) && break
    println("Took " * string(val))
end
put!(op, 1.);
ip[1].link.buffer
```

## Indexing and Iteration of Ports 

Ports can be indexed similarly to the arrays in Julia. When indexed, the corresponding pin of the port is returned.
```@repl bus_indexing_ex_1
using Jusdl # hide 
op = Outport(3) 
op[1]
op[end] 
op[:]
op[1] = Outpin()
op[1:2] = [Outpin(), Outpin()]
```
The iteration of `Port`s in a loop is also possible. When iterated, the pins of the `Port` is returned.
```@repl 
using Jusdl # hide 
port = Inport(3)
for pin in port
    @show pin
end
```

## Full API 

```@docs 
datatype(port::AbstractPort{<:AbstractPin{T}}) where T
size(port::AbstractPort)
getindex(port::AbstractPort, idx::Vararg{Int, N}) where N
setindex!(port::AbstractPort, item, idx::Vararg{Int, N}) where N
take!(inport::Inport)
put!(outport::Outport, vals)
similar(outport::Outport{P}, numpins::Int=length(outport)) where {P<:Outpin{T}} where {T} 
``` 