# This example illustrates synchronization of discrete time chaotic systems.

using JuSDL
using Plots 

# Construct the components 
function foldedfunc(dx, x, u, t, a=-0.1, b=-1.7)
    dx[1] = x[2] + a * x[1]
    dx[2] = b + x[1]^2
end
outputfunc(x, u, t) = x
dsfolded = DiscreteSystem(foldedfunc, outputfunc, rand(2), 0)

# Construct the components 
function henonfunc(dx, x, u, t, alpha=1.07, beta=0.3)
    dx[1] = -beta * x[2] + u[1]
    dx[2] = x[3] + 1 - alpha * x[2]^2 + u[2]
    dx[3] = beta * x[2] + x[1]+ u[3]
end
dshenon = DiscreteSystem(henonfunc, outputfunc, rand(3), 0, Bus(3))

# Construct the coupler 
a = -0.1
b = -1.7
alpha = 1.07
beta = 0.3
A = [a 1; 0 0]
f(x) = [0, b + x[1]^2]
B = [0 -beta 0; 0 0 1; 1 beta 0]
g(y) = [0, 1 - alpha * y[2]^2, 0]
F(x) = [x[1] + x[2], x[2]^2, x[3]]
Finv(x) = [x[1] - sqrt(abs(x[2])), sqrt(abs(x[2])), x[3]]
M = [1 1; 0 2; 3 0]
L = [0.1 -beta 0; 0 -0.2 1; 1 beta 0.3]
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
clk = Clock(0., 1., 1000.)
writer1 = Writer(Bus(2))
writer2 = Writer(Bus(3))

connect(dsfolded.output, ss.input[1:2])
connect(dshenon.output, ss.input[3:5])
connect(ss.output, mem.input)
connect(mem.output, dshenon.input)
connect(dsfolded.output, writer1.input)
connect(dshenon.output, writer2.input)

model = Model(dsfolded, dshenon, ss, mem, writer1, writer2, clk=clk)

sim = simulate(model)

content1 = vcat(collect(values(read(writer1)))...)
content2 = vcat(collect(values(read(writer2)))...)
error = zeros(size(content1, 1), 3)
for k in 1 : size(error, 1)
    error[k, :] = F(content2[k, :]) - M * content1[k, :]
end
scatter(error[:, 1], label="", ms=0.25)
scatter(error[:, 2], label="", ms=0.25)
scatter(error[:, 3], label="", ms=0.25)
scatter(content1[:, 1], content1[:, 2], ms=0.25)
