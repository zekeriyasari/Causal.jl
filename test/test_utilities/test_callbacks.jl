# This file includees the callbacks tests

@testset  "CallbackTestSet" begin
    @info "Running CallbackTestSet ..."
    condition(obj) = obj.x >= 5
    action(obj) = println("Callaback activated . obj.x = ", obj.x)
    clb = Callback(condition, action)
    @test isenabled(clb)
    disable!(clb)
    @test !isenabled(clb)

    mutable struct Object{CB}
        x::Int
        clb::CB
    end
    obj = Object(1, clb)
    for val in 1 : 10
        obj.x  = val
        obj.clb(obj)
    end

    mutable struct Object2{CB}
        x::Int
        callbacks::CB
    end

    obj2 = Object2(4, Callback(condition, action))
    for val in 1 : 10
        obj2.x = val
        applycallbacks(obj2)
    end

    @info "Done CallbackTestSet."
end # testset
