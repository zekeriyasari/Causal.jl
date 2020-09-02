# This file includes an example usage of Interpolants 

using Causal
using Plots 

# Construct and interpolant 
interp = Interpolant(Buffer(5), Buffer(Vector{Float64}, 5))

# Write some initialization data to interpolation buffers
foreach(t -> (write!(interp.timebuf, t); write!(interp.databuf, [cos(t), sin(t)])), [0., 1.])
update!(interp)

# Plots
tr = 2. : 10.
plt = plot(layout=length(tr)) 
for (i, ti) in enumerate(tr)
    tc = content(interp.timebuf)
    tv = collect(range(tc[1], tc[end], length=100))
    plot!(tv, interp[1].(tv), label="icos", subplot=i)
    plot!(tv, cos.(tv), label="cos", subplot=i)
    plot!(tv, interp[2].(tv), label="isin", subplot=i)
    plot!(tv, sin.(tv), label="sin", subplot=i)

    write!(interp.timebuf, ti) 
    write!(interp.databuf, [cos(ti), sin(ti)])
    update!(interp)
end
plt
