# This file contains SDESystem prototypes

import DifferentialEquations: LambaEM, SDEProblem
import UUIDs: uuid4

"""
    @def_sde_system ex 

where `ex` is the expression to define to define a new AbstractSDESystem component type. The usage is as follows:
```julia
@def_sde_system mutable struct MySDESystem{T1,T2,T3,...,TN,OP,RH,RO,ST,IP,OP} <: AbstractSDESystem
    param1::T1 = param1_default                 # optional field 
    param2::T2 = param2_default                 # optional field 
    param3::T3 = param3_default                 # optional field
        ⋮
    paramN::TN = paramN_default                 # optional field 
    drift::DR = drift_function                  # mandatory field
    diffusion::DF = diffusion_function          # mandatory field
    readout::RO = readout_functtion             # mandatory field
    state::ST = state_default                   # mandatory field
    input::IP = input_default                   # mandatory field
    output::OP = output_default                 # mandatory field
end
```
Here, `MySDESystem` has `N` parameters. `MySDESystem` is represented by the `drift`, `diffusion` and `readout` function. `state`, `input` and `output` is the initial state, input port and output port of `MySDESystem`.

!!! warning 
    `drift` must have the signature 
    ```julia
    function drift((dx, x, u, t, args...; kwargs...)
        dx .= .... # update dx
    end
    ```
    and `diffusion` must have the signature 
    ```julia
    function diffusion((dx, x, u, t, args...; kwargs...)
        dx .= .... # update dx
    end
    ```
    and `readout` must have the signature 
    ```julia
    function readout(x, u, t)
        y = ...
        return y
    end
    ```

!!! warning 
    New SDE system must be a subtype of `AbstractSDESystem` to function properly.

# Example 
```julia 
julia> @def_sde_system mutable struct MySDESystem{DR, DF, RO, IP, OP} <: AbstractSDESystem
           η::Float64 = 1.
           drift::DR = (dx, x, u, t) -> (dx .= x)
           diffusion::DF = (dx, x, u, t, η=η) -> (dx .= η)
           readout::RO = (x, u, t) -> x 
           state::Vector{Float64} = rand(2) 
           input::IP = nothing 
           output::OP = Outport(2)
       end

julia> ds = MySDESystem();
```
"""
macro def_sde_system(ex) 
    checksyntax(ex, :AbstractSDESystem)
    appendcommonex!(ex)
    foreach(nex -> appendex!(ex, nex), [
        :( alg::$ALG_TYPE_SYMBOL = Causal.LambaEM{true}() ), 
        :( integrator::$INTEGRATOR_TYPE_SYMBOL = Causal.construct_integrator(Causal.SDEProblem, input, 
            (drift, diffusion), state, t, modelargs, solverargs; alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=3) ) 
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end


##### Define SDE system library

"""
    $TYPEDEF

Constructs a SDE system. 

# Fields 

    $TYPEDFIELDS
"""
@def_sde_system mutable struct SDESystem{DR, DF, RO, ST, IP, OP} <: AbstractSDESystem 
    "Drift function"
    drift::DR 
    "diffusion function"
    diffusion::DF 
    "Readout function"
    readout::RO 
    "State"
    state::ST 
    "Input. Expected to be an `Inport` or `Nothing`"
    input::IP 
    "Output port"
    output::OP 
end

"""
    $TYPEDEF

Constructs a noisy Lorenz system 

# Fields 

    $TYPEDFIELDS
"""
@def_sde_system mutable struct NoisyLorenzSystem{ET, DR, DF, RO, IP, OP} <: AbstractSDESystem
    "σ"
    σ::Float64 = 10.
    "β"
    β::Float64 = 8 / 3
    "ρ"
    ρ::Float64 = 28.
    "η"
    η::ET = 1.
    "γ"
    γ::Float64 = 1.
    "Drift function"
    drift::DR = function lorenzdrift(dx, x, u, t, σ=σ, β=β, ρ=ρ, γ=γ)
        dx[1] = σ * (x[2] - x[1])
        dx[2] = x[1] * (ρ - x[3]) - x[2]
        dx[3] = x[1] * x[2] - β * x[3]
        dx .*= γ
    end
    "Diffusion function"
    diffusion::DF = (dx, x, u, t, η=η) -> (dx .= η)
    "Readout function"
    readout::RO = (x, u, t) -> x
    "State"
    state::Vector{Float64} = rand(3)
    "Input. Expected to be an `Inport` or `Nothing`"
    input::IP = nothing 
    "Output port"
    output::OP = Outport(3) 
end  

"""
    $TYPEDEF

Constructs a noisy Lorenz system 

# Fields

    $TYPEDFIELDS
"""
@def_sde_system mutable struct ForcedNoisyLorenzSystem{ET, CM, DR, DF, RO, IP, OP} <: AbstractSDESystem
    "σ"
    σ::Float64 = 10.
    "β"
    β::Float64 = 8 / 3
    "ρ"
    ρ::Float64 = 28.
    "η"
    η::ET = 1.
    "Input coupling matrix. Expected to be a diagonal matrix."
    cplmat::CM = I(3)
    "γ"
    γ::Float64 = 1.
    "Drift function"
    drift::DR = function forcedlorenzdrift(dx, x, u, t, σ=σ, β=β, ρ=ρ, γ=γ, cplmat=cplmat)
        dx[1] = σ * (x[2] - x[1])
        dx[2] = x[1] * (ρ - x[3]) - x[2]
        dx[3] = x[1] * x[2] - β * x[3]
        dx .*= γ
        dx .+= cplmat * map(ui -> ui(t), u.itp)   # Couple inputs
    end
    "Diffusion function"
    diffusion::DF = (dx, x, u, t, η=η) -> (dx .= η)
    "Readout function"
    readout::RO = (x, u, t) -> x
    "State"
    state::Vector{Float64} = rand(3)
    "Input. Expected to be an `Inport` or `Nothing`"
    input::IP = Inport(3) 
    "Output port"
    output::OP = Outport(3) 
end  


##### Pretty printing 
show(io::IO, ds::SDESystem) = print(io, 
    "SDESystem(drift:$(ds.drift), diffusion:$(ds.diffusion), readout:$(ds.readout), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::NoisyLorenzSystem) = print(io, 
    "NoisyLorenzSystem(σ:$(ds.σ), β:$(ds.β), ρ:$(ds.ρ), η:$(ds.η), γ:$(ds.γ), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ForcedNoisyLorenzSystem) = print(io, 
    "ForcedNoisyLorenzSystem(σ:$(ds.σ), β:$(ds.β), ρ:$(ds.ρ), η:$(ds.η), γ:$(ds.γ), cplmat:$(ds.cplmat), ", 
    "state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")
