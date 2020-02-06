# This file includes testset for sources.

@testset "ClockTestSet" begin 
    # Clock construction 
    clk1 = Clock(0., 1., 10.)
    clk2 = Clock(0., 1, 10)
    clk3 = Clock(0, 1, 10)
    @test eltype(clk1.t) == Float64
    @test eltype(clk2.t) == Float64
    @test eltype(clk3.t) == Int
end
