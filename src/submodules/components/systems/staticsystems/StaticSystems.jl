"""
Includes static system components such as adder, multiplier, gain, etc.

# Imports 

    $(IMPORTS) 

# Exports 

    $(EXPORTS)
"""
module StaticSystems 

using DocStringExtensions
using UUIDs, LinearAlgebra, Interpolations
using Causal.Connections 
using Causal.Utilities
using Causal.Components.ComponentsBase
import Base: show 
import UUIDs.uuid4
import Causal.Components: readout

export @def_static_system
export StaticSystem, Adder, Multiplier, Gain, Terminator, Memory, Coupler, Differentiator

"""
    @def_static_system ex 

where `ex` is the expression to define to define a new AbstractStaticSystem component type. The usage is as follows:
```julia
@def_source struct MyStaticSystem{T1,T2,T3,...,TN,OP, RO} <: AbstractStaticSystem
    param1::T1 = param1_default     # optional field 
    param2::T2 = param2_default     # optional field 
    param3::T3 = param3_default     # optional field
        ⋮
    paramN::TN = paramN_default     # optional field 
    input::IP = input_default       # mandatory field
    output::OP = output_default     # mandatory field 
    readout::RO = readout_function  # mandatory field
end
```
Here, `MyStaticSystem` has `N` parameters, an `output` port, an `input` port and a `readout` function.

!!! warning 
    `input`, `output` and `readout` are mandatory fields to define a new static system. The rest of the fields are the parameters of the system.

!!! warning 
    `readout` must be a two-argument function, i.e. a function of time `t` and input value `u`.

!!! warning 
    New static system must be a subtype of `AbstractStaticSystem` to function properly.

# Example 
```julia 
julia> @def_static_system struct MyStaticSystem{IP, OP, RO} <: AbstractStaticSystem 
       α::Float64 = 1. 
       β::Float64 = 2. 
       input::IP = Inport() 
       output::OP = Outport() 
       readout::RO = (t,u) -> α * u[1] + β * u[2]
       end

julia> sys = MyStaticSystem(); 

julia> sys.α
1.0

julia> sys.input
1-element Inport{Inpin{Float64}}:
 Inpin(eltype:Float64, isbound:false)
```
"""
macro def_static_system(ex) 
    ex.args[2].head == :(<:) && ex.args[2].args[2] in [:AbstractStaticSystem, :AbstractMemory] || 
        error("Invalid usage. The type should be a subtype of AbstractStaticSystem or AbstractMemory.\n$ex")
    foreach(nex -> ComponentsBase.appendex!(ex, nex), [
        :( trigger::$TRIGGER_TYPE_SYMBOL = Inpin() ),
        :( handshake::$HANDSHAKE_TYPE_SYMBOL = Outpin{Bool}() ),
        :( callbacks::$CALLBACKS_TYPE_SYMBOL = nothing ),
        :( name::Symbol = Symbol() ),
        :( id::$ID_TYPE_SYMBOL = StaticSystems.uuid4() )
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end

##### Define prototipical static systems.

# """
#     $(TYPEDEF)

# Generic static system with `readout` function, `input` port and `output` port.

# # Fields 

#     $(TYPEDFIELDS)

# # Example 
# ```julia 
# julia> ss = StaticSystem(readout = (t,u) -> u[1] + u[2], input=Inport(2), output=Outport(1));

# julia> ss.readout(0., ones(2))
# 2.0
# ```
# """
# @def_static_system struct StaticSystem{RO, IP, OP} <: AbstractStaticSystem
#     readout::RO 
#     input::IP 
#     output::OP
# end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

An`Adder` with input bus `input` and signs `signs`. `signs` is a tuplle of `+` and/or `-`. The output function `g` of `Adder` is of the form,
```math 
    y = g(u, t) =  \\sum_{j = 1}^n s_k u_k
```
where `n` is the length of the `input`, ``s_k`` is the `k`th element of `signs`, ``u_k`` is the `k`th value of `input` and ``y`` is the value of `output`. The default value of `signs` is all `+`.

# Example 
```julia
julia> adder = Adder(signs=(+, +, -));

julia> adder.readout([3, 4, 5], 0.) == 3 + 4 - 5
true
```
"""
@def_static_system mutable struct Adder{S, IP, OP} <: AbstractStaticSystem 
    signs::S = (+, +)
    input::IP = Inport(length(signs))
<<<<<<< HEAD
    output::OP = Outport()
=======
    output::OP = Outport{datatype(input)}()
    readout::RO = (u, t, signs=signs) -> sum([sign(val) for (sign, val) in zip(signs, u)])
>>>>>>> modular
end
readout(ss::Adder, u, t) = sum([sign(val) for (sign, val) in zip(ss.signs, u)])


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

A `Multiplier` with input bus `input` and signs `signs`. `signs` is a tuplle of `*` and/or `/`. The output function `g` of `Multiplier` is of the form,
```math 
    y = g(u, t) =  \\prod_{j = 1}^n s_k u_k
```
where `n` is the length of the `input`, ``s_k`` is the `k`th element of `signs`, ``u_k`` is the `k`th value of `input` and ``y`` is the value of the `output`. The default value of `signs` is all `*`.

# Example 
```julia
julia> mlt = Multiplier(ops=(*, *, /));

julia> mlt.readout([3, 4, 5], 0.) == 3 * 4 / 5
true
```
"""
@def_static_system mutable struct Multiplier{S, IP, OP} <: AbstractStaticSystem
    ops::S = (*,*)
    input::IP = Inport(length(ops))
<<<<<<< HEAD
    output::OP = Outport()
end
function readout(ss::Multiplier, u, t) 
    ops = ss.ops
    val = 1
    for i = 1 : length(ops)
        val = ops[i](val, u[i])
=======
    output::OP = Outport{datatype(input)}()
    readout::RO = (u, t, ops=ops) -> begin 
        ops = ops
        val = 1
        for i = 1 : length(ops)
            val = ops[i](val, u[i])
        end
        val
>>>>>>> modular
    end
    val
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

A `Gain` whose output function `g` is of the form 
```math 
    y = g(u, t) =  K u
```
where ``K`` is `gain`, ``u`` is the value of `input` and `y` is the value of `output`.

# Example 
```julia
julia> K = [1. 2.; 3. 4.];

julia> sfunc = Gain(input=Inport(2), gain=K);

julia> sfunc.readout([1., 2.], 0.) == K * [1., 2.]
true
```
"""
@def_static_system mutable struct Gain{G, IP, OP} <: AbstractStaticSystem
    gain::G = 1.
    input::IP = Inport() 
<<<<<<< HEAD
    output::OP = Outport(length(gain * zeros(length(input)))) 
=======
    output::OP = Outport{datatype(input)}(length(gain * zeros(length(input)))) 
    readout::RO = (u, t, gain=gain) -> gain * u
>>>>>>> modular
end
readout(ss::Gain, u, t) = ss.gain * u


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`Terminator` with input bus `input`. The output function `g` is eqaul to `nothing`. A `Terminator` is used just to sink the incomming data flowing from its `input`.
"""
@def_static_system struct Terminator{IP, OP} <: AbstractStaticSystem
    input::IP = Inport() 
    output::OP = nothing
end 
readout(ss::Terminator, u, t) = nothing


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

A 'Memory` with input bus `input`. A 'Memory` delays the values of `input` by an amount of `numdelay`. 
`initial` determines the transient output from the `Memory`, that is, until the internal buffer of `Memory` is full, 
the values from `initial` is returned.

# Example
```julia
julia> Memory(delay=0.1)
Memory(delay:0.1, numtaps:5, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))

julia> Memory(delay=0.1, numtaps=5)
Memory(delay:0.1, numtaps:5, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))
```
"""
@def_static_system mutable struct Memory{D, IN, TB, DB, IP, OP} <: AbstractMemory
    delay::D = 1.
    initial::IN = 0.
    numtaps::Int = 5
    timebuf::TB = Buffer(numtaps)
    databuf::DB = Buffer(typeof(initial), numtaps)
    input::IP = Inport{typeof(initial)}()
    output::OP = Outport{typeof(initial)}()
end 
function readout(mem::Memory, u, t) 
    if t <= mem.delay
        return mem.initial
    else
        tt = content(mem.timebuf, flip=false)
        uu = content(mem.databuf, flip=false)
        if length(tt) == 1
            return uu[1]
        end
        if eltype(uu) <: AbstractVector
            itp = map(row -> CubicSplineInterpolation(range(tt[end], tt[1], length=length(tt)), reverse(row), extrapolation_bc=Line()), eachrow(hcat(uu...)))
            return map(f -> f(t - delay), itp)
        else
            itp = CubicSplineInterpolation(range(tt[end], tt[1], length=length(tt)), reverse(uu), extrapolation_bc=Line())
            return itp(t - delay)
        end
    end
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

 Coupler from connection matrix `conmat` of size ``n \times n`` and coupling matrix `cplmat` of size ``d \times d``. The output function `g` of `Coupler` is of the form 
```math 
    y = g(u, t) = (E \\otimes P) u
