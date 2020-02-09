# using ChaosTools

# ntype = FixedMassNeighborhood(5)
# dt = 0.05
# x = rand(20001)
# ks2 = 0:4:200
# D = 3 
# τ = 7
# r = reconstruct(x, D, τ)
# E2 = numericallyapunov(r, ks2; ntype = ntype)
# λ2 = linear_region(ks2 .* dt, E2)[2]

using Jusdl 
using Plots 
import Jusdl.Plugins: Lyapunov

writer = Writer(Bus(1), buflen=5000, plugin=Lyapunov())
open(writer)
t  = launch(writer)
for t in 1 : 10000
    drive(writer, t)
    put!(writer.input, [t])
    approve(writer)
end
close(writer)
