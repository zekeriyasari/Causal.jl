# Pins
`Pin`s are building blocks of [Ports](@ref). Pins can be thought of *gates* of components as they are the most primitive type for data transfer inside and outside the components. There are two types of pins: [`Outpin`](@ref) and [`Inpin`](@ref). The data flows from inside of the components to its outside through `Outpin` while data flow from outside of the components to its inside through `Inpin`.

## Connection and Disconnection of Pins 
In Causal, signal flow modelling approach is adopted(see [Modeling](@ref) and [Simulation](@ref section) for more information on modelling approach in Causal). In this approach, the components drive each other and data flow is unidirectional. The unidirectional data movement is carried out though the [`Link`](@ref)s. A `Link` connects `Outpin`s to `Inpin`s, and the data flow is from `Outpin` to `Inpin`.

!!! note 
    As the data movement is from `Outpin` to `Inpin`, connection of an  `Inpin` to an `Outpin` gives a `MethodError`.

For example, let us construct and `Outpin` and `Inpin`s and connect the together.
```@repl pin_example_1
using Causal # hide 
op = Outpin() 
ip = Inpin() 
link = connect!(op, ip)
```
Note `connect!(op, ip)` connects `op` and `ip` through a `Link` can return the constructed link. The connection of pins can be monitored. 
```@repl pin_example_1
isconnected(op, ip)
```
The constructed `link` can be accessed though the pins. 
```@repl pin_example_1
op.links[1] === link 
ip.link === link
```

!!! note 
    It is possible for an [`Outpin`](@ref) to have multiple [`Link`](@ref)s bound to itself. On contract, an [`Inpin`](@ref) can have just one [`Link`](@ref).

The connected links `Outpin` and `Inpin` can be disconnected using [`disconnect!`](@ref) function. When disconnected, the data transfer from the `Outpin` to `Inpin` is not possible. 

## Data Flow Through Pins 
The data flow from an `Outpin` to an `Inpin`. However for data flow through a pin, a running task must be bound the channel of the link of the pin. See the example below. 
```@repl pin_example_1
t = @async while true 
    take!(ip) === NaN && break 
end 
```
As the task `t` is bound the channel of the `link` data can flow through `op` and `ip`. 
```@repl pin_example_1
put!(op, 1.)
put!(op, 2.) 
put!(op, 3.)
```
Note that `t` is a taker job. As the taker job `t` takes data from `op`, we were able to put values into `op`. The converse is also possible. 
```@repl pin_example_1
op2, ip2  = Outpin(), Inpin() 
link2 = connect!(op2, ip2) 
t2 = @async for item in 1 : 5
    put!(op2, item)
end
take!(ip2)
take!(ip2)
```
Note that in both of the cases given above the data flow is always from an `Outpin` to an `Inpin`. 

!!! warning 
    It is not possible to take data from an `Outpin` and put into `Inpin`. Thus, `take!(pin::Outpoin)` and `put!(pin::Inpin)` throws a method error.

## Full API 
```@autodocs
Modules = [Causal.Connections]
Pages   = ["pin.jl"]
Order = [:type, :function]
```