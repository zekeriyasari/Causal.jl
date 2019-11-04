using DifferentialEquations
using ForwardDiff
using DynamicalSystems

# Define a system
struct System{F, X, T}
    f::F 
    dx::X
    x::X 
    t::T 
end

# Construct a dynamic system
function lorenz(dx, x, sigma=10, beta=8/3, rho=28, gamma=1)
    dx[1] = sigma * (x[2] - x[1])
    dx[2] = x[1] * (rho - x[3]) - x[2]
    dx[3] = x[1] * x[2] - beta * x[3]
    dx .*= gamma
end
Df = (result, dx, x) -> ForwardDiff.jacobian!(result, lorenz, dx, x)
x = rand(3)
dx = rand(3)
ds = System(lorenz, x, dx, 0.)

# Define jacobian of the system
Dflorenz = (J,ds) -> ForwardDiff.jacobian!(J, ds.f, ds.dx, ds.x)

# Define solution of the system
s(t, ds=ds) = solve(ODEProblem(ds.f, ds.x, (ds.t, t))).u[end]

# As time evolves print solution and jacobian
xt = ones(1)
dxt = rand(1)
result = rand(1,1)
for tt in 0. : 10.
    val = s(tt)
    Dfunc(result, dxt, xt)
    @show (val, result)
end


# Construct a dynamic system 
ds = ContinuousDynamicalSystem(lorenz, ones(3), nothing)


