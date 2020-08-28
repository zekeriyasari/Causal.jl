# Evolution of Components
In Causal, the simulation of a model is performed by individual evolution of components (see [Modeling](@ref) and [Simulation](@ref section) for more information of modeling and simulation adopted in Causal). Basically, when triggered through its `trigger` pin, based on its type, a component takes a forward step as follows, 
1. The next clock time `t` is read from its `trigger` pin.
2. The next input value `u(t)` is read from from its `input` port, 
3. The component evolves from its current time `t - dt` to the current clock time `t`
4. Using the state variable `x(t)` at time `t`, current clock time `t` and `u(t)`, the next output value `y(t)` is computed. 
5. The component writes `true` to its `handshake` pin to signal that taking step is performed with success.
or a backward step as follows. 
1. The next clock time `t` is read from its `trigger` pin.
2. Using the state variable `x(t - dt)` at time `t - dt`, current component time `t - dt` and `u(t - dt)`, the next output value `y(t)` is computed. 
3. The next input value `u(t)` is read from from its `input` port, 
4. The component evolves from its current time `t - dt` to the current clock time `t`
5. The component writes `true` to its `handshake` pin to signal that taking step is performed with success.
Here `dt` is the simulation step size. 

## Reading Time 
```@docs 
readtime!
```

## Reading State 
```@docs 
readstate
```

## Reading Input
```@docs 
readinput!
```

## Writing Output
```@docs 
writeoutput!
```

## Computing Output 
```@docs 
computeoutput 
```

## Evolve
```@docs 
evolve!
```

## Taking Steps 
```@docs 
takestep!
forwardstep
backwardstep
launch(comp::AbstractComponent)
launch(comp::AbstractSubSystem)
drive!
approve!
terminate!
```

