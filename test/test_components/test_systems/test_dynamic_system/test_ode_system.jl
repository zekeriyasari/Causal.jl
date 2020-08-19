# This file includes testset for ODESystem 

@testset "ODESystemTestSet" begin 
    @info "Running ODESystemTestSet ..."

    # ODESystem construction 
    sfunc1(dx, x, u, t) = (dx .= -x)
    ofunc1(x, u, t) = x
    ds = ODESystem(righthandside = sfunc1, readout=ofunc1, state=[1.], solverkwargs=(dt=0.1,), input=nothing, output=Outport())
    ds = ODESystem(righthandside = sfunc1, readout=ofunc1, state=[1.], solverkwargs=(dt=0.1, dense=true), input=nothing, output=Outport())
    ds = ODESystem(righthandside = sfunc1, readout=ofunc1, state=[1.], input=nothing, output=Outport())
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
    ds = ODESystem(righthandside=sfunc2, readout=ofunc2, state=ones(3), input=Inport(2), output=Outport(3))
    @test isa(ds.input, Inport)
    @test isa(ds.output, Outport)
    @test length(ds.input) == 2
    @test length(ds.output) == 3

    ds = ODESystem(righthandside=sfunc2, readout=nothing, state=ones(3), input=Inport(2), output=nothing)
    @test isa(ds.input, Inport)
    @test length(ds.input) == 2
    @test ds.readout === nothing
    @test ds.output === nothing

    # Driving ODESystem
    sfunc3(dx, x, u, t) = (dx .= -x)
    ofunc3(x, u, t) = x
    ds = ODESystem(righthandside=sfunc3, readout=ofunc3, state=[1.], input=nothing, output=Outport())
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

    # LinaerSystem tests
    ds = ContinuousLinearSystem(input=nothing, output=Outport(1))
    @test ds.A == fill(-1, 1, 1) 
    @test ds.B == fill(1., 1, 1) 
    @test ds.C == fill(1, 1, 1)
    @test ds.D == fill(0, 1, 1)
    @test_throws Exception ds.γ == 1.
    ds = ContinuousLinearSystem(input=nothing, output=Outport(2), A=ones(2,2), C=ones(2,2))
    @test ds.input === nothing
    @test isa(ds.output, Outport)
    @test length(ds.output) == 2
    ds = ContinuousLinearSystem(input=Inport(2), output=Outport(3), A=ones(4,4), B=ones(4,2), C=ones(3,4), D=ones(3, 2), state=zeros(4))
    @test ds.t == 0.
    @test ds.state == zeros(4)

    ds = ContinuousLinearSystem(input=Inport(2), output=Outport(3), A=ones(4,4), B=ones(4,2), C=ones(3,4), D=ones(3, 2))
    @test typeof(ds.integrator.sol.prob.p) <: Interpolant
    @test size(ds.integrator.sol.prob.p.timebuf) == (3,)
    @test size(ds.integrator.sol.prob.p.databuf) == (2, 3)
    @test isa(ds.output, Outport)
    @test length(ds.input) == 2
    @test length(ds.output) == 3
    @test length(ds.state) == 4
    oport = Outport(2)
    iport = Inport(3)
    trg = Outpin()
    hnd = Inpin{Bool}()
    connect!(ds.output, iport)
    connect!(ds.handshake, hnd)
    connect!(trg, ds.trigger)
    connect!(oport, ds.input)
    tsk = launch(ds)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break
    end
    for t in 1. : 10.
        put!(trg, t)
        u = [sin(t), cos(t)]
        put!(oport, u)
        take!(hnd)
        @test ds.t == t 
        @test [read(pin.link.buffer) for pin in iport] == ds.C * ds.state + ds.D * u
    end
    put!(trg, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
    put!(ds.output, NaN * ones(length(ds.output)))
    sleep(0.1)
    @test istaskdone(tsk2)

    # Other 3-Dimensional AbstractODESystem tests
    for (DSystem, defaults) in zip(
        [
            LorenzSystem, 
            ChenSystem, 
            ChuaSystem, 
            RosslerSystem
        ], [
            (σ = 10., β = 8/3, ρ = 28., γ = 1.), 
            (a = 35., b = 3., c = 28., γ = 1.), 
            (diode = Jusdl.PiecewiseLinearDiode(), α = 15.6, β = 28., γ = 1.),
            (a = 0.38, b = 0.3, c = 4.82, γ = 1.)
        ]
        )
        ds = DSystem(input=nothing, output=Outport(3); defaults...)  # System with key-value pairs with no input and bus output.
        ds = DSystem(input=nothing, output=Outport(3))  # System with no input
        @test ds.input === nothing
        @test isa(ds.output, Outport)
        @test length(ds.output) == 3
        @test length(ds.state) == 3
        iport = Inport(3)
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
    end

    for (DSystem, defaults) in zip(
        [
            ForcedLorenzSystem, 
            ForcedChenSystem, 
            ForcedChuaSystem, 
            ForcedRosslerSystem
        ], [
            (σ = 10., β = 8/3, ρ = 28., γ = 1.), 
            (a = 35., b = 3., c = 28., γ = 1.), 
            (diode = Jusdl.PiecewiseLinearDiode(), α = 15.6, β = 28., γ = 1.),
            (a = 0.38, b = 0.3, c = 4.82, γ = 1.)
        ]
        )
        ds = DSystem(input=Inport(3), output=Outport(3), state=rand(3), cplmat=[1. 0 0; 0 1 0; 0 0 0])
        @test typeof(ds.integrator.sol.prob.p) <: Interpolant
        @test size(ds.integrator.sol.prob.p.timebuf) == (3,)
        @test size(ds.integrator.sol.prob.p.databuf) == (3,3)
        @test isa(ds.input, Inport) 
        @test isa(ds.output, Outport) 
        @test length(ds.input) == 3
        @test length(ds.output) == 3
        iport = Inport(3)
        oport = Outport(3)
        trg = Outpin() 
        hnd = Inpin{Bool}() 
        connect!(ds.output, iport)
        connect!(oport, ds.input)
        connect!(trg, ds.trigger) 
        connect!(ds.handshake, hnd)
        tsk = launch(ds)
        tsk2 = @async while true 
            all(take!(iport) .=== NaN) && break 
        end
        for t in 1. : 10.
            put!(trg, t)
            u = [sin(t), cos(t), log(t)]
            put!(oport, u)
            take!(hnd)
            @test ds.t == t 
        end
        put!(trg, NaN)
        sleep(0.1)
        @test istaskdone(tsk)
        put!(ds.output, NaN * ones(length(ds.output)))
        sleep(0.1)
        @test istaskdone(tsk2)
    end

    # VanderpolSystem tests.
    ds = VanderpolSystem(input=nothing, output=Outport(2))  # System with no input
    @test ds.input === nothing
    @test isa(ds.output, Outport)
    @test length(ds.output) == 2
    @test length(ds.state) == 2
    @test ds.μ == 5.
    @test ds.γ == 1.
    iport = Inport(2) 
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

    ds = ForcedVanderpolSystem(input=Inport(2), output=Outport(2), cplmat=[1 0; 0 0])  # Add input values to 1. state 
    @test isa(ds.input, Inport) 
    @test isa(ds.output, Outport) 
    @test length(ds.input) == 2
    @test length(ds.output) == 2
    iport = Inport(2) 
    oport = Outport(2)
    trg = Outpin()
    hnd = Inpin{Bool}()
    connect!(oport, ds.input)
    connect!(ds.output, iport) 
    connect!(trg, ds.trigger)
    connect!(ds.handshake, hnd)
    tsk = launch(ds)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break 
    end
    for t in 1. : 10.
        put!(trg, t)
        u = [sin(t), cos(t)]
        put!(oport, u)
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

    # Test defining new ODE systems 
    # The type must be mutabe
    @test_throws Exception @eval @def_ode_system struct ODESystem{RH, RO, ST, IP, OP}
        righthandside::RH 
        readout::RO 
        state::ST 
        input::IP 
        output::OP
    end

    # The type must be a subtype of AbstractODESystem
    @test_throws Exception @eval @def_ode_system mutable struct ODESystem{RH, RO, ST, IP, OP} 
        righthandside::RH 
        readout::RO 
        state::ST 
        input::IP 
        output::OP
    end

    # The type must be subtype of AbstractODESystem
    @test_throws Exception @eval @def_ode_system mutable struct ODESystem{RH, RO, ST, IP, OP} <: MyDummyyAbstractODESystem 
        righthandside::RH 
        readout::RO 
        state::ST 
        input::IP 
        output::OP
    end

    @info "Done ODESystemTestSet."
end  # testset 

