# # This file includes testset for DDESystem 

# @testset "DDESystemTestSet" begin 
#     # DDESystem construction 
#     out = zeros(1)
#     tau = 1 
#     conslags = [tau]
#     histfunc(out, u, t) = (out .= 1.)
#     function statefunc(dx, x, h, u, t)
#         h(out, u, t - tau) # Update `out`.
#         dx[1] = out[1] + x[1]
#     end
#     outputfunc(x, u, t) = x 
#     ds = DDESystem(nothing, Bus(1), (statefunc, histfunc), outputfunc, [1.], 0., alg=MethodOfSteps(Vern9()))
#     ds = DDESystem(nothing, Bus(1), (statefunc, histfunc), outputfunc, [1.], 0., alg=MethodOfSteps(Tsit5()), modelkwargs=(constant_lags=conslags,))
#     @test typeof(ds.trigger) == Link{Float64}
#     @test typeof(ds.handshake) == Link{Bool}
#     @test ds.input === nothing
#     @test isa(ds.output, Bus)
#     @test length(ds.output) == 1
#     @test ds.integrator.sol.prob.constant_lags == [1]
#     @test ds.integrator.sol.prob.dependent_lags == ()
#     @test ds.integrator.sol.prob.neutral == false
#     @test ds.integrator.alg == Tsit5()

#     # Driving DDESystem
#     tsk = launch(ds)
#     for t in 1 : 10
#         drive(ds, t)
#         approve(ds)
#         @test ds.t == t 
#         @test [read(link.buffer) for link in ds.output] == ds.state 
#     end
#     terminate(ds)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))        

#     # DDESystem with input 
#     # hist2 = History(histfunc, conslags, ())
#     function statefunc2(dx, x, h, u, t)
#         h(out, u, t - tau) # Update `out`.
#         dx[1] = out[1] + x[1] + sin(u[1](t)) + cos(u[2](t))
#     end
#     outputfunc2(x, u, t) = x
#     ds = DDESystem(Bus(2), Bus(1), (statefunc2, histfunc), outputfunc2, [1.], 0.)
#     @test isa(ds.input, Bus)
#     @test isa(ds.output, Bus)
#     @test length(ds.input) == 2
#     @test length(ds.output) == 1
#     tsk = launch(ds)
#     for t in 1 : 10 
#         drive(ds, t)
#         put!(ds.input, [t, 2t])
#         approve(ds)
#         @test ds.t == t 
#         @test [read(link.buffer) for link in ds.output] == ds.state 
#     end
#     terminate(ds)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))
# end  # testset

