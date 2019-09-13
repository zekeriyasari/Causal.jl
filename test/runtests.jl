# This file includes the main test set of JuSDL. 
# To include new tests, write your tests in files and save them under `test` directory.

using Test
using JuSDL


# Construct the file tree in `test` directory.
filetree = walkdir(@__DIR__)
take!(filetree) # Pop the root directory `test` in which `runtests.jl` is.

# Include all test files under `test`
@time @testset "JuSDLTestSet" begin
    for (root, dirs, files) in filetree
        foreach(file -> include(joinpath(root, file)), files)
    end
end
