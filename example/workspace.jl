using Jusdl 

ofunc(u, t) = u[1] + u[2]
ss = StaticSystem(ofunc, Bus(2), Bus(1))
gen1 = SinewaveGenerator()
gen2 = SinewaveGenerator()

sub = Subsystem([gen1, gen2, ss], nothing, ss.output)



