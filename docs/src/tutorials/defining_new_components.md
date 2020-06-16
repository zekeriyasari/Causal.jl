# Defining New Component Types

Jusdl provides a library that includes some well-known components that are ready to be used. For example,

* [`FunctionGenerator`](@ref), [`SinewaveGenerator`](@ref), [`SquarewaveGenerator`](@ref), [`RampGenerator`](@ref), etc. as sources
* [`StaticSystem`](@ref), [`Adder`](@ref), [`Multiplier`](@ref), [`Gain`](@ref), etc. as static systems
* [`DiscreteSystem`](@ref), [`DiscreteLinearSystem`](@ref), [`HenonSystem`](@ref), [`LogisticSystem`](@ref), etc. as dynamical systems represented by discrete difference equations.
* [`ODESystem`](@ref), [`LorenzSystem`](@ref), [`ChenSystem`](@ref), [`ChuaSystem`](@ref), etc. as dynamical systems represented by ODEs.
* [`DAESystem`](@ref), [`RobertsonSystem`](@ref), etc. as dynamical systems represented by dynamical systems represented by DAEs.
* [`RODESystem`](@ref), [`MultiplicativeNoiseLinearSystem`](@ref), etc. as dynamical systems represented by dynamical systems represented by RODEs.
* [`SDESystem`](@ref), [`NoisyLorenzSystem`](@ref), [`ForcedNoisyLorenzSystem`](@ref), etc. as dynamical systems represented by dynamical systems represented by SDEs.
* [`DDESystem`](@ref), [`DelayFeedbackSystem`](@ref), etc. as dynamical systems represented by dynamical systems represented by DDEs.
* [`Writer`](@ref), [`Printer`](@ref), [`Scope`](@ref), etc. as sinks.

It is very natural that this library may lack some of the components that are wanted to be used by the user. In such a case, Jusdl provides the users with the flexibility to enrich this library. The users can define their new component types, including source, static system, dynamical system, sink and use them with ease. 

## Defining A New Source
New source types are defines using [`@def_source`](@ref) macro. Before embarking on defining new source, let us get the necessary information on how to use `@def_source`. This can be can be obtained through its docstrings. 
```@repl defining_new_components_ex
using Jusdl # hide 
@doc @def_source
```
From the docstring, its clear that new types of source can be defined as if we define a new Julia type. The difference is that the `struct` keyword is preceded by `@def_source` macro and the new component must be a subtype of [`AbstractSource`](@ref). Also from the docstring is that the new type has some optional and mandatory fields. 

!!! warning 
    To define a new source, mandatory fields must be defined. The optional fields are the parameters of the source.


For example let us define a new source that generates waveforms of the form. 
```math
    y(t) = 
    \begin{bmatrix}
        \alpha sin(t) \\ 
        \beta cos(t)
    \end{bmatrix}
```
Here ``\alpha`` and ``beta`` is the system parameters. That is, while defining the new source component, ``\alpha`` and ``\beta`` are optional fields. `readout` and ``output`` are the mandatory field while defining a source. Note from above equation that the output of the new source has two pins. Thus, this new source component type, say `MySource` is defined as follows. 
```@repl defining_new_components_ex
@def_source struct MySource{RO, OP} <: AbstractSource 
    α::Float64 = 1. 
    β::Float64 = 2. 
    readout::RO = (t, α=α, β=β) ->  [α*sin(t), β*cos(t)]
    output::OP = Outport(2)
end
```
Note that the syntax is very similar to the case in which we define a normal Julia type. We start with `struct` keyword preceded with `@def_source` macro. In order for the `MySource` to work flawlessly, i.e. to be used a model component, it must a subtype of `AbstractSource`. The `readout` function of `MySource` is a function of `t` and the remaining parameters, i.e., ``\alpha`` and ``\beta``, are passed into as optional arguments to avoid global variables. 

One other important point to note is that the `MySource` has additional fields that are required for it to work as a regular model component. Let us print all the field names of `MySource`, 
```@repl defining_new_components_ex
fieldnames(MySource)
```
We know that we defined the fields `α, β, readout, output`, but, the fields `trigger, callback, handshake, callbacks, name, id` are defined automatically by `@def_source` macro. 

