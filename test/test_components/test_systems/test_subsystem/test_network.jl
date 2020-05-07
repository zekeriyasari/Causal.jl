# # This file includes testset for Network

# @testset "NetworkTestSet" begin 
#     # Network construction 
#     nodenum =  5
#     nodedim = 3
#     nodes = [LorenzSystem(Bus(nodedim), Bus(nodedim)) for i = 1 : nodenum]
#     conmat = [-1 1; 1 -1]
#     cplmat = [1 0 0; 0 0 0; 0 0 0]
#     net = Network(nodes, conmat, cplmat)
#     @test typeof(net.trigger) == Link{Float64}
#     @test typeof(net.handshake) == Link{Bool}
#     @test net.input == nothing
#     @test typeof(net.output) == Bus{Link{Float64}}
#     @test length(net.output) == nodenum * nodedim
#     @test length(filter(comp -> isa(comp, Memory), net.components)) == nodenum
#     @test length(filter(comp -> isa(comp, Coupler), net.components)) == 1
#     @test net.clusters == [1 : nodenum]

#     # More on Network construction 
#     conmat = (a = ones(nodenum, nodenum); map(i -> a[i, i] = -(nodenum - 1), 1 : nodenum); a)
#     net = Network(nodes, conmat, cplmat; inputnodeidx=[], outputnodeidx=[])
#     @test net.input === nothing
#     @test net.output === nothing
#     net = Network(nodes, conmat, cplmat; inputnodeidx=[], outputnodeidx=[1, 3]) 
#     @test net.input === nothing
#     @test typeof(net.output) == Bus{Link{Float64}}
#     @test length(net.output) == 2 * nodedim
#     net = Network(nodes, conmat, cplmat; inputnodeidx=[], outputnodeidx=collect(1:nodenum), clusters=[1:2, 3:5]) 
#     @test net.clusters == [1:2, 3:5]

#     # Network topologies
#     @test coupling(3, 1) == [1 0 0; 0 0 0; 0 0 0]
#     @test coupling(3, [1,2]) == [1 0 0; 0 1 0; 0 0 0]
#     @test coupling(3, [1,3]) == [1 0 0; 0 0 0; 0 0 1]

#     @test topology(:path_graph, 5) == [-1.0   1.0  -0.0  -0.0  -0.0;
#                                         1.0  -2.0   1.0  -0.0  -0.0;
#                                         -0.0   1.0  -2.0   1.0  -0.0;
#                                         -0.0  -0.0   1.0  -2.0   1.0;
#                                         -0.0  -0.0  -0.0   1.0  -1.0]
#     @test topology(:path_graph, 5, weight=10) == [-1.0   1.0  -0.0  -0.0  -0.0;
#                                                 1.0  -2.0   1.0  -0.0  -0.0;
#                                                 -0.0   1.0  -2.0   1.0  -0.0;
#                                                 -0.0  -0.0   1.0  -2.0   1.0;
#                                                 -0.0  -0.0  -0.0   1.0  -1.0] * 10
#     conmat = topology(:path_graph, 5, weight=10, timevarying=true)
#     @test size(conmat) == (5, 5)
#     @test isa(conmat, Matrix{<:Function})
#     @test map(f -> f(1.), conmat) == [-1.0   1.0  -0.0  -0.0  -0.0;
#                                         1.0  -2.0   1.0  -0.0  -0.0;
#                                         -0.0   1.0  -2.0   1.0  -0.0;
#                                         -0.0  -0.0   1.0  -2.0   1.0;
#                                         -0.0  -0.0  -0.0   1.0  -1.0] * 10
#     @test topology(:star_graph, 5) == [-4.0   1.0   1.0   1.0   1.0;
#                                         1.0  -1.0  -0.0  -0.0  -0.0;
#                                         1.0  -0.0  -1.0  -0.0  -0.0;
#                                         1.0  -0.0  -0.0  -1.0  -0.0;
#                                         1.0  -0.0  -0.0  -0.0  -1.0]
#     @test topology(:cycle_graph, 5) == [-2.0   1.0  -0.0  -0.0   1.0;
#                                         1.0  -2.0   1.0  -0.0  -0.0;
#                                         -0.0   1.0  -2.0   1.0  -0.0;
#                                         -0.0  -0.0   1.0  -2.0   1.0;
#                                         1.0  -0.0  -0.0   1.0  -2.0]
#     @test clusterconnectivity(1:2, 3:6) == [-3.0   3.0  -1.0   1.0   0.0   0.0;
#                                             3.0  -3.0   1.0  -1.0   0.0   0.0;
#                                             -1.0   1.0  -9.0   3.0   3.0   3.0;
#                                             1.0  -1.0   3.0  -9.0   3.0   3.0;
#                                             0.0   0.0   3.0   3.0  -9.0   3.0;
#                                             0.0   0.0   3.0   3.0   3.0  -9.0]
#     @test isapprox(cgsconnectivity(:path_graph, 5), [-0.8   0.8   0.0   0.0   0.0;
#                                                 0.8  -2.0   1.2   0.0   0.0;
#                                                 0.0   1.2  -2.4   1.2   0.0;
#                                                 0.0   0.0   1.2  -2.0   0.8;
#                                                 0.0   0.0   0.0   0.8  -0.8])

#     # Driving Network 
#     nodenum = 2
#     nodedim = 3
#     nodes = [LorenzSystem(Bus(nodedim), Bus(nodedim)) for i = 1 : nodenum]
#     conmat = [-1 1; 1 -1]
#     cplmat = [1 0 0; 0 0 0; 0 0 0]
#     net = Network(nodes, conmat, cplmat)
#     tsk = ComponentTask.(launch(net))
#     for t in 0. : 10.
#         drive!(net, t)
#         approve!(net)
#     end
#     release(net)
#     terminate!(net)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

# end  # testset 
