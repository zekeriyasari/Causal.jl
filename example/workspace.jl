using Jusdl 
using LightGraphs, MetaGraphs

model = Model()
addcomponent(model, FunctionGenerator(sin, name=:gen))
addcomponent(model, Adder(Inport(2), (+, -), name=:adder))
addcomponent(model, Gain(Inport(), name=:gain))
addconnection(model, :gen, :adder, 1, 1)
addconnection(model, :adder, :gain)
addconnection(model, :gain, :adder, 1, 2)
graph = model.graph

# Detect algrebraic loops
loops = simplecycles(graph)
loop = loops[1]
vertexfuncs = loopvertexfuncs(model, loop)

