# This file contains the static systems of Jusdl.


macro defss(ex) 
    nex = ex.head == :macrocall ? ex.args[end] : ex 
    defss(nex) |> esc
end

function defss(ex) 
    head = ex.head
    ismutable, name, args = ex.args
    if ismutable
        if name isa Symbol 
            return quote 
                Base.@kwdef mutable struct $name{TR, HS, CB} <: AbstractSource
                    $args
                    @genericfields
                end 
            end
        else 
            return quote 
                Base.@kwdef mutable struct $(name.args[1]){$(name.args[2:end]...), TR, HS, CB} <: AbstractSource
                    $args
                    @genericfields
                end 
            end
        end
    else 
        if name isa Symbol
            return quote 
                Base.@kwdef struct $name{TR, HS, CB} <: AbstractSource
                    $args
                    @genericfields
                end 
            end
        else
            return quote 
                Base.@kwdef struct $(name.args[1]){$(name.args[2:end]...), TR, HS, CB} <: AbstractSource
                    $args
                    @genericfields
                end 
            end
        end
    end 
end


##### Define prototipical static systems.

@doc raw"""
    Adder(signs=(+,+))

Construts an `Adder` with input bus `input` and signs `signs`. `signs` is a tuplle of `+` and/or `-`. The output function `g` of `Adder` is of the form,
```math 
    y = g(u, t) =  \sum_{j = 1}^n s_k u_k
```
where `n` is the length of the `input`, ``s_k`` is the `k`th element of `signs`, ``u_k`` is the `k`th value of `input` and ``y`` is the value of `output`. The default value of `signs` is all `+`.

# Example 
```jldoctest
julia> adder = Adder((+, +, -));

julia> adder.readout([3, 4, 5], 0.) == 3 + 4 - 5
true
```
"""
@defss Base.@kwdef struct Adder{S, IP, OP}
    signs::S = (+, +)
    input::IP = Inport(length(signs))
    output::OP = Outport()
end

function readout(ss::Adder, u, t)
    sum([sign(val) for (sign, val) in zip(ss.signs, u)])
end 

@doc raw"""
    Multiplier(ops=(*,*))

Construts an `Multiplier` with input bus `input` and signs `signs`. `signs` is a tuplle of `*` and/or `/`. The output function `g` of `Multiplier` is of the form,
```math 
    y = g(u, t) =  \prod_{j = 1}^n s_k u_k
```
where `n` is the length of the `input`, ``s_k`` is the `k`th element of `signs`, ``u_k`` is the `k`th value of `input` and ``y`` is the value of the `output`. The default value of `signs` is all `*`.

# Example 
```jldoctest
julia> mlt = Multiplier((*, *, /));

julia> mlt.readout([3, 4, 5], 0.) == 3 * 4 / 5
true
```
"""
@defss Base.@kwdef struct Multiplier{S, IP, OP}
    ops::S=(*,*)
    input::IP = Inport(length(ops))
    output::OP = Outport()
end

function readout(ss::Multiplier, u, t)
    ops = ss.ops
    val = 1
    for i = 1 : length(ops)
        val = ops[i](val, u[i])
    end
    val
end



@doc raw"""
    Gain(input; gain=1.)

Constructs a `Gain` whose output function `g` is of the form 
```math 
    y = g(u, t) =  K u
```
where ``K`` is `gain`, ``u`` is the value of `input` and `y` is the value of `output`.

# Example 
```jldoctest
julia> K = [1. 2.; 3. 4.];

julia> sfunc = Gain(Inport(2), gain=K);

julia> sfunc.readout([1., 2.], 0.) == K * [1., 2.]
true
```
"""
@defss Base.@kwdef struct Gain{G, IP, OP} 
    gain::G = 1.
    input::IP = Inport() 
    output::OP = Outport(length(gain * zeros(length(input)))) 
end

function readout(ss::Gain, u, t) 
    ss.gain * u
end 


@doc raw"""
    Terminator(input::Inport)

Constructs a `Terminator` with input bus `input`. The output function `g` is eqaul to `nothing`. A `Terminator` is used just to sink the incomming data flowing from its `input`.
"""
@defss Base.@kwdef struct Terminator{IP, OP}
    input::IP = Inport() 
    output::OP = nothing
end 


