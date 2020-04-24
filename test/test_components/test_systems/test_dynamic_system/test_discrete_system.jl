# This file includes testset for DiscreteSystem 

@testset "DiscreteSystemTestSet" begin 
    # ODESystem construction 
    sfunc1(dx, x, u, t) = (dx .= -x)
    ofunc1(x, u, t) = x
    ds = DiscreteSystem(sfunc1, ofunc1, [1.], 0., nothing, Outport())
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
    ds = DiscreteSystem(sfunc2, ofunc2, ones(3), 0., Inport(2), Outport(3))
    @test isa(ds.input, Inport)
    @test isa(ds.output, Outport)
    @test length(ds.input) == 2
    @test length(ds.output) == 3

    ds = DiscreteSystem(sfunc2, nothing, ones(3), 0., Inport(2), nothing)
    @test isa(ds.input, Inport)
    @test length(ds.input) == 2
    @test ds.outputfunc === nothing
    @test ds.output === nothing

    # Driving ODESystem
    sfunc3(dx, x, u, t) = (dx .= -x)
    ofunc3(x, u, t) = x
    ds = DiscreteSystem(sfunc3, ofunc3, [1.], 0., nothing, Outport())
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
end