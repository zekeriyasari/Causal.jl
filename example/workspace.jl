
using BenchmarkTools 

function f()
    array = Vector{Vector{Float64}}(undef, 1000)
    for i = 1 : 1000
        array[i] = rand(2)
    end
end

function g()
    array = Vector{Union{Nothing, Vector{Float64}}}(undef, 1000)
    for i = 1 : 1000
        array[i] = rand(2)
    end
end

f()
g()
@benchmark f()
@benchmark g()

