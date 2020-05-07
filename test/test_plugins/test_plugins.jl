# This file includes testset for Plugin

@testset "PluginTestSet" begin 
    @info "Running PluginTestSet ..."

    # Construction of a new plugin
    struct MeanPlugin  <: AbstractPlugin end 
    Jusdl.process(plg::MeanPlugin, x) = mean(x)

    # Try equip a writer in a model.
    model = Model(clock=Clock(0., 0.01, 10.)) 
    addnode!(model, SinewaveGenerator(), label=:gen)
    addnode!(model, Writer(buflen=50, plugin=MeanPlugin()), label=:writer)
    addbranch!(model, :gen => :writer)
    simulate!(model)

    # Test the simulation data
    data = read(getnode(model, :writer).component, flatten=false)
    @test length(data) == 20
    for (t,x) in data
        @test isapprox(x, mean(sin.(2 * pi * t)))
    end

    @info "Done PluginTestSet ..."
end # testset