Since the type `MySource` has been defined, any instance of it can be constructed. Let us see the constructors first.
```@repl defining_new_components_ex
methods(MySource)
```
The constructor with the keyword arguments is very much easy to uses. 
```@repl defining_new_components_ex
gen1 = MySource()
gen2 = MySource(α=4.)
gen3 = MySource(α=4., β=5.)
gen3 = MySource(α=4., β=5., name=:mygen)
gen3.trigger 
gen3.id 
gen3.α
gen3.β
gen3.output
```
An instance works flawlessly as a model component, that is, it can be driven from its `trigger` pin and signalling cane be carried out from its `handshake` pin. To see this, let us construct required pins and ports to drive a `MySource` instance. 
```@repl defining_new_components_ex
gen = MySource()                # `MySource` instance 
trg = Outpin()                  # To trigger `gen`
hnd = Inpin{Bool}()             # To signalling with `gen`
iport = Inport(2)               # To take values out of `gen` 
connect!(trg, gen.trigger); 
connect!(gen.handshake, hnd);
connect!(gen.output, iport);
launch(gen)                 # Launch `gen,
```
Now `gen` can be driven through `trg` pin. 
```@repl defining_new_components_ex
put!(trg, 1.)       # Drive `gen` for `t=1`.
take!(iport)        # Read output of `gen` from `iport`
take!(hnd)          # Approve `gen` has taken a step.
```
Thus, by using `@def_source` macro, it is possible for the users to define any type of sources under `AbstractSource` type and user them without a hassle. 

The procedure is again the same for any other component types. The table below lists the macros that are used to define new component types. 

| Macro                     | Component Type                | Supertype                     | Mandatory Field Names |
| -----------               | -----------                   | ----------------------------- | -------------------- |
| [`@def_source`](@ref)     | Source                        |[`AbstractSource`](@ref)       | `readout`, `output`  |
| [`@def_static_system`](@ref)     | StaticSystem           |[`AbstractStaticSystem`](@ref) |`readout`, `output`, `input`  |
| [`@def_discrete_system`](@ref)     | Discrete Dynamic System        |[`AbstractDiscreteSystem`](@ref) |`righthandside`, `readout`, `state`, `input`, `output`  |
| [`@def_ode_system`](@ref)     | ODE Dynamic System        |[`AbstractODESystem`](@ref) | `righthandside`, `readout`, `state`, `input`, `output`  |
| [`@def_dae_system`](@ref)     | DAE Dynamic System        |[`AbstractDAESystem`](@ref) | `righthandside`, `readout`, `state`, `stateder`, `diffvars`, `input`, `output`  |
| [`@def_rode_system`](@ref)     | RODE Dynamic System      |[`AbstractRODESystem`](@ref) | `righthandside`, `readout`, `state`, `input`, `output`  |
| [`@def_sde_system`](@ref)     | SDE Dynamic System        |[`AbstractSDESystem`](@ref) | `drift`, `diffusion`, `readout`, `state`, `input`, `output`  |
| [`@def_dde_system`](@ref)     | DDE Dynamic System        |[`AbstractDDESystem`](@ref) | `constlags`, `depslags`, `righthandside`,  `history`, `readout`, `state`, `input`, `output`  |
| [`@def_sink`](@ref)     | Sink        |[`AbstractSink`](@ref) | `action` |


The steps followed in the previous section are the same to define other component types: start with suitable macro given above, make the newly-defined type a subtype of the corresponding supertype, define the optional fields (if exist) ands define the mandatory fields of the new type (with the default values if necessary).

## Defining New StaticSystem 
Consider the following readout function of the static system to be defined 
```math 
y = u_1 t + a cos(u_2)
```
where ``u = [u_1, u_2]`` is the input, ``y`` is the output of the system and ``t`` is time. The system has two inputs and one output. This system can be defined as follows. 
```@repl defining_new_components_ex
@def_static_system struct MyStaticSystem{RO, IP, OP} <: AbstractStaticSystem
    a::Float64 = 1.
    readout::RO = (t, a = a) -> u[1] * t + a * cos(u[2])
    input::IP = Inport(2)
    output::OP = Outport(1) 
end
```

## Defining New Discrete Dynamical System
The discrete dynamical system given by 
```math
\begin{array}{l}
x_{k + 1} = α x_k + u_k \\[0.25cm]
y_k = x_k
\end{array}
```
can be defined as, 
```@repl defining_new_components_ex
@def_discrete_system struct MyDiscreteSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem 
    α::Float64 = 1. 
    β::Float64 = 2. 
    righthandside::RH = (dx, x, u, t, α=α) -> (dx[1] = α * x[1] + u[1](t))
    readout::RO = (x, u, t) -> x
    input::IP = Inport(1) 
    output::OP = Outport(1) 
