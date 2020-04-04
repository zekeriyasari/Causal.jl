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

julia> ss = StaticSystem(Bus(2), Bus(3), g)
StaticSystem(outputfunc:g, input:Bus(nlinks:2, eltype:Link{Float64}, isreadable:false, iswritable:false), output:Bus(nlinks:3, eltype:Link{Float64}, isreadable:false, iswritable:false))

julia> g2(u, t) = t  # The system does not have any input.
g2 (generic function with 1 method)

julia> ss2 = StaticSystem(nothing, Bus(), g2)
StaticSystem(outputfunc:g2, input:nothing, output:Bus(nlinks:1, eltype:Link{Float64}, isreadable:false, iswritable:false))
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
    Adder(input::Bus[, signs])

Construts an `Adder` with input bus `input` and signs `signs`. `signs` is a tuplle of `+` and/or `-`. The output function `g` of `Adder` is of the form,
```math 
    y = g(u, t) =  \sum_{j = 1}^n s_k u_k
```
where `n` is the length of the `input`, ``s_k`` is the `k`th element of `signs`, ``u_k`` is the `k`th value of `input` and ``y`` is the value of `output`. The default value of `signs` is all `+`.

# Example 
```jldoctest
julia> adder = Adder(Bus(3), (+, +, -));

julia> adder.outputfunc([3, 4, 5], 0.) == 3 + 4 - 5
true
```
"""
struct Adder{OF, IB, OB, TR, HS, CB, S} <: AbstractStaticSystem
    @generic_static_system_fields
    signs::S
    function Adder(input::Inport, signs::Tuple{Vararg{Union{typeof(+), typeof(-)}}}=tuple(fill(+, length(input))...); 
        callbacks=nothing, name=Symbol())
        outputfunc(u, t) = sum([sign(val) for (sign, val) in zip(signs, u)])
        output = Outport()
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(signs)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4(), signs)
    end
end


@doc raw"""
    Multiplier(input::Bus[, ops])

Construts an `Multiplier` with input bus `input` and signs `signs`. `signs` is a tuplle of `*` and/or `/`. The output function `g` of `Multiplier` is of the form,
```math 
    y = g(u, t) =  \prod_{j = 1}^n s_k u_k
```
where `n` is the length of the `input`, ``s_k`` is the `k`th element of `signs`, ``u_k`` is the `k`th value of `input` and ``y`` is the value of the `output`. The default value of `signs` is all `*`.

# Example 
```jldoctest
julia> mlt = Multiplier(Bus(3), (*, *, /));

julia> mlt.outputfunc([3, 4, 5], 0.) == 3 * 4 / 5
true
```
"""
struct Multiplier{OF, IB, OB, TR, HS, CB, S} <: AbstractStaticSystem
    @generic_static_system_fields
    ops::S
    function Multiplier(input::Inport, ops::Tuple{Vararg{Union{typeof(*), typeof(/)}}}=tuple(fill(*, length(input))...);
        callbacks=nothing, name=Symbol())
        function outputfunc(u, t)
            val = 1
            for i = 1 : length(ops)
                val = ops[i](val, u[i])
            end
            val
        end
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

julia> g = Gain(Bus(2), gain=K);

julia> g.outputfunc([1., 2.], 0.) == K * [1., 2.]
true
```
"""
struct Gain{OF, IB, OB, TR, HS, CB, G} <: AbstractStaticSystem
    @generic_static_system_fields
    gain::G
    function Gain(input::Inport{<:Inpin{T}}; gain=1., callbacks=nothing, name=Symbol()) where T 
        outputfunc(u, t) =  gain * u
        output = Outport{T}(length(input))
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(gain)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4(), gain)
    end
end


@doc raw"""
    Terminator(input::Bus)

Constructs a `Terminator` with input bus `input`. The output function `g` is eqaul to `nothing`. A `Terminator` is used just to sink the incomming data flowing from its `input`.
"""
struct Terminator{OF, IB, OB, TR, HS, CB} <: AbstractStaticSystem
    @generic_static_system_fields
    function Terminator(input::Inport; callbacks=nothing, name=Symbol())
        outputfunc = nothing
        output = nothing
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), 
            typeof(callbacks)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4()) 
    end
end 


"""
    Memory(input::Bus{Union{Missing, T}}, numdelay::Int; initial=Vector{T}(undef, length(input)))

Constructs a 'Memory` with input bus `input`. A 'Memory` delays the values of `input` by an amount of `numdelay`. `initial` determines the transient output from the `Memory`, that is, until the internal buffer of `Memory` is full, the values from `initial` is returned.
"""
struct Memory{OF, IB, OB, TR, HS, CB, B} <: AbstractMemory
    @generic_static_system_fields
    buffer::B 
    function Memory(input::Inport{<:Inpin{T}}, numdelay::Int;initial=nothing, callbacks=nothing, name=Symbol()) where T 
        numinput = length(input)
        buffer = numinput == 1 ? Buffer{Fifo}(T, numdelay) : Buffer{Fifo}(T, numinput, numdelay)
        initial === nothing && (initial = numinput == 1 ? zero(T) : zeros(T, numinput))
        fill!(buffer, initial)
        outputfunc(u, t) = read(buffer)
        output = Outport{T}(numinput)
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(buffer)}(outputfunc, input, output, trigger, handshake, callbacks, name, uuid4(), buffer)
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

# ##### Pretty-printing
show(io::IO, ss::StaticSystem) = print(io, 
    "StaticSystem(outputfunc:$(ss.outputfunc), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Adder) = print(io, 
    "Adder(signs:$(ss.signs), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Multiplier) = print(io, 
    "Multiplier(ops:$(ss.ops), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Gain) = print(io, 
    "Gain(gain:$(ss.gain), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Terminator) = print(io, "Gain(input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Memory) = print(io, 
    "Memory(ndelay:$(length(ss.buffer)), input:$(ss.input), output:$(ss.output))")
show(io::IO, ss::Coupler) = print(io, "Coupler(conmat:$(ss.conmat), cplmat:$(ss.cplmat))")
