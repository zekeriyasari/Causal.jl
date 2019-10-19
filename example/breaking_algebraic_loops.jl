using Jusdl 
using Plots 


t0, dt, tf = 0, 0.01, 10.

gen = FunctionGenerator(identity)
adder = Adder(Bus(2), (+, -))
mem = Memory(Bus(1), 1, initial=rand(1))
writer1 = Writer(Bus(1))
writer2 = Writer(Bus(1))
writer3 = Writer(Bus(1))

connect(gen.output, adder.input[1])
connect(adder.output, mem.input)
connect(mem.output, adder.input[2])
connect(gen.output, writer1.input)
connect(adder.output, writer2.input)
connect(mem.output, writer3.input)

model = Model(gen, adder, mem, writer1, writer2, writer3)

sim = simulate(model, t0, dt, tf)

t, x1 = read(writer1, flatten=true)
t, x2 = read(writer2, flatten=true)
t, x3 = read(writer3, flatten=true)

plot(t, x1, label=:input)
plot!(t, x3, label=:memout)
plot!(t, x2, label=:output)
plot!(t, x1 / 2, label=:theoout)
plot!(t, abs.(x1 / 2 - x2), label=:theoout)
# plot(t[1:20], x1[1:20], markershape=:circle, label=:input)
# plot!(t[1:20], x3[1:20], markershape=:circle, label=:memout)
# plot!(t[1:20], x2[1:20], markershape=:circle, label=:output)
# plot!(t[1:20], x1[1:20] / 2, markershape=:circle, label=:theoout)
# plot!(t[1:20], abs.(x1[1:20] / 2 - x2[1:20]), markershape=:circle, label=:theoout)
