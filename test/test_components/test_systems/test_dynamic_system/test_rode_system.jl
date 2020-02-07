# This file includes testset for RODESystem 

@testset "RODESystemTestSet" begin 
    # RODESystem construction 
    function statefunc(dx, x, u, t, W)
        dx[1] = 2x[1]*sin(W[1] - W[2])
        dx[2] = -2x[2]*cos(W[1] + W[2])
    end
    outputfunc(x, u, t) = x
    ds = RODESystem(nothing, Bus(2), statefunc, outputfunc, ones(2), 0.)
    @test typeof(ds.trigger) == Link{Float64}
    @test typeof(ds.handshake) == Link{Bool}
    @test ds.input === nothing
    @test isa(ds.output, Bus)
    @test length(ds.output) == 2
    @test ds.state == ones(2)
end