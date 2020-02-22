# Generators

## FunctionGenerator
`FunctionGenerator` is the generic function generator. The output waveform is shaped by its *output function*. A `FunctionGenerator` can be constructed by specifying its output function `outputfunc`.

```@docs 
FunctionGenerator
```

## Basic Operation AbstractSource
An `AbstractSource` is a subtype of `AbstractComponent`. (See [Components](@ref) for more information.) An `AbstractComponent` has `input` and `output` for data flow. The `AbstractComponent` reads data from the `input` and writes data to `output`. Since the input-output relation of `AbstractSource` depends on just the current time `t`, `Source`s does not have `input`s since they do not read input values. They just need time `t` to compute its output. During their evolution, the `AbstractComponent` read time `t` from their `trigger` links, computes their output according to their output function and writes its computed output to their `output` busses. An `AbstractComponent` also writes `true` to their `handshake` links to signal that the evolution is succeeded. To further clarify the operation of `AbstractSource`, let us do some examples. 

```@repl source_ex
using Jusdl # hide 
outputfunc(t) = t * exp(t) + sin(t)
gen = FunctionGenerator(outputfunc)
```
We constructed a [`FunctionGenerator`](@ref) which is an `AbstractSource`.
```@repl source_ex
gen isa AbstractSource
```
To drive `gen`, that is to make `gen` evolve, we need to launch `gen`. 
```@repl source_ex
t = launch(gen)
```
At this moment, `gen` is ready to be triggered from its `trigger` link. Note that the trigger link `gen.trigger` and the output `gen.output` of `gen` are writable. 
```@repl source_ex
gen.trigger
gen.output
```
`gen` is triggered by writing time `t` to its trigger link `gen.trigger`.
```@repl source_ex
put!(gen.trigger, 1.)
```
When triggered `gen` writes `true` to its handshake link `gen.handshake`. Note that `gen.handshake` is readable.
```@repl source_ex
gen.handshake
```
and to drive `gen` for another time `gen.handshake` must be read. 
```@repl source_ex
take!(gen.handshake)
```
Now continue driving `gen`.
```@repl source_ex
for t in 2. : 10.
    put!(gen.trigger, t)
    take!(gen.handshake)
end
```
When triggered, the output of `gen` is written to its output `gen.output`.
```@repl source_ex 
println(gen.output[1].buffer.data)
```

In addition to generic `FunctionGenerator`, `Jusdl` provides some other function generators which are documented in the following section.

## Full API 
```@docs 
SinewaveGenerator
DampedSinewaveGenerator
SquarewaveGenerator
TriangularwaveGenerator
ConstantGenerator
RampGenerator
StepGenerator
ExponentialGenerator
DampedExponentialGenerator
```