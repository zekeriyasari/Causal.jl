# This file includes testset for sources.

@testset "ClockTestSet" begin 
    # Clock construction 
    clk1 = Clock(0., 1., 10.)
    clk2 = Clock(0., 1, 10)
    clk3 = Clock(0, 1, 10)
    @test eltype(clk1.t) == Float64
    @test eltype(clk2.t) == Float64
    @test eltype(clk3.t) == Int

    # Check Clock defaults.
    clk = clk1
    @test clk.t == 0.
    @test clk.dt == 1.
    @test clk.tf == 10.
    @test typeof(clk.generator) == Channel{Float64}
    @test clk.generator.sz_max == 0
    @test !ispaused(clk) 
    @test !isrunning(clk)

    # Set Clock
    set!(clk)
    @test isrunning(clk)

    # Taking values from clk 
    clk = Clock(0., 1., 10.)
    set!(clk)
    @test [take!(clk) for i in 0 : 10] == collect(Float64, 0:10)
    @test isoutoftime(clk)
end
