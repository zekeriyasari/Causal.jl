# This file includes testset for DiscreteSystem 

@testset "DiscreteSystemTestSet" begin 
    @info "Running DiscreteSystemTestSet ..."

    # ODESystem construction 
    sfunc1(dx, x, u, t) = (dx .= -x)
    ofunc1(x, u, t) = x
    ds = DiscreteSystem(righthandside=sfunc1, readout=ofunc1, state=[1.], input=nothing, output=Outport())
    @test typeof(ds.trigger) == Inpin{Float64}
    @test typeof(ds.handshake) == Outpin{Bool}
    @test ds.input === nothing
    @test typeof(ds.output) == Outport{Outpin{Float64}} 
    @test length(ds.output) == 1
    @test ds.state == [1.]
    @test ds.t == 0.
    @test ds.integrator.sol.prob.p === nothing

    function sfunc2(dx, x, u, t)
        dx[1] = x[1] + u[1](t)
        dx[2] = x[2] - u[2](t)
        dx[3] = x[3] + sin(u[1](t))
    end
    ofunc2(x, u, t) = x
    ds = DiscreteSystem(righthandside=sfunc2, readout=ofunc2, state=ones(3), input=Inport(2), output=Outport(3))
    @test isa(ds.input, Inport)
    @test isa(ds.output, Outport)
    @test length(ds.input) == 2
    @test length(ds.output) == 3

    ds = DiscreteSystem(righthandside=sfunc2, readout=nothing, state=ones(3), input = Inport(2), output = nothing)
    @test isa(ds.input, Inport)
    @test length(ds.input) == 2
    @test ds.readout === nothing
    @test ds.output === nothing

    # Driving ODESystem
    sfunc3(dx, x, u, t) = (dx .= -x)
    ofunc3(x, u, t) = x
    ds = DiscreteSystem(righthandside=sfunc3, readout=ofunc3, state=[1.], input=nothing, output=Outport())
    iport = Inport() 
    trg = Outpin()
    hnd = Inpin{Bool}()
    connect!(ds.output, iport)
    connect!(trg, ds.trigger)
    connect!(ds.handshake, hnd)
    tsk = launch(ds)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break
    end
    for t in 1. : 10.
        put!(trg, t)
        take!(hnd)
        @test ds.t == t
        @test [read(pin.link.buffer) for pin in iport] == ds.state
    end
    put!(trg, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
    put!(ds.output, NaN * ones(length(ds.output)))
    sleep(0.1)
    @test istaskdone(tsk2)

    # Test definining new DiscreteSystem 

    # Type must be mutable
    # The type must be mutable 
    @test_throws Exception @eval @def_discrete_system struct MyDiscreteSystem{RH, RO, ST, IP, OP}  
        righthandside::RH
        readout::RO 
        state::ST 
        input::IP 
        output::OP
    end

    # Type must be a subtype of AbstractDiscreteSystem
    @test_throws Exception @eval @def_discrete_system mutable struct MyDiscreteSystem{RH, RO, ST, IP, OP}  
        righthandside::RH
        readout::RO 
        state::ST 
        input::IP 
        output::OP
    end

    @test_throws Exception @eval @def_discrete_system mutable struct MyDiscreteSystem{RH, RO, ST, IP, OP} <: MyDummyAbstractDiscreteSystem
        righthandside::RH
        readout::RO 
        state::ST 
        input::IP 
        output::OP
    end

    @info "Done DiscreteSystemTestSet ..."
end
