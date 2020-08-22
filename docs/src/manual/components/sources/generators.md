# Generators

## Basic Operation AbstractSource
An `AbstractSource` is a subtype of `AbstractComponent`. (See [Components](@ref) for more information.) An `AbstractComponent` has `input` port and `output` port for data flow. The `AbstractComponent` reads data from the `input` port and writes data to `output` port. Since the input-output relation of `AbstractSource` depends on just the current time `t`, `Source`s do not have `input` ports since they do not read input values. They just need time `t` to compute its output. During their evolution, an `AbstractComponent` reads time `t` from its `trigger` pins, computes its output according to its output function and writes its computed output to its `output` ports. An `AbstractComponent` also writes `true` to their `handshake` pin to signal that the evolution is succeeded. To further clarify the operation of `AbstractSource`, let us do some examples. 

```@repl source_ex
using Causal # hide 
f(t) = t * exp(t) + sin(t)
gen = FunctionGenerator(readout=f)
```
We constructed a [`FunctionGenerator`](@ref) which is an `AbstractSource`.
```@repl source_ex
gen isa AbstractSource
```
To drive `gen`, that is to make `gen` evolve, we need to launch `gen`.  To this end, we construct ports and pins for input-output and signaling.
```@repl source_ex
trg, hnd, iport = Outpin(), Inpin{Bool}(), Inport(length(gen.output))
connect!(gen.output, iport)
connect!(trg, gen.trigger) 
connect!(gen.handshake, hnd)
t = launch(gen)
tout = @async while true 
    all(take!(iport) .=== NaN) && break 
    end
```
At this moment, `gen` is ready to be triggered from its `trigger` link. Note that the trigger link `gen.trigger` and the output `gen.output` of `gen` are writable. 
```@repl source_ex
gen.trigger.link
gen.output[1].links[1]
```
`gen` is triggered by writing time `t` to `trg`
```@repl source_ex
put!(trg, 1.)
```
When triggered `gen` writes `true` to its handshake link `gen.handshake` which can be read from `hnd`.
```@repl source_ex
hnd.link
```
and to drive `gen` for another time `hnd` must be read. 
```@repl source_ex
take!(hnd)
```
Now continue driving `gen`.
```@repl source_ex
for t in 2. : 10.
    put!(trg, t)
    take!(hnd)
end
```
When triggered, the output of `gen` is written to its output `gen.output`.
```@repl source_ex 
gen.output[1].links[1].buffer
```

`Causal` provides some other function generators which are documented in the following section.

## Full API 
```@docs
@def_source 
FunctionGenerator
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