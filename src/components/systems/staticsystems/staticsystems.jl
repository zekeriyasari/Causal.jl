# This file contains the static systems of Causal.

import UUIDs: uuid4

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
    foreach(nex -> appendex!(ex, nex), [
        :( trigger::$TRIGGER_TYPE_SYMBOL = Inpin() ),
        :( handshake::$HANDSHAKE_TYPE_SYMBOL = Outpin{Bool}() ),
        :( callbacks::$CALLBACKS_TYPE_SYMBOL = nothing ),
        :( name::Symbol = Symbol() ),
        :( id::$ID_TYPE_SYMBOL = Causal.uuid4() )
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end

##### Define prototipical static systems.

"""
    $TYPEDEF

Consructs a generic static system with `readout` function, `input` port and `output` port.

# Fields 

    $TYPEDFIELDS

# Example 
```jldoctest 
julia> ss = StaticSystem(readout = (t,u) -> u[1] + u[2], input=Inport(2), output=Outport(1));

julia> ss.readout(0., ones(2))
2.0
```
"""
@def_static_system struct StaticSystem{RO, IP, OP} <: AbstractStaticSystem
    "Readout function"
    readout::RO 
    "Input port"
    input::IP 
    "Output. May be an `Outport` of `Nothing`"
    output::OP
end


"""
    $TYPEDEF

Construts an `Adder` with input bus `input` and signs `signs`. `signs` is a tuplle of `+` and/or `-`. The output function `g` of `Adder` is of the form,
```math 
    y = g(u, t) =  \\sum_{j = 1}^n s_k u_k
```
where `n` is the length of the `input`, ``s_k`` is the `k`th element of `signs`, ``u_k`` is the `k`th value of `input` and ``y`` is the value of `output`. The default value of `signs` is all `+`.

# Fields 

    $TYPEDFIELDS

# Example 
```jldoctest
julia> adder = Adder(signs=(+, +, -));

julia> adder.readout([3, 4, 5], 0.) == 3 + 4 - 5
true
```
"""
@def_static_system struct Adder{S, IP, OP, RO} <: AbstractStaticSystem 
    "Addition signs"
    signs::S = (+, +)
    "Input port"
    input::IP = Inport(length(signs))
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (u, t, signs=signs) -> sum([sign(val) for (sign, val) in zip(signs, u)])
end


"""
    $TYPEDEF

Construts an `Multiplier` with input bus `input` and signs `signs`. `signs` is a tuplle of `*` and/or `/`. The output function `g` of `Multiplier` is of the form,
```math 
    y = g(u, t) =  \\prod_{j = 1}^n s_k u_k
```
where `n` is the length of the `input`, ``s_k`` is the `k`th element of `signs`, ``u_k`` is the `k`th value of `input` and ``y`` is the value of the `output`. The default value of `signs` is all `*`.

# Fields 

    $TYPEDFIELDS

# Example 
```jldoctest
julia> mlt = Multiplier(ops=(*, *, /));

julia> mlt.readout([3, 4, 5], 0.) == 3 * 4 / 5
true
```
"""
@def_static_system struct Multiplier{S, IP, OP, RO} <: AbstractStaticSystem
    "Operators"
    ops::S = (*,*)
    "Input port"
    input::IP = Inport(length(ops))
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (u, t, ops=ops) -> begin 
        ops = ops
        val = 1
        for i = 1 : length(ops)
            val = ops[i](val, u[i])
        end
        val
    end
end


"""
    $TYPEDEF

Constructs a `Gain` whose output function `g` is of the form 
```math 
    y = g(u, t) =  K u
```
where ``K`` is `gain`, ``u`` is the value of `input` and `y` is the value of `output`.

# Fields 

    $TYPEDFIELDS

# Example 
```jldoctest
julia> K = [1. 2.; 3. 4.];

julia> sfunc = Gain(input=Inport(2), gain=K);

julia> sfunc.readout([1., 2.], 0.) == K * [1., 2.]
true
```
"""
@def_static_system struct Gain{G, IP, OP, RO} <: AbstractStaticSystem
    "Gain"
    gain::G = 1.
    "Input port"
    input::IP = Inport() 
    "Output port"
    output::OP = Outport(length(gain * zeros(length(input)))) 
    "Readout function"
    readout::RO = (u, t, gain=gain) -> gain * u
end


"""
    $TYPEDEF

Constructs a `Terminator` with input bus `input`. The output function `g` is eqaul to `nothing`. A `Terminator` is used just 
to sink the incomming data flowing from its `input`.

# Fields 

    $TYPEDFIELDS
"""
@def_static_system struct Terminator{IP, OP, RO} <: AbstractStaticSystem
    "Input port"
    input::IP = Inport() 
    "Output. Must be nothing"
    output::OP = nothing
    "Readout functionk. Must be nothing"
    readout::RO = nothing
end 


"""
    $TYPEDEF

Constructs a 'Memory` with input bus `input`. A 'Memory` delays the values of `input` by an amount of `numdelay`. 
`initial` determines the transient output from the `Memory`, that is, until the internal buffer of `Memory` is full, 
the values from `initial` is returned.

# Fields 

    $TYPEDFIELDS

# Example
```jldoctest
julia> Memory(delay=0.1)
Memory(delay:0.1, numtaps:5, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))

julia> Memory(delay=0.1, numtaps=5)
Memory(delay:0.1, numtaps:5, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))
```
"""
@def_static_system struct Memory{D, IN, TB, DB, IP, OP, RO} <: AbstractMemory
    "Delay in seconds"
    delay::D = 1.
    "Inital value of memory"
    initial::IN = zeros(1)
    "Number of taps memory. The number of taps is length of internal(timebuf, databuf) buffers of memory"
    numtaps::Int = 5
    "Time buffer of memory to record time instants"
    timebuf::TB = Buffer(numtaps)
    "Data buffer of memory to record input data values"
    databuf::DB = length(initial) == 1 ? Buffer(numtaps) : Buffer(length(initial), numtaps)
    "Input port"
    input::IP = Inport(length(initial))
    "Output port"
    output::OP = Outport(length(initial))
    "Readout function"
    readout::RO = (u, t, delay=delay, initial=initial, numtaps=numtaps, timebuf=timebuf, databuf=databuf) -> begin 
        if t <= delay
            return initial
        else
            tt = content(timebuf, flip=false)
            uu = content(databuf, flip=false)
            if length(tt) == 1
                return uu[1]
            end
            if ndims(databuf) == 1
                itp = CubicSplineInterpolation(range(tt[end], tt[1], length=length(tt)), reverse(uu), extrapolation_bc=Line())
                return itp(t - delay)
            else
                itp = map(row -> CubicSplineInterpolation(range(tt[end], tt[1], length=length(tt)), reverse(row), extrapolation_bc=Line()), eachrow(uu))
                return map(f -> f(t - delay), itp)
            end
        end
    end
end 


"""
    $TYPEDEF

Constructs a coupler from connection matrix `conmat` of size ``n \\times n`` and coupling matrix `cplmat` of size ``d \\times
d``. The output function `g` of `Coupler` is of the form 
```math 
    y = g(u, t) = (E \\otimes P) u
```
where ``\\otimes`` is the Kronecker product, ``E`` is `conmat` and ``P`` is `cplmat`, ``u`` is the value of `input` and `y`
is the value of `output`.

# Fields 

    $TYPEDFIELDS
"""
@def_static_system struct Coupler{C1, C2, IP, OP, RO} <: AbstractStaticSystem
    "Outer coupling matrix"
    conmat::C1 = [-1. 1; 1. 1.]
    "Inner coupling matrix"
    cplmat::C2 = [1 0 0; 0 0 0; 0 0 0]
    "Input port"
    input::IP = Inport(size(conmat, 1) * size(cplmat, 1))
    "Output port"
    output::OP = Outport(size(conmat, 1) * size(cplmat, 1))
    "Readout function"
    readout::RO = typeof(conmat) <: AbstractMatrix{<:Real} ? 
        ( (u, t, conmat=conmat, cplmat=cplmat) ->  kron(conmat, cplmat) * u ) : # Time-invariant coupling 
        ( (u, t, conmat=conmat, cplmat=cplmat) ->  kron(map(f -> f(t), conmat), cplmat) * u )   # Time-variant coupling
end

"""
    $TYPEDEF

Consructs a `Differentiator` whose input output relation is of the form 
```math 
    y(t) = k_d \\dot{u}(t)
```
where ``u(t)`` is the input and ``y(t)`` is the output and ``kd`` is the differentiation constant.

# Fields

    $TYPEDFIELDS
"""
@def_static_system struct Differentiator{T1 <: Real, 
                                         T2 <: Real,   
                                         T3 <: Real,   
                                         IP, 
                                         OP, 
                                         RO} <: AbstractStaticSystem 
    "Differentiation gain"
    kd::T1 = 1. 
    "Time"
    t::T2 = zeros(0.)
    "Input value"
    u::T3 = zeros(0.)
    "Input port"
    input::IP = Inport()
    "Output port"
    output::OP = Outport()
    "Readout function"
    readout::RO = (uu, tt, t=t, u=u, kd=kd) -> begin
        val = only(uu)
        sst = t[1]
        ssu = u[1]
        out = tt ≤ sst ? ssu : (val - ssu) / (tt - sst)
        t .= t
        u .= val
        kd * out 
    end
end

##### Pretty-printing
show(io::IO, ss::StaticSystem) = print(io,"StaticSystem(readout:$(ss.readout), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Adder) = print(io, "Adder(signs:$(ss.signs), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Multiplier) = print(io, "Multiplier(ops:$(ss.ops), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Gain) = print(io, "Gain(gain:$(ss.gain), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Terminator) = print(io, "Terminator(input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Memory) = 
    print(io, "Memory(delay:$(ss.delay), numtaps:$(length(ss.timebuf)), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Coupler) = print(io, "Coupler(conmat:$(ss.conmat), cplmat:$(ss.cplmat))")
show(io::IO, ss::Differentiator) = print(io, "Differentiator(kd:$(ss.kd))")
