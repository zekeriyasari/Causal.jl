# This file includes testset for RODESystem 

@testset "RODESystemTestSet" begin 
    @info "Running RODESystemTestSet ..."

    # RODESystem construction 
    function statefunc(dx, x, u, t, W)
        dx[1] = 2x[1]*sin(W[1] - W[2])
        dx[2] = -2x[2]*cos(W[1] + W[2])
    end
    outputfunc(x, u, t) = x
    ds = RODESystem(statefunc, outputfunc, ones(2), 0.,  nothing, Outport(2),
        alg=RandomEM(), solverkwargs=(dt=0.01,))
    ds = RODESystem(statefunc, outputfunc, ones(2), 0., nothing, Outport(2), 
        alg=RandomEM(), solverkwargs=(dt=0.01,), modelkwargs=(rand_prototype=zeros(2),))
    @test typeof(ds.trigger) == Inpin{Float64}
    @test typeof(ds.handshake) == Outpin{Bool}
    @test ds.input === nothing
    @test isa(ds.output, Outport)
    @test length(ds.output) == 2
    @test ds.state == ones(2)
    @test ds.integrator.sol.prob.p === nothing

    # Driving RODESystem
    iport = Inport(2) 
    trg = Outpin() 
    hnd = Inpin{Bool}()
    connect(ds.output, iport) 
    connect(trg, ds.trigger) 
    connect(ds.handshake, hnd)
    tsk = launch(ds)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break 
    end
    for t in 1 : 10
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

    # Driving RODESystem with input
    function sfunc(dx, x, u, t, W)
        dx[1] = 2x[1]*sin(W[1] - W[2]) + cos(u[1](t)) 
        dx[2] = -2x[2]*cos(W[1] + W[2]) - sin(u[1](t))
    end
    ofunc(x, u, t) = x
    ds = RODESystem(sfunc, ofunc, ones(2), 0., Inport(2), Outport(2), 
        solverkwargs=(dt=0.01,), modelkwargs=(rand_prototype=zeros(2),), numtaps=5)
    @test typeof(ds.integrator.sol.prob.p) <: Interpolant
    @test size(ds.integrator.sol.prob.p.timebuf) == (5,)
    @test size(ds.integrator.sol.prob.p.databuf) == (2,5)
    oport = Outport(2) 
    iport = Inport(2) 
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
    for t in 1 : 10
        put!(trg, t)
        put!(oport, [t, 2t])
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

    @info "Done RODESystemTestSet ..."
end  # testset 