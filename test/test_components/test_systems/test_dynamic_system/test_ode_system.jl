# This file includes testset for ODESystem 

@testset "ODESystemTestSet" begin 
    # ODESystem construction 
    sfunc1(dx, x, u, t) = (dx .= -x)
    ofunc1(x, u, t) = x
    ds = ODESystem(nothing, Bus(), sfunc1, ofunc1, [1.], 0.)
    @test typeof(ds.trigger) == Link{Float64}
    @test typeof(ds.handshake) == Link{Bool}
    @test ds.input === nothing
    @test typeof(ds.output) == Bus{Link{Float64}} 
    @test length(ds.output) == 1
    @test ds.state == [1.]
    @test ds.t == 0.
    @test ds.inputval == nothing

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
        drive(ds, 1.)
        approve(ds)
        # @test ds.t == t
        # @test [read(link.buffer) for link in ds.output] == ds.state
    end
    terminate(ds)
    sleep(0.1)
    @test all(istaskdone.(tsk))

end  # testset 

