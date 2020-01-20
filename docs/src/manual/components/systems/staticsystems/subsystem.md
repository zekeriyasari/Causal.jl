# Subsystem

## Construction of SubSystems
A `SubSystem` consists of connected components. Thus, to construct a `SubSystem`, we first construct components, connect them and specify the input and output of `SubSystem`. See the basic constructor.
```@docs 
SubSystem
```

## Basic Operation of SubSystems

The operation of a `SubSystem` is very similar to that of a `StaticSystem`. The only difference is that when a `SubSystem` is triggered from its `trigger` link, it distributes the trigger to the trigger links of its components. Then, each of the components of the `SubSystem` takes steps individually.

Let us construct a subsystem consisting of a generator and an adder. 
```@repl subsystem_ex
using Jusdl # hide 
gen = ConstantGenerator()
adder = Adder(Bus(2))
```
Connect the generator and adder.
```@repl subsystem_ex 
connect(gen.output, adder.input[1])
```
We are ready to construct a `SubSystem`.
```@repl subsystem_ex
sub = SubSystem([gen, adder], [adder.input[2]], adder.output)
```
To trigger the `sub`, we need to launch it,
```@repl subsystem_ex
t = launch(sub)
```
`sub` is ready to be triggered
```@repl subsystem_ex
drive(sub, 1.)
```
Put some data to the input of `sub`.
```@repl subsystem_ex 
put!(sub.input, [1.])
```
The step needs to be approved.
```@repl subsystem_ex
approve(sub)
```
Now print the data written to the outputs of the components of `sub`.
```@repl subsystem_ex 
sub.components[1].output[1].buffer.data[1]
sub.components[2].output[1].buffer.data[1]
```
Note that when `sub` is triggered, `sub` transfer the trigger to all its internal components.
