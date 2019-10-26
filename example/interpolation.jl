using Interpolations
using Plots 

# t = 0.:0.1:1
# x = sin.(2pi * t)
# itpcubic = scale(interpolate(x, BSpline(Cubic(Line(OnGrid())))), t)
# itpquadratic = scale(interpolate(x, BSpline(Quadratic(Line(OnGrid())))), t)
# itplinear = scale(interpolate(x, BSpline(Linear())), t)
# tt = 0.:0.005:1.
# ni = 40
# nf = 60
# p1 = scatter(tt[ni:nf], itpcubic.(tt)[ni:nf], marker=(:circle, 1), label=:cubic)
#     scatter!(tt[ni:nf], itpquadratic.(tt)[ni:nf], marker=(:circle, 1), label=:quadratic)
#     scatter!(tt[ni:nf], itplinear.(tt)[ni:nf], marker=(:circle, 1), label=:linear)
#     scatter!(t, x, marker=(:circle, 3), label=:interpolationdata)
# display(p1)


t = 0. : 1.: 2.
x = rand(length(t))
scatter(t, x, marker=(1))
itpcubic = scale(interpolate(x, BSpline(Cubic(Line(OnGrid())))), t)
itpquadratic = scale(interpolate(x, BSpline(Quadratic(Line(OnGrid())))), t)
itplinear = scale(interpolate(x, BSpline(Linear())), t)
tt = t[1]:0.01:t[end]
p1 = scatter(tt, itpcubic.(tt), marker=(:circle, 1), label=:cubic)
    scatter!(tt, itpquadratic.(tt), marker=(:circle, 1), label=:quadratic)
    scatter!(tt, itplinear.(tt), marker=(:circle, 1), label=:linear)
    scatter!(t, x, marker=(:circle, 3), label=:interpolationdata)
display(p1)
