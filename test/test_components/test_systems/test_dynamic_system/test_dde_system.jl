# This file includes testset for DDESystem 

@testset "DDESystemTestSet" begin 
    @info "Running DDESystemTestSet ..."

    # DDESystem construction 
    out = zeros(1)
    tau = 1 
    constlags = [tau]
    histfunc(out, u, t) = (out .= 1.)
    function statefunc(dx, x, h, u, t)
        h(out, u, t - tau) # Update `out`.
        dx[1] = out[1] + x[1]
    end
    outputfunc(x, u, t) = x 
    ds = DDESystem(righthandside=statefunc, history=histfunc, readout=outputfunc, state=[1.], input=nothing, output=Outport(1), alg=MethodOfSteps(Vern9()), constlags=constlags, depslags=nothing)
    # ds = DDESystem((statefunc, histfunc), outputfunc, [1.], 0., nothing, Outport(1), alg=MethodOfSteps(Tsit5()), modelkwargs=(constant_lags=constlags,))
    @test typeof(ds.trigger) == Inpin{Float64}
    @test typeof(ds.handshake) == Outpin{Bool}
    @test ds.input === nothing
    @test isa(ds.output, Outport)
    @test length(ds.output) == 1
    @test ds.integrator.sol.prob.constant_lags == constlags
    @test ds.integrator.sol.prob.dependent_lags === nothing
    @test ds.integrator.sol.prob.neutral == false
    @test ds.integrator.alg == Vern9()

    # Driving DDESystem
    iport = Inport(1) 
    trg  = Outpin() 
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

    # DDESystem with input 
    # hist2 = History(histfunc, constlags, ())
    function statefunc2(dx, x, h, u, t)
        h(out, u, t - tau) # Update `out`.
        dx[1] = out[1] + x[1] + sin(u[1](t)) + cos(u[2](t))
    end
    outputfunc2(x, u, t) = x
    ds = DDESystem(righthandside=statefunc2, history=histfunc, readout=outputfunc2, state=[1.], input=Inport(2),    
        output=Outport(1), constlags=constlags, depslags=nothing)
    @test isa(ds.input, Inport)
    @test isa(ds.output, Outport)
    @test length(ds.input) == 2
    @test length(ds.output) == 1
    @test typeof(ds.integrator.sol.prob.p) <: Interpolant 
    @test size(ds.integrator.sol.prob.p.timebuf) == (3,)
    @test size(ds.integrator.sol.prob.p.databuf) == (2, 3)
    oport = Outport(2)
    iport = Inport(1)
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

    @info "Done DDESystemTestSet ..."
end  # testset

