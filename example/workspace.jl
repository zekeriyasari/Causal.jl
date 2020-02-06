using Jusdl 

clk = Clock(0., 1., 10.)
set!(clk)
@show [take!(clk) for i = 0 : 10]

clk = Clock(0., 1., 10.)
set!(clk)
for t in clk 
    @show t
end

clk = Clock(0., 1., 10.)
set!(clk)
vals = []
for t in clk 
    @show t
    push!(vals, t)
end
@show vals

chnl = Channel() do ch
    foreach(i -> put!(ch, i), 1:4)
end;

vals = [take!(chnl) for i = 1 : 4]
@show vals
