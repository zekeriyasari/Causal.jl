# This file includes testset for RODESystem 

@testset "RODESystemTestSet" begin 
    # RODESystem construction 
    function statefunc(dx, x, u, t, W)
        dx[1] = 2x[1]*sin(W[1] - W[2])
        dx[2] = -2x[2]*cos(W[1] + W[2])
    end
    outputfunc(x, u, t) = x
    ds = RODESystem(nothing, Bus(2), statefunc, outputfunc, ones(2), 0., 
        alg=RandomEM(), solverkwargs=(dt=0.01,))
    ds = RODESystem(nothing, Bus(2), statefunc, outputfunc, ones(2), 0., 
        alg=RandomEM(), solverkwargs=(dt=0.01,), modelkwargs=(rand_prototype=zeros(2),))
    # ds = RODESystem(nothing, Bus(2), statefunc, outputfunc, ones(2), 0.)
    @test typeof(ds.trigger) == Link{Float64}
    @test typeof(ds.handshake) == Link{Bool}
    @test ds.input === nothing
    @test isa(ds.output, Bus)
    @test length(ds.output) == 2
    @test ds.state == ones(2)

    # Driving RODESystem
    tsk = launch(ds)
    for t in 1 : 10
        drive(ds, t)
        approve(ds)
        @test ds.t == t
        @test [read(link.buffer) for link in ds.output] == ds.state
    end
    terminate(ds)
    sleep(0.1)
    @test all(istaskdone.(tsk))

     # Driving RODESystem with input
    function sfunc(dx, x, u, t, W)
        dx[1] = 2x[1]*sin(W[1] - W[2]) + cos(u[1](t)) 
        dx[2] = -2x[2]*cos(W[1] + W[2]) - sin(u[1](t))
    end
    ofunc(x, u, t) = x
    ds = RODESystem(Bus(2), Bus(2), sfunc, ofunc, ones(2), 0., solverkwargs=(dt=0.01,), modelkwargs=(rand_prototype=zeros(2),))
    tsk = launch(ds)
    for t in 1 : 10
        drive(ds, t)
        put!(ds.input, [t, 2t])
        approve(ds)
        @test ds.t == t
        @test [read(link.buffer) for link in ds.output] == ds.state
    end
    terminate(ds)
    sleep(0.1)
    @test all(istaskdone.(tsk))

end  # testset 