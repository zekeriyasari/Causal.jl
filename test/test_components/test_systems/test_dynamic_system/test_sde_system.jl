# This file includes testset for SDESystem 

@testset "SDESystemTestSet" begin 
    # SDESystem construction 
    f(dx, x, u, t) = (dx[1] = -x[1])
    h(dx, x, u, t) = (dx[1] = -x[1])
    g(x, u, t) = x
    ds = SDESystem(nothing, Bus(1), (f,h), g, [1.], 0., solver=Solver(LambaEM{true}()), noise=Noise(WienerProcess(0., zeros(1))))
    ds = SDESystem(nothing, Bus(1), (f,h), g, [1.], 0)
    @test isa(ds.statefunc, Tuple{<:Function, <:Function})
    @test typeof(ds.trigger) == Link{Float64}
    @test typeof(ds.handshake) == Link{Bool}
    @test ds.input === nothing
    @test isa(ds.output, Bus)
    @test length(ds.output) == 1

    # Driving SDESystem
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
    ds = SDESystem(Bus(2), Bus(3), (f2, h2), g2, ones(3), 0)
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
