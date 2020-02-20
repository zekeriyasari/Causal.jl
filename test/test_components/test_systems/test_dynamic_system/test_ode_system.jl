# This file includes testset for ODESystem 

@testset "ODESystemTestSet" begin 
    # ODESystem construction 
    sfunc1(dx, x, u, t) = (dx .= -x)
    ofunc1(x, u, t) = x
    ds = ODESystem(nothing, Bus(), sfunc1, ofunc1, [1.], 0., solverkwargs=(dt=0.1,))
    ds = ODESystem(nothing, Bus(), sfunc1, ofunc1, [1.], 0., solverkwargs=(dt=0.1, dense=true))
    ds = ODESystem(nothing, Bus(), sfunc1, ofunc1, [1.], 0.)
    @test typeof(ds.trigger) == Link{Float64}
    @test typeof(ds.handshake) == Link{Bool}
    @test ds.input === nothing
    @test typeof(ds.output) == Bus{Link{Float64}} 
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
    ds = ODESystem(Bus(2), Bus(3), sfunc2, ofunc2, ones(3), 0.)
    @test isa(ds.input, Bus)
    @test isa(ds.output, Bus)
    @test length(ds.input) == 2
    @test length(ds.output) == 3

    ds = ODESystem(Bus(2), nothing, sfunc2, nothing, ones(3), 0.)
    @test isa(ds.input, Bus)
    @test length(ds.input) == 2
    @test ds.outputfunc === nothing
    @test ds.output === nothing

    # Driving ODESystem
    sfunc3(dx, x, u, t) = (dx .= -x)
    ofunc3(x, u, t) = x
    ds = ODESystem(nothing, Bus(), sfunc3, ofunc3, [1.], 0.)
    tsk = launch(ds)
    for t in 1. : 10.
        drive(ds, t)
        approve(ds)
        @test ds.t == t
        @test [read(link.buffer) for link in ds.output] == ds.state
    end
    terminate(ds)
    sleep(0.1)
    @test all(istaskdone.(tsk))

    # LinaerSystem tests
    ds = LinearSystem(nothing, Bus(1))
    @test ds.A == fill(-1, 1, 1) 
    @test ds.B == fill(0, 1, 1) 
    @test ds.C == fill(1, 1, 1)
    @test ds.D == fill(0, 1, 1)
    @test_throws Exception ds.gamma == 1.
    ds = LinearSystem(nothing, Bus(2), A=ones(2,2), C=ones(2,2))
    @test ds.input === nothing
    @test isa(ds.output, Bus)
    @test length(ds.output) == 2
    ds = LinearSystem(Bus(2), Bus(3), A=ones(4,4), B=ones(4,2), C=ones(3,4), D=ones(3, 2), state=zeros(4,1))
    @test ds.t == 0.
    @test ds.state == zeros(4,1)
    ds = LinearSystem(Bus(2), Bus(3), A=ones(4,4), B=ones(4,2), C=ones(3,4), D=ones(3, 2))
    @test isa(ds.output, Bus)
    @test isa(ds.output, Bus)
    @test length(ds.input) == 2
    @test length(ds.output) == 3
    @test length(ds.state) == 4
    tsk = launch(ds)
    for t in 1. : 10.
        drive(ds, t)
        u = [sin(t), cos(t)]
        put!(ds.input, u)
        approve(ds)
        @test ds.t == t 
        @test [read(link.buffer) for link in ds.output] == ds.C * ds.state + ds.D * u
    end
    terminate(ds)
    sleep(0.1)
    @test all(istaskdone.(tsk))

    # Other 3-Dimensional AbstractODESystem tests
    DSystems = Dict(
        LorenzSystem => Dict(:sigma => 10, :beta => 8/3, :rho => 28, :gamma => 1.), 
        ChenSystem => Dict(:a => 35, :b => 3, :c => 28, :gamma => 1),  
        ChuaSystem => Dict(:diode => DynamicSystems.PiecewiseLinearDiode(), :alpha => 15.6, :beta => 28., :gamma => 1),
        RosslerSystem => Dict(:a => 0.38, :b => 0.3, :c => 4.82, :gamma => 1.)
        )
    for (DSystem, defaults) in DSystems
        ds = DSystem(nothing, Bus(3); defaults...)  # System with key-value pairs with no input and bus output.
        ds = DSystem(nothing, Bus(3))  # System with no input
        @test ds.input === nothing
        @test isa(ds.output, Bus)
        @test length(ds.output) == 3
        @test length(ds.state) == 3
        foreach(item -> @test(getfield(ds, item.first) == item.second), defaults)
        tsk = launch(ds)
        for t in 1. : 10.
            drive(ds, t)
            approve(ds)
            @test ds.t == t 
            @test [read(link.buffer) for link in ds.output] == ds.state
        end
        terminate(ds)
        sleep(0.1)
        @test all(istaskdone.(tsk))

        ds = DSystem(Bus(3), Bus(3), cplmat=[1 0 0; 0 1 0; 0 0 0])  # Add input values to 1. and 2. state 
        @test isa(ds.input, Bus) 
        @test isa(ds.input, Bus) 
        @test length(ds.input) == 3
        @test length(ds.output) == 3
        tsk = launch(ds)
        for t in 1. : 10.
            drive(ds, t)
            u = [sin(t), cos(t), log(t)]
            put!(ds.input, u)
            approve(ds)
            @test ds.t == t 
        end
        terminate(ds)
        sleep(0.1)
        @test all(istaskdone.(tsk))
    end

    # VanderpolSystem tests.
    ds = VanderpolSystem(nothing, Bus(2))  # System with no input
    @test ds.input === nothing
    @test isa(ds.output, Bus)
    @test length(ds.output) == 2
    @test length(ds.state) == 2
    @test ds.mu == 5.
    @test ds.gamma == 1.
    tsk = launch(ds)
    for t in 1. : 10.
        drive(ds, t)
        approve(ds)
        @test ds.t == t 
        @test [read(link.buffer) for link in ds.output] == ds.state
    end
    terminate(ds)
    sleep(0.1)
    @test all(istaskdone.(tsk))

    ds = VanderpolSystem(Bus(2), Bus(2), cplmat=[1 0; 0 0])  # Add input values to 1. state 
    @test isa(ds.input, Bus) 
    @test isa(ds.input, Bus) 
    @test length(ds.input) == 2
    @test length(ds.output) == 2
    tsk = launch(ds)
    for t in 1. : 10.
        drive(ds, t)
        u = [sin(t), cos(t)]
        put!(ds.input, u)
        approve(ds)
        @test ds.t == t 
        @test [read(link.buffer) for link in ds.output] == ds.state
    end
    terminate(ds)
    sleep(0.1)
    @test all(istaskdone.(tsk))

end  # testset 

