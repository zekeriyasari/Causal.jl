# This file includees the callbacks tests

@testset  "CallbackTestSet" begin 

    condition(obj) = obj.x >= 5
    action(obj) = println("Callaback activated . obj.x = ", obj.x)
    clb = Callback(condition, action)
    @test clb.enabled 


    mutable struct Object
        x::Int 
        clb::Callback
    end
    obj = Object(1, clb)
    for val in 1 : 10
        obj.x  = val
        obj.clb(obj)
    end

    mutable struct Object2
        x::Int 
        callbacks::Vector{Callback}
        Object2(x::Int) = new(x, Callback[])
    end

    obj2 = Object2(4)
    @test isempty(obj2.callbacks)

    clb = Callback(condition, action)
    addcallback(obj2, clb)
    @test length(obj2.callbacks) == 1

    for val in 1 : 10
        obj2.x = val 
        obj2.callbacks(obj)
    end

end # testset