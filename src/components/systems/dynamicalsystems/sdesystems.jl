# This file contains SDESystem prototypes


@doc raw"""
    SDESystem(input, output, statefunc, outputfunc, state, t, modelargs=(), solverargs=(); 
        alg=SDEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `SDESystem` with `input` and `output`. `statefunc` is the state function and `outputfunc` is the output function of `SDESystem`. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

The `SDESystem` is represented by the state equation
```math 
    \begin{array}{l}
        dx = f(x, u, t) dt + h(x, u, t)dW \\
        y = g(x, u, t)
    \end{array}
```
where ``f`` is the drift equation and ``h`` is the diffusion equation.  The `statefunc` is the tuple of drift function ``f`` and diffusion function ``h`` i.e. `statefunc = (f, h)`. ``g`` is `outputfunc`. ``t`` is the time `t`, ``x`` is the `state`, ``u`` is the value of `input` and ``y`` is the value of the `output`. ``W`` is the Wiever process. `noise` is the noise of the system and `solver` is used to solve the above differential equation. 

The syntax of the drift and diffusion function of `statefunc` must be of the form
```julia
function f(dx, x, u, t)
    dx .= ... # Update dx
end
function h(dx, x, u, t)
    dx .= ... # Update dx.
end
```
and the syntax of `outputfunc` must be of the form 
```julia
function outputfunc(x, u, t)
    y = ... # Compute y 
    return y
end
```

# Example 
```julia
julia> sfuncdrift(dx, x, u, t) = (dx[1] = -x[1]);

julia> sfuncdiffusion(dx, x, u, t) = (dx[1] = -x[1]);

julia> ofuncsde(x, u, t) = x;

julia> SDESystem((sfuncdrift,sfuncdiffusion), ofuncsde, [1.], 0., nothing, Outport())
SDESystem(state:[1.0], t:0.0, input:nothing, output:Outport(numpins:1, eltype:Outpin{Float64}))
```

!!! info 
    See [DifferentialEquations](https://docs.juliadiffeq.org/) for more information about `modelargs`, `modelkwargs`, `solverargs` `solverkwargs` and `alg`.
"""
mutable struct SDESystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractSDESystem
    @generic_dynamic_system_fields
    function SDESystem(statefunc, outputfunc, state, t, input, output, modelargs=(), solverargs=(); 
        alg=SDEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, callbacks=nothing, 
        name=Symbol())
        trigger, handshake, integrator = init_dynamic_system(
                SDEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4())
    end
end

show(io::IO, ds::SDESystem) = print(io, 
    "SDESystem(state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")

