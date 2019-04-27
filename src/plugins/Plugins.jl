# This file includes the Plugins module

@reexport module Plugins

abstract type AbstractPlugin end

# Define generic plugin functions.
function process end
function enable end
function disable end
function check end
function add end
function remove end

# Includes all the plugin files
for file in readdir(@__DIR__)
    (startswith(file, "Plugins.jl") || startswith(file, ".")) || include(file)
end

# Include user defines plugins if exists
pluginpath = joinpath(pwd(), "plugins")
if ispath(pluginpath)
    for file in readdir(pluginpath)
        filepath = joinpath(pluginpath, file)
        startswith(file, ".") || include(filepath)
        @info "Included plugin file" filepath
    end
end

end  # module