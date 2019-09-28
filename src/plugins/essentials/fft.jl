# This file includes the plugin for calculation of fast fourier transform of data
using FFTW

struct Fft <: AbstractPlugin 
    dims::Int
end 
Fft(;dims=1) = Fft(dims)

show(io::IO, plg::Fft) = print(io, "Fft(dims:$(plg.dims))")

process(plg::Fft, x) = fft(x, plg.dims)