end
```

## Defining New ODE Dynamical System
The ODE dynamical system given by 
```math
\begin{array}{l}
\dot{x} = α x + u \\[0.25cm]
y = x
\end{array}
```
can be defined as, 
```@repl defining_new_components_ex
@def_ode_system struct MyODESystem{RH, RO, IP, OP} <: AbstractDiscreteSystem 
    α::Float64 = 1. 
    β::Float64 = 2. 
    righthandside::RH = (dx, x, u, t, α=α) -> (dx[1] = α * x[1] + u[1](t))
    readout::RO = (x, u, t) -> x
    input::IP = Inport(1) 
    output::OP = Outport(1) 
end
```

## Defining New DAE Dynamical System
The DAE dynamical system given by 
```math
\begin{array}
dx = x + 1 \\[0.25cm]
0 = 2(x + 1) + 2
\end{array}
```
can be defined as, 
```@repl defining_new_components_ex
@def_dae_system mutable struct MyDAESystem{RH, RO, ST, IP, OP} <: AbstractDAESystem
    righthandside::RH = function sfuncdae(out, dx, x, u, t)
            out[1] = x[1] + 1 - dx[1]
            out[2] = (x[1] + 1) * x[2] + 2
        end 
    readout::RO = (x,u,t) -> x 
    state::ST = [1., -1]
    stateder::ST = [2., 0]
    diffvars::Vector{Bool} = [true, false]
    input::IP = nothing 
    output::OP = Outport(1)
end
```

## Defining RODE Dynamical System 
The RODE dynamical system given by 
```math
\begin{array}{l}
\dot{x} = A x W \\[0.25cm]
y = x 
\end{array}
```
where 
```math 
A = \begin{bmatrix}
    2 & 0 \\ 
    0 & -2
\end{bmatrix}
```
can be defined as, 
```@repl defining_new_components_ex
@def_rode_system struct MyRODESystem{RH, RO, IP, OP} <: AbstractRODESystem
    A::Matrix{Float64} = [2. 0.; 0 -2]
    righthandside::RH = (dx, x, u, t, W) -> (dx .= A * x * W)
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(2) 
    input::IP = nothing 
    output::OP = Outport(2)
end
```

## Defining SDE Dynamical System 
The RODE dynamical system given by 
```math
\begin{array}{l}
dx = -x dt + dW \\[0.25cm]
y = x 
\end{array}
```
can be defined as,
```@repl defining_new_components_ex
@def_sde_system mutable struct MySDESystem{DR, DF, RO, ST, IP, OP} <: AbstractSDESystem
    drift::DR = (dx, x, u, t) -> (dx .= -x)
    diffusion::DF = (dx, x, u, t) -> (dx .= 1)
    readout::RO = (x, u, t) -> x 
    state::ST = [1.] 
    input::IP = nothing
    output::OP = Outport(1)
end 
```

## Defining DDE Dynamical System 
The DDE dynamical system given by 
```math 
    \begin{array}{l}
    \dot{x} = -x(t - \tau) \quad t \geq 0 \\
    x(t) = 1. -\tau \leq t \leq 0 \\
    \end{array}
```
can be defined as,
```@repl defining_new_components_ex
_delay_feedback_system_cache = zeros(1)
_delay_feedback_system_tau = 1.
_delay_feedback_system_constlags = [1.]
_delay_feedback_system_history(cache, u, t) = (cache .= 1.)
function _delay_feedback_system_rhs(dx, x, h, u, t, 
    cache=_delay_feedback_system_cache, τ=_delay_feedback_system_tau)
    h(cache, u, t - τ)  # Update cache 
    dx[1] = cache[1] + x[1]
end
@def_dde_system mutable struct DelayFeedbackSystem{RH, HST, RO, IP, OP} <: AbstractDDESystem
    constlags::Vector{Float64} = _delay_feedback_system_constlags
    depslags::Nothing = nothing
    righthandside::RH = _delay_feedback_system_rhs
    history::HST = _delay_feedback_system_history
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(1)
    input::IP = nothing 
    output::OP = Outport(1)
end
```

## Defining Sinks 
Say we want a sink type that takes the data flowing through the connections of the model and prints it. This new sink type cane be defined as follows. 
```@repl defining_new_components_ex
@def_sink struct MySink{A} <: AbstractSink
    action::A = actionfunc
end
actionfunc(sink::MySink, t, u) = println(t, u)
```
