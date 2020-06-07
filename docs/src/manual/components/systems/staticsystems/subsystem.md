# Subsystem

## Construction of SubSystems
A SubSystem consists of connected components. Thus, to construct a `SubSystem`, we first construct components, connect them and specify the input and output of `SubSystem`.


## Basic Operation of SubSystems

The operation of a `SubSystem` is very similar to that of a [`StaticSystem`](@ref). The only difference is that when a `SubSystem` is triggered through its `trigger` pin, it distributes the trigger to the trigger pins of its components. Then, each of the components of the `SubSystem` takes steps individually.

Let us construct a subsystem consisting of a generator and an adder. 
```@repl subsystem_ex
using Jusdl # hide 
gen = ConstantGenerator()
adder = Adder((+,+))
```
Connect the generator and adder.
```@repl subsystem_ex 
connect!(gen.output, adder.input[1])
```
We are ready to construct a `SubSystem`.
```@repl subsystem_ex
sub = SubSystem([gen, adder], [adder.input[2]], adder.output)
```
To trigger the `sub`, we need to launch it. For that purpose, we construct ports and pins for input-output and signaling.
```@repl subsystem_ex
oport, iport, trg, hnd = Outport(length(sub.input)), Inport(length(sub.output)), Outpin(), Inpin{Bool}()
connect!(oport, sub.input)
connect!(sub.output, iport)
connect!(trg, sub.trigger)
connect!(sub.handshake, hnd)
t = launch(sub)
t2 = @async while true 
    all(take!(iport) .=== NaN) && break 
    end
```
`sub` is ready to be triggered,
```@repl subsystem_ex
put!(trg, 1.)
```
Put some data to the input of `sub` via `oport` (since `oport` is connected to `sub.input`)
```@repl subsystem_ex 
put!(oport, [1.])
```
The step needs to be approved.
```@repl subsystem_ex
take!(hnd)
```
Now print the data written to the outputs of the components of `sub`.
```@repl subsystem_ex 
sub.components[1].output[1].links[1].buffer[1]
sub.components[2].output[1].links[1].buffer[1]
```
Note that when `sub` is triggered, `sub` transfer the trigger to all its internal components.

```@autodocs
Modules = [Jusdl]
Pages   = ["subsystem.jl"]
Order = [:type, :function]
```