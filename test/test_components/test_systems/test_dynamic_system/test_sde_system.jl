# This file includes testset for SDESystem 

@testset "SDESystemTestSet" begin 
    @info "Running SDESystemTestSet ..."

    # SDESystem construction 
    f(dx, x, u, t) = (dx[1] = -x[1])
    h(dx, x, u, t) = (dx[1] = -x[1])
    g(x, u, t) = x
    ds = SDESystem((f,h), g, [1.], 0., nothing, Outport(1), alg=LambaEM{true}())
    ds = SDESystem((f,h), g, [1.], 0, nothing, Outport(1))
    @test isa(ds.statefunc, Tuple{<:Function, <:Function})
    @test typeof(ds.trigger) == Inpin{Float64}
    @test typeof(ds.handshake) == Outpin{Bool}
    @test ds.input === nothing
    @test isa(ds.output, Outport)
    @test length(ds.output) == 1
    @test ds.integrator.sol.prob.p === nothing

    # Driving SDESystem
    iport = Inport(1) 
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

    # SDESystem with input 
    function f2(dx, x, u, t)
        dx[1] = -x[1] + sin(u[2](t))
        dx[2] = -x[2] + cos(u[1](t))
        dx[3] = -x[3] + cos(u[1](t))
    end
    function h2(dx, x, u, t)
        dx[1] = -x[1] 
        dx[2] = -x[2] + cos(u[1](t))
        dx[3] = -x[3] + cos(u[2](t))
    end
    g2(x, u, t) = x 
    ds = SDESystem((f2, h2), g2, ones(3), 0., Inport(2), Outport(3))
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

    @info "Running SDESystemTestSet ..."
end  # testset
