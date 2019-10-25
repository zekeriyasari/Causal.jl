using Interpolations
using Plots 

t = 0.9:0.1:1
x = sin.(2pi * t)
x = exp.(2pi * t)
itpcubic = scale(interpolate(x, BSpline(Cubic(Line(OnGrid())))), t)
itplinear = scale(interpolate(x, BSpline(Linear())), t)
tt = 0.9:0.005:1.
p1 = scatter(tt, itpcubic.(tt), marker=(:circle, 1), label=:cubic)
    scatter!(tt, itplinear.(tt), marker=(:circle, 1), label=:linear)
    scatter!(t, x, marker=(:circle, 3))
display(p1)