```
where ``\\otimes`` is the Kronecker product, ``E`` is `conmat` and ``P`` is `cplmat`, ``u`` is the value of `input` and `y` is the value of `output`.
"""
@def_static_system mutable struct Coupler{C1, C2, IP, OP} <: AbstractStaticSystem
    conmat::C1 = [-1. 1; 1. 1.]
    cplmat::C2 = [1 0 0; 0 0 0; 0 0 0]
    input::IP = Inport(size(conmat, 1) * size(cplmat, 1))
    output::OP = Outport(size(conmat, 1) * size(cplmat, 1))
end
function readout(ss::Coupler, u, t)
    typeof(ss.conmat) <: AbstractMatrix{<:Real} ? 
        kron(ss.conmat, ss.cplmat) * u  : 
        kron(map(f -> f(t), ss.conmat), ss.cplmat) * u 
end 

"""
        $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

Consructs a `Differentiator` whose input output relation is of the form 
```math 
    y(t) = k_d \\dot{u}(t)
```
where ``u(t)`` is the input and ``y(t)`` is the output and ``k_d`` is the differentiation constant.
"""
@def_static_system mutable struct Differentiator{IP, OP} <: AbstractStaticSystem 
    kd::Float64 = 1. 
    t::Float64 = 0.
    u::Float64 = 0.
    input::IP = Inport()
    output::OP = Outport()
end
function readout(ss::Differentiator, u, t)
    out = t ≤ ss.t ? ss.u : (u - ss.u) / (t - ss.t)
    ss.t = t
    ss.u = u
    kd * out 
end

##### Pretty-printing
# show(io::IO, ss::StaticSystem) = print(io,"StaticSystem(readout:$(ss.readout), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Adder) = print(io, "Adder(signs:$(ss.signs), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Multiplier) = print(io, "Multiplier(ops:$(ss.ops), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Gain) = print(io, "Gain(gain:$(ss.gain), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Terminator) = print(io, "Terminator(input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Memory) = 
    print(io, "Memory(delay:$(ss.delay), numtaps:$(length(ss.timebuf)), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Coupler) = print(io, "Coupler(conmat:$(ss.conmat), cplmat:$(ss.cplmat))")
show(io::IO, ss::Differentiator) = print(io, "Differentiator(kd:$(ss.kd))")

end # module 