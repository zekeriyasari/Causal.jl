using Jusdl 
using IntervalArithmetic, IntervalRootFinding, StaticArrays

model = Model()
model[:gen] = FunctionGenerator(sin)
model[:adder] = Adder(Inport(2), (+,-))
model[:gain] = Gain(Inport())
model[:gen => :adder] = Edge(1 => 1)
model[:adder => :gain] = Edge()
model[:gain => :adder] = Edge(1 => 2)

loops = getloops(model)
loop = loops[1]
@enter Jusdl.breakloop(model, loop)

f(x) = SVector(
    x[1] - 1,
    x[2] - 2
    )

X = -Inf..Inf 
rts = roots(f, IntervalBox(fill(X, 2)))

mid(interval(rts[findfirst(rt -> rt.status == :unique, rts)]))
 