using Jusdl 

adder = Adder(Bus(2))
gain = Gain(Bus(), 2)
connect(adder.output, gain.input)

sub = SubSystem([adder, gain], adder.input, gain.output)
t1 = launch(sub)
t2 = launch(sub.input, [[rand() for i in 1 : 10] for j in 1 : length(adder.input)])
t3 = launch(sub.output)
