# This file contains the static systems of Jusdl.

@doc raw"""
    StaticSystem(input, output, outputfunc)

Construts a `StaticSystem` with input `input`, output `output` and output function `outputfunc`. `outputfunc` is a two-argument function of the form
```math
    y = g(u, t)
```
where `g` is `outputfunc`, `t` is the time, `u` is the input at time `t` and `y` is the output at time `t`.  `input` and `output` may be `nothing` depending on relation defined in `outputfunc`.

# Example 
```jldoctest
julia> g(u, t) = [u[1] + u[2], sin(u[2]), cos([1])]  # The system has 2 inputs and 3 outputs.
g (generic function with 1 method)

julia> ss = StaticSystem(g, Inport(2), Outport(3))
StaticSystem(outputfunc:g, input:Inport(numpins:2, eltype:Inpin{Float64}), output:Outport(numpins:3, eltype:Outpin{Float64}))

julia> g2(u, t) = t  # The system does not have any input.
g2 (generic function with 1 method)

julia> ss2 = StaticSystem(g2, nothing, Outport())
StaticSystem(outputfunc:g2, input:nothing, output:Outport(numpins:1, eltype:Outpin{Float64}))
```
"""
struct StaticSystem{OF, IB, OB, TR, HS, CB} <: AbstractStaticSystem
    @generic_static_system_fields
    function StaticSystem(outputfunc, input, output; callbacks=nothing, name=Symbol())
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), 
            typeof(callbacks)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4())
    end
end


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

julia> adder.outputfunc([3, 4, 5], 0.) == 3 + 4 - 5
true
```
"""
struct Adder{OF, IB, OB, TR, HS, CB, S} <: AbstractStaticSystem
    @generic_static_system_fields
    signs::S
    function Adder(signs::Tuple{Vararg{Union{typeof(+), typeof(-)}}}=(+,+); 
        callbacks=nothing, name=Symbol())
        outputfunc(u, t) = sum([sign(val) for (sign, val) in zip(signs, u)])
        input = Inport(length(signs))
        output = Outport()
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(signs)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4(), signs)
    end
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

julia> mlt.outputfunc([3, 4, 5], 0.) == 3 * 4 / 5
true
```
"""
struct Multiplier{OF, IB, OB, TR, HS, CB, S} <: AbstractStaticSystem
    @generic_static_system_fields
    ops::S
    function Multiplier(ops::Tuple{Vararg{Union{typeof(*), typeof(/)}}}=(*,*);
        callbacks=nothing, name=Symbol())
        function outputfunc(u, t)
            val = 1
            for i = 1 : length(ops)
                val = ops[i](val, u[i])
            end
            val
        end
        input = Inport(length(ops))
        output = Outport()
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(ops)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4(), ops)
    end
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

julia> sfunc.outputfunc([1., 2.], 0.) == K * [1., 2.]
true
```
"""
struct Gain{OF, IB, OB, TR, HS, CB, G} <: AbstractStaticSystem
    @generic_static_system_fields
    gain::G
    function Gain(input::Inport{<:Inpin{T}}=Inport(); gain=1., callbacks=nothing, name=Symbol()) where T 
        outputfunc(u, t) =  gain * u
        out = gain * zeros(length(input))
        output = Outport{T}(length(out))
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(gain)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4(), gain)
    end
end


@doc raw"""
    Terminator(input::Inport)

Constructs a `Terminator` with input bus `input`. The output function `g` is eqaul to `nothing`. A `Terminator` is used just to sink the incomming data flowing from its `input`.
"""
struct Terminator{OF, IB, OB, TR, HS, CB} <: AbstractStaticSystem
    @generic_static_system_fields
    function Terminator(input::Inport=Inport(); callbacks=nothing, name=Symbol())
        outputfunc = nothing
        output = nothing
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), 
            typeof(callbacks)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4()) 
    end
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
struct Memory{OF, IB, OB, TR, HS, CB, D, TB, DB} <: AbstractMemory
    @generic_static_system_fields
    delay::D
    timebuf::TB
    databuf::DB 
    function Memory(delay=1.; initial::AbstractVector{T}=zeros(1), numtaps::Int=5, 
        t0=0., dt=0.01, callbacks=nothing, name=Symbol()) where T 
        numinput = length(initial)
        databuf = numinput == 1 ? Buffer(T, numtaps) : Buffer(T, numinput, numtaps)
        timebuf = Buffer(T, numtaps)
        # trange = range(t0, length=numtaps, step=dt)
        # foreach(t -> write!(timebuf, t), trange)
        # foreach(t -> write!(databuf, initial), trange)
        function outputfunc(u, t)
            if t <= delay
                return initial
            else
                # if !isfull(timebuf)
                #     return initial
                # else 
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
                # end
            end
        end
        input = Inport{T}(numinput)
        output = Outport{T}(numinput)
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(delay), typeof(timebuf), typeof(databuf)}(outputfunc, input, output, trigger, 
            handshake, callbacks, name, uuid4(), delay, timebuf, databuf)
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
struct Coupler{OF, IB, OB, TR, HS, CB, C1, C2} <: AbstractStaticSystem
    @generic_static_system_fields
    conmat::C1
    cplmat::C2
    function Coupler(conmat::AbstractMatrix, cplmat::AbstractMatrix; callbacks=nothing, name=Symbol())
        n = size(conmat, 1)
        d = size(cplmat, 1)
        input = Inport(n * d)
        output = Outport(n * d)
        if eltype(conmat) <: Real 
            outputfunc = (u, t) -> kron(conmat, cplmat) * u     # Time invariant coupling
        else
            outputfunc = (u, t) -> kron(map(f->f(t), conmat), cplmat) * u  # Time varying coupling 
        end
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(conmat), typeof(cplmat)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4(), conmat, 
            cplmat)
    end
end

@doc raw"""
    Differentiator(kd=1; callbacks=nothing, name=Symbol())

Consructs a `Differentiator` whose input output relation is of the form 
```math 
    y(t) = k_d \dot{u}(t)
```
where ``u(t)`` is the input and ``y(t)`` is the output and ``kd`` is the differentiation constant.
"""
struct Differentiator{OF, IB, OB, TR, HS, CB, KD, T, U} <: AbstractStaticSystem
    @generic_static_system_fields
    kd::KD
    t::T
    u::U
    function Differentiator(;kd=1, callbacks=nothing, name=Symbol())
        t = zeros(1)
        u = zeros(1)
        input = Inport() 
        output = Outport()
        trigger = Inpin() 
        handshake = Outpin{Bool}()
        function outputfunc(uu, tt)
            out = tt ≤ t[1] ? u[1] : (uu[1] - u[1]) / (tt - t[1])
            t .= tt
            u .= uu
            return kd * out 
        end
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), typeof(kd), typeof(t), typeof(u)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4(), kd, t, u)
    end
end


# ##### Pretty-printing
show(io::IO, ss::StaticSystem) = 
    print(io, "StaticSystem(outputfunc:$(ss.outputfunc), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Adder) = print(io, "Adder(signs:$(ss.signs), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Multiplier) = print(io, "Multiplier(ops:$(ss.ops), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Gain) = print(io, "Gain(gain:$(ss.gain), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Terminator) = print(io, "Terminator(input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Memory) = 
    print(io, "Memory(delay:$(ss.delay), numtaps:$(length(ss.timebuf)), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Coupler) = print(io, "Coupler(conmat:$(ss.conmat), cplmat:$(ss.cplmat))")
show(io::IO, ss::Differentiator) = print(io, "Differentiator(kd:$(ss.kd))")
