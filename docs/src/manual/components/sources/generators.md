# Generators

## FunctionGenerator
``FunctionGenerator` is the generic function generator. The output waveform is shaped by its *output function*. A `FunctionGenerator` can be construted by specifying its output function `outputfunc`.

```@docs 
FunctionGenerator
```

## Basic Operation AbstractSource
An`AbstractSource` is a subtype of `AbstractComponent`. (See [Components](@ref) for more information.) An `AbstractComponent` has `input` and `output` for data flow. The `AbstractComponent` reads data from `input` and writes data to `output`. Since the input-output relation of `AbstractSource` depends on just the current time `t`, `Source`s does not have `input`s since they do not read input values. They just need time `t` to compute its output. During their evolution, the `AbstractComponent` read time `t` from their `trigger` links, computes their output according to their output function and writes its computed output to their `output` busses. An `AbstractComponent` also writes `true` to their `handshake` links in signal that the evolution is succeeded. To further clarify the operation of `AbstractSource`, let us do some examples. 

```@repl source_ex
using Jusdl # hide 
outputfunc(t) = t * exp(t) + sin(t)
gen = FunctionGenerator(outputfunc)
```
We constructed a [`FunctionGenerator`](@ref) which is an `AbstractSource`.
```@repl source_ex
gen isa AbstractSource
```

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