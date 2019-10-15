# This example illustrates synchronization of discrete time chaotic systems.

using Jusdl
using Plots 

# Construct the components 
function foldedfunc(dx, x, u, t, a=-0.1, b=-1.7)
    dx[1] = x[2] + a * x[1]
    dx[2] = b + x[1]^2
end
outputfunc(x, u, t) = x
dsfolded = DiscreteSystem(foldedfunc, outputfunc, rand(2), 0)

function henonfunc(dx, x, u, t, alpha=1.07, beta=0.3)
    dx[1] = -beta * x[2] + u[1]
    dx[2] = x[3] + 1 - alpha * x[2]^2 + u[2]
    dx[3] = beta * x[2] + x[1] + u[3]
end
dshenon = DiscreteSystem(henonfunc, outputfunc, rand(3), 0, Bus(3))

a = -0.1
b = -1.7
alpha = 1.07
beta = 0.3
A = [a 1; 0 0]
f(x) = [0, b + x[1]^2]
B = [0 -beta 0; 0 0 1; 1 beta 0]
g(y) = [0, 1 - alpha * y[2]^2, 0]
F(x) = x
Finv(x) = x
# F(x) = [x[1] + x[2], x[2]^2, x[3]]
# Finv(x) = [x[1] - sqrt(abs(x[2])), sqrt(abs(x[2])), x[3]]
M = [1 1; 0 2; 3 0]
L = [0.1 -beta 0; 0 -0.02 1; 1 beta 0.3]
function staticfunc(u, t, a=a, b=b, alpha=alpha, beta=beta,
    A=A, B=B, f=f, g=g, F=F, Finv=Finv, M=M, L=L)
    x = u[1:2]
    y = u[3:5]
    err = F(y) - M*x
    R1 = (L - B) * err - M * (A * x + f(x))
    U = -B * y - g(y) + Finv(-R1)
end
ss = StaticSystem(staticfunc, Bus(5))
mem = Memory(2, Bus(3), scale=0)
writer1 = Writer(Bus(2))
writer2 = Writer(Bus(3))
clk = Clock(0., 1., 1000.)

# Connect the components
connect(dsfolded.output, ss.input[1:2])
connect(dshenon.output, ss.input[3:5])
connect(ss.output, mem.input)
connect(mem.output, dshenon.input)
connect(dsfolded.output, writer1.input)
connect(dshenon.output, writer2.input)

# Construct the model
model = Model(dsfolded, dshenon, ss, mem, writer1, writer2, clk=clk)

# Simulate the model 
sim = simulate(model)

# Read the simulation data 
content1 = vcat(collect(values(read(writer1)))...)
content2 = vcat(collect(values(read(writer2)))...)

# Plot the errors
error = zeros(size(content1, 1), 3)
for k in 1 : size(error, 1)
    error[k, :] = F(content2[k, :]) - M * content1[k, :]
end
theme(:default)
plt1 = bar(error[1:20, 1], label="", bar_width=0.2, 
    size=(400, 200),xtickfont=font(10), ytickfont=font(10))
plt2 = bar(error[1:20, 2], label="", bar_width=0.2,
    size=(400, 200),xtickfont=font(10), ytickfont=font(10))
plt3 = bar(error[1:20, 3], label="", bar_width=0.2,
    size=(400, 200),xtickfont=font(10), ytickfont=font(10))

path = "/tmp"
if ispath(path)
    savefig(plt1, joinpath(path, "discrete_system_error1.pdf"))
    savefig(plt2, joinpath(path, "discrete_system_error2.pdf"))
    savefig(plt3, joinpath(path, "discrete_system_error3.pdf"))
else 
    @warn "$path does not exist. Plots are not saved."
end
