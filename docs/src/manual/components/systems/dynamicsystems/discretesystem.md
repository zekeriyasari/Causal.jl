# DiscreteSystem

## Construction of DiscreteSystem 
`DiscreteSystem`s evolve by the following discrete time difference equation.
```math 
    x_{k + 1} = f(x_k, u_k, k) \\
    y_k = g(x_k, u_k, k)
```
where ``x_k`` is the state, ``y_k`` is the value of `output` and ``u_k`` is the value of `input` at discrete time `t`. ``f`` is the state function and ``g`` is the output function of the system. See the main constructor.

```@docs 
DiscreteSystem
```

