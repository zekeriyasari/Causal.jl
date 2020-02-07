
main(name::Symbol, args...; kwargs...) = eval(name)(args...; kwargs...)
f(x, y) = x + y
g(x, y; z=4) = x + y + z