"""
    Memory(delay=1.; initial::AbstractVector{T}=zeros(1), numtaps::Int=5, t0=0., dt=0.01, callbacks=nothing, 
        name=Symbol()) where T 

Constructs a 'Memory` with input bus `input`. A 'Memory` delays the values of `input` by an amount of `numdelay`. 
`initial` determines the transient output from the `Memory`, that is, until the internal buffer of `Memory` is full, 
the values from `initial` is returned.

# Example
```jldoctest
julia> Memory(0.1)
Memory(delay:0.1, numtaps:5, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))

julia> Memory(0.1; numtaps=5)
Memory(delay:0.1, numtaps:5, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))

julia> Memory(0.1; numtaps=5, dt=1.)
Memory(delay:0.1, numtaps:5, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))
```
"""
@defss Base.@kwdef struct Memory{D, IN, TB, DB, IP, OP} 
    delay::D = 1.
    initial::IN = zeros(1)
    numtaps::Int = 5
    timebuf::TB = Buffer(numtaps)
    databuf::DB = length(initial) == 1 ? Buffer(numtaps) : Buffer(length(initial), numtaps)
    input::IP = Inport(length(initial))
    output::OP = Outport(length(initial))
end 

function readout(ss::Memory, u, t)
    if t <= ss.delay
        return ss.initial
    else
        tt = content(ss.timebuf, flip=false)
        uu = content(ss.databuf, flip=false)
        if length(tt) == 1
            return uu[1]
        end
        if ndims(ss.databuf) == 1
            itp = CubicSplineInterpolation(range(tt[end], tt[1], length=length(tt)), reverse(uu), extrapolation_bc=Line())
            return itp(t - ss.delay)
        else
            itp = map(row -> CubicSplineInterpolation(range(tt[end], tt[1], length=length(tt)), reverse(row), extrapolation_bc=Line()), eachrow(uu))
            return map(f -> f(t - ss.delay), itp)
        end
    end
end

@doc raw"""
    Coupler(conmat::AbstractMatrix, cplmat::AbstractMatrix)

Constructs a coupler from connection matrix `conmat` of size ``n \times n`` and coupling matrix `cplmat` of size ``d \times d``. The output function `g` of `Coupler` is of the form 
```math 
    y = g(u, t) = (E \otimes P) u
```
where ``\otimes`` is the Kronecker product, ``E`` is `conmat` and ``P`` is `cplmat`, ``u`` is the value of `input` and `y` is the value of `output`.
"""
@defss Base.@kwdef struct Coupler{C1, C2, IP, OP} 
    conmat::C1 = [-1. 1; 1. 1.]
    cplmat::C2 = [1 0 0; 0 0 0; 0 0 0]
    input::IP = Inport(size(C1, 1) * size(cplmat, 1))
    output::OP = Outport(size(C1, 1) * size(cplmat, 1))
end

function readout(ss::Coupler,  u, t)
    kron(ss.conmat, ss.cplmat) * u     # Time invariant coupling
end 

@doc raw"""
    Differentiator(kd=1; callbacks=nothing, name=Symbol())

Consructs a `Differentiator` whose input output relation is of the form 
```math 
    y(t) = k_d \dot{u}(t)
```
where ``u(t)`` is the input and ``y(t)`` is the output and ``kd`` is the differentiation constant.
"""
@defss Base.@kwdef struct Differentiator{KD, T, U, IP, OP} 
    kd::KD = 1. 
    t::T = 0.
    u::U = 0.
    input::IP = Inport()
    output::OP = Outport()
end

function readout(ss::Differentiator, uu, tt)
    out = tt ≤ ss.t[1] ? ss.u[1] : (uu[1] - ss.u[1]) / (tt - ss.t[1])
    ss.t = tt
    ss.u = uu
    ss.kd * out 
end

##### Pretty-printing
show(io::IO, ss::Adder) = print(io, "Adder(signs:$(ss.signs), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Multiplier) = print(io, "Multiplier(ops:$(ss.ops), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Gain) = print(io, "Gain(gain:$(ss.gain), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Terminator) = print(io, "Terminator(input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Memory) = 
    print(io, "Memory(delay:$(ss.delay), numtaps:$(length(ss.timebuf)), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Coupler) = print(io, "Coupler(conmat:$(ss.conmat), cplmat:$(ss.cplmat))")
show(io::IO, ss::Differentiator) = print(io, "Differentiator(kd:$(ss.kd))")
