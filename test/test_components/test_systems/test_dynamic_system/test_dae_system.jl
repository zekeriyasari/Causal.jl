# This file includes testset for DAESystem 

@testset "DAESystemTestSet" begin 
    @info "Running DAESystemTestSet ..."

    # DAESystem construction 
    function sfunc(out, dx, x, u, t)
        out[1] = -0.04 * x[1] + 1e4 * x[2] * x[3] - dx[1]
        out[2] = 0.04 * x[1] - 3e7 * x[2]^2 - 1e4 * x[2] * x[3] - dx[2]
        out[3] = x[1] + x[2] + x[3] - 1.0
    end
    ofunc(x, u, t) = x
    state = [1., 0., 0.]
    stateder = [-0.04, 0.04, 0.]
    differential_vars = [true, true, false]
    ds = DAESystem(sfunc, ofunc, state, 0., nothing, Outport(3), 
        stateder=stateder, modelkwargs=(differential_vars=differential_vars,))
    @test typeof(ds.trigger) == Inpin{Float64}
    @test typeof(ds.handshake) == Outpin{Bool} 
    @test ds.input === nothing 
    @test typeof(ds.output) == Outport{Outpin{Float64}}
    @test length(ds.output) == 3 
    @test ds.state == state 
    @test ds.t == 0. 
    @test ds.integrator.sol.prob.p === nothing

    # Driving DAESystem 
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

    # DAESystem with inputs 
    function sfunc2(out, dx, x, u, t)
        out[1] = -0.04 * x[1] + 1e4 * x[2] * x[3] - dx[1] + u[1](t)
        out[2] = 0.04 * x[1] - 3e7 * x[2]^2 - 1e4 * x[2] * x[3] - dx[2] + u[2](t)
        out[3] = x[1] + x[2] + x[3] - 1.0
    end
    ofunc2(x, u, t) = x
    state = [1., 0., 0.]
    stateder = [-0.04, 0.04, 0.]
    differential_vars = [true, true, false]
    ds = DAESystem(sfunc2, ofunc2, state, 0., Inport(2), Outport(3), 
        stateder=stateder, modelkwargs=(differential_vars=differential_vars,), numtaps=5)
    @test typeof(ds.trigger) == Inpin{Float64}
    @test typeof(ds.handshake) == Outpin{Bool} 
    @test typeof(ds.input) <: Inport 
    @test typeof(ds.output) == Outport{Outpin{Float64}}
    @test length(ds.input) == 2 
    @test length(ds.output) == 3 
    @test ds.state == state 
    @test ds.t == 0. 
    @test typeof(ds.integrator.sol.prob.p) <: Interpolant
    @test size(ds.integrator.sol.prob.p.timebuf) == (5,)
    @test size(ds.integrator.sol.prob.p.databuf) == (2,5)
    
    # Driving DAESystem with input 
    oport = Outport(2)
    iport = Inport(3) 
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
    for t in 1 : 10 
        put!(trg, t) 
        put!(oport, ones(2) * t)
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

    @info "Done DAESystemTestSet."
end # testset 
