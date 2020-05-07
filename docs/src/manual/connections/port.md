 # Ports

A `Port` is actually is a bunch of pins (See [Pins](@ref) for mor information on pins.). As such, the connection, disconnection and data transfer are very similar to those of pins. Basically, there are two type of port: [`Outport`](@ref) and [`Inport`](@ref). The data flows from outside of a component to its inside through an `Inport` while data flows from inside of the component to its outside through an `Outport`.

## Construction of Ports
A port (both `Inport` and `Outport`) is constructed by specifying its element type `T`, the number of pins `npins` and the buffer length of its pins.

```@repl port_example_1
using Jusdl # hide
Outport{Bool}(5)
Outport{Int}(2) 
Outport(3) 
Outport() 
Inport{Bool}(5)
Inport{Int}(2) 
Inport(3) 
Inport() 
```

## Connection and Disconnection of Ports
The ports can be connected to and disconnected from each other. See the following example.

Let us construct and `Outport` and an `Inport` and connect them together.
```@repl port_example_1
op1 = Outport(2)  
ip1 = Inport(2) 
ls = connect!(op1, ip1)
```
Note that we connected all pins of `op` to `ip`. We cannot connect the ports partially. 
```@repl port_example_1
op2, ip21, ip22 = Outport(5), Inport(2), Inport(3) 
ls1 = connect!(op2[1:2], ip21)
ls2 = connect!(op2[3:5], ip22)
```
The connectedness of ports can be checked. 
```@repl port_example_1
isconnected(op2[1], ip21[1])
isconnected(op2[1], ip21[2])
isconnected(op2[1:2], ip21)
isconnected(op2[3:5], ip22)
isconnected(op2[5], ip22[3])
```
Connected ports can be disconnected.
```@repl port_example_1
disconnect!(op2[1], ip21[1])
disconnect!(op2[2], ip21[2])
disconnect!(op2[3:5], ip22)
```
Now check again the connectedness,
```@repl port_example_1
isconnected(op2[1], ip21[1])
isconnected(op2[1], ip21[2])
isconnected(op2[1:2], ip21)
isconnected(op2[3:5], ip22)
isconnected(op2[5], ip22[3])
```

## Data Flow Through Ports
Data flow through the ports is very similar to the case in pins(see [Data Flow Through Pins](@ref) for information about data flow through pins). Running tasks must be bound to the links of pins of the ports for data flow through the ports.

Let us construct an `Outport` and an `Inport`, connect them together with links and perform data transfer from the `Outport` to the `Inport` through the links. 
```@repl port_example_1
op3, ip3 = Outport(2), Inport(2)
ls = connect!(op3, ip3)
t = @async while true
    val = take!(ip3)
    all(val .=== NaN) && break
    println("Took " * string(val))
end
put!(op3, 1.);
ip3[1].link.buffer
```
Note that the data flowing through the links are also written into the buffers of links.

## Indexing and Iteration of Ports 
Ports can be indexed similarly to the arrays in Julia. When indexed, the corresponding pin of the port is returned.
```@repl port_example_1
op4 = Outport(3) 
op4[1]
op4[end] 
op4[:]
op4[1] = Outpin()
op4[1:2] = [Outpin(), Outpin()]
```
The iteration of `Port`s in a loop is also possible. When iterated, the pins of the `Port` is returned.
```@repl port_example_1
ip5 = Inport(3)
for pin in ip5
    @show pin
end
```

## Full API 
```@autodocs
Modules = [Jusdl]
Pages   = ["port.jl"]
Order = [:type, :function]
```