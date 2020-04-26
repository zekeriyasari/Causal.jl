# This file includes testset for ODESystem 

@testset "ODESystemTestSet" begin 
    @info "Running ODESystemTestSet ..."

    # ODESystem construction 
    sfunc1(dx, x, u, t) = (dx .= -x)
    ofunc1(x, u, t) = x
    ds = ODESystem(sfunc1, ofunc1, [1.], 0., solverkwargs=(dt=0.1,), nothing, Outport())
    ds = ODESystem(sfunc1, ofunc1, [1.], 0., solverkwargs=(dt=0.1, dense=true), nothing, Outport())
    ds = ODESystem(sfunc1, ofunc1, [1.], 0., nothing, Outport())
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
    ds = ODESystem(sfunc2, ofunc2, ones(3), 0., Inport(2), Outport(3))
    @test isa(ds.input, Inport)
    @test isa(ds.output, Outport)
    @test length(ds.input) == 2
    @test length(ds.output) == 3

    ds = ODESystem(sfunc2, nothing, ones(3), 0., Inport(2), nothing)
    @test isa(ds.input, Inport)
    @test length(ds.input) == 2
    @test ds.outputfunc === nothing
    @test ds.output === nothing

    # Driving ODESystem
    sfunc3(dx, x, u, t) = (dx .= -x)
    ofunc3(x, u, t) = x
    ds = ODESystem(sfunc3, ofunc3, [1.], 0., nothing, Outport())
    iport = Inport()
    trg = Outpin() 
    hnd = Inpin{Bool}()
    connect(ds.output, iport)
    connect(trg, ds.trigger)
    connect(ds.handshake, hnd)
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
    ds = LinearSystem(nothing, Outport(1))
    @test ds.A == fill(-1, 1, 1) 
    @test ds.B == fill(0, 1, 1) 
    @test ds.C == fill(1, 1, 1)
    @test ds.D == fill(0, 1, 1)
    @test_throws Exception ds.gamma == 1.
    ds = LinearSystem(nothing, Outport(2), A=ones(2,2), C=ones(2,2))
    @test ds.input === nothing
    @test isa(ds.output, Outport)
    @test length(ds.output) == 2
    ds = LinearSystem(Inport(2), Outport(3), A=ones(4,4), B=ones(4,2), C=ones(3,4), D=ones(3, 2), state=zeros(4,1))
    @test ds.t == 0.
    @test ds.state == zeros(4,1)

    ds = LinearSystem(Inport(2), Outport(3), A=ones(4,4), B=ones(4,2), C=ones(3,4), D=ones(3, 2), numtaps=3)
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
    connect(ds.output, iport)
    connect(ds.handshake, hnd)
    connect(trg, ds.trigger)
    connect(oport, ds.input)
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
    DSystems = Dict(
        LorenzSystem => Dict(:sigma => 10, :beta => 8/3, :rho => 28, :gamma => 1.), 
        ChenSystem => Dict(:a => 35, :b => 3, :c => 28, :gamma => 1),  
        ChuaSystem => Dict(:diode => Jusdl.PiecewiseLinearDiode(), :alpha => 15.6, :beta => 28., :gamma => 1),
        RosslerSystem => Dict(:a => 0.38, :b => 0.3, :c => 4.82, :gamma => 1.)
        )
    for (DSystem, defaults) in DSystems
        ds = DSystem(nothing, Outport(3); defaults...)  # System with key-value pairs with no input and bus output.
        ds = DSystem(nothing, Outport(3))  # System with no input
        @test ds.input === nothing
        @test isa(ds.output, Outport)
        @test length(ds.output) == 3
        @test length(ds.state) == 3
        foreach(item -> @test(getfield(ds, item.first) == item.second), defaults)
        iport = Inport(3)
        trg = Outpin() 
        hnd = Inpin{Bool}() 
        connect(ds.output, iport)
        connect(trg, ds.trigger) 
        connect(ds.handshake, hnd)
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

        ds = DSystem(Inport(3), Outport(3), cplmat=[1 0 0; 0 1 0; 0 0 0], numtaps=3)
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
        connect(ds.output, iport)
        connect(oport, ds.input)
        connect(trg, ds.trigger) 
        connect(ds.handshake, hnd)
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
    ds = VanderpolSystem(nothing, Outport(2))  # System with no input
    @test ds.input === nothing
    @test isa(ds.output, Outport)
    @test length(ds.output) == 2
    @test length(ds.state) == 2
    @test ds.mu == 5.
    @test ds.gamma == 1.
    iport = Inport(2) 
    trg = Outpin() 
    hdn = Inpin{Bool}()
    connect(ds.output, iport) 
    connect(trg, ds.trigger) 
    connect(ds.handshake, hnd)
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

    ds = VanderpolSystem(Inport(2), Outport(2), cplmat=[1 0; 0 0])  # Add input values to 1. state 
    @test isa(ds.input, Inport) 
    @test isa(ds.output, Outport) 
    @test length(ds.input) == 2
    @test length(ds.output) == 2
    iport = Inport(2) 
    oport = Outport(2)
    trg = Outpin()
    hnd = Inpin{Bool}()
    connect(oport, ds.input)
    connect(ds.output, iport) 
    connect(trg, ds.trigger)
    connect(ds.handshake, hnd)
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

    @info "Done ODESystemTestSet."
end  # testset 

