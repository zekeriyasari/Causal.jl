using Plots

theme(:default)
default()
plt1 = plot(rand(1000), size=(500, 300), xtickfont = font(10), ytickfont = font(10))
# savefig(plt1, "/home/sari/Desktop/workingdirectory/myimage.svg")
