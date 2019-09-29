
using Jusdl 

gen = SinewaveGenerator(1., 1. / 0.64)
scope = Scope(Bus())

connect(gen.output, scope.input)
model = Model(gen, scope)

sim = simulate(model, 0., 0.01, 100.)
