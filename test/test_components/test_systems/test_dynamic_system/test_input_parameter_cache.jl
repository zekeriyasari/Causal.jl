@testset "InterpolatedInputCacheTestSet" begin
    # Parameters are initialized with zero-valued placeholders, then replaced
    # by sampled input. Cached derivatives must be refreshed on every update.
    rhs!(dz,z,u,t) = (dz[1] = 0.1*z[1] + u[1](t))
    ds = ODESystem(righthandside=rhs!,readout=(z,u,t)->z,state=[0.0],
                   input=Inport(),output=Outport(),
                   solverkwargs=(abstol=1e-11,reltol=1e-11))
    errors=Float64[]
    for t in 0.0:0.001:1.0
        Causal.evolve!(ds,[1.0],t)
        push!(errors,abs(ds.state[1]-10*expm1(0.1*t)))
    end
    @test maximum(errors) < 1e-8
    @test ds.t == 1.0
    @test ds.interpolant.nvalid == 3
    @test ds.interpolant(1.0) ≈ 1.0

    # Changing sampled input u(t)=1+t has an independent closed-form response.
    ramp = ODESystem(righthandside=rhs!,readout=(z,u,t)->z,state=[0.0],
                     input=Inport(),output=Outport(),
                     solverkwargs=(abstol=1e-11,reltol=1e-11))
    ramp_errors=Float64[]
    for t in 0.0:0.001:1.0
        Causal.evolve!(ramp,[1.0+t],t)
        exact=110*expm1(0.1*t)-10*t
        push!(ramp_errors,abs(ramp.state[1]-exact))
    end
    @test maximum(ramp_errors) < 1e-8
    @test ramp.interpolant.nvalid == 3
    @test ramp.interpolant(0.9995) ≈ 1.9995

    # Single-sample startup must have zero slope, including vector-valued input.
    interp=Interpolant(3,2)
    Causal.update_interpolator!(interp,[2.0,-3.0],0.0)
    @test interp(0.5) ≈ [2.0,-3.0]
end
