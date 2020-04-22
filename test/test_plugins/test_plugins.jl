# # This file includes testset for Plugin

# import Jusdl.Plugins: Fft, Variance, Std, Mean, Lyapunov

# @testset "PluginTestSet" begin 
#     plgs = [Fft(), Variance(), Std(), Mean(), Lyapunov()]
#     foreach(plg -> @test(plg.dims == 1), plgs[1 : end - 1])
#     plg = plgs[end]
#     @test plg.m == 15
#     @test plg.J == 5
#     @test plg.ni == 300
#     @test plg.ts == 0.01

#     foreach(plg -> @test(applicable(process, plg, rand(100))), plgs)
# end # testset

