using Jusdl 
using Plots; pyplot()

model = Model(clock=Clock(0, 0.01, 5)) 
model[:gen] = SinewaveGenerator() 
model[:mem] = Memory(0.01)
model[:writer] = Writer()
model[:gen => :mem] = Edge(1 => 1) 
model[:mem => :writer] = Edge(1 => 1) 
simulate(model) 

t, x = read(model[:writer].component)
plot(t, x)

# mem = Memory() 
# op = Outport() 
# tr = Outpin() 
# hn = Inpin{Bool}() 
# connect(op, mem.input)
# connect(tr, mem.trigger) 
# connect(mem.handshake, hn)
# t = launch(mem)
# put!(tr, 1.)
# t
# put!(op, [10.])
# t
# take!(hn)
# t
# put!(tr, 2.)
# t
# put!(op, [20.])
# t
# take!(hn)
# t
