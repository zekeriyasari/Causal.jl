# This file includes the Plugins module

abstract type AbstractPlugin end

# Define generic plugin functions.
function process end
function enable end
function disable end
function check end
function add end
function remove end

function search(rootpath::AbstractString, filename::AbstractString)
    paths = String[]
    for (root, dirs, files) in walkdir(rootpath)
        for file in files
            if occursin(filename, file)
                push!(paths, joinpath(root, file))
            end
        end
    end
    paths
end

const remote_repo_url = "https://imel.eee.deu.edu.tr/git/CausalPlugins.jl.git"

function add(name::AbstractString, url::AbstractString=remote_repo_url)
    startswith(name, ".") && error("Name of plugin should not start with `.`")
    startswith(name, "Plugins") && error("Name of plugin cannot be `Plugins`")
    startswith(".jl", name) || (name *= ".jl")
    
    repopath = joinpath("/tmp", "CausalPlugins", randstring())
    ispath(repopath) || mkpath(repopath)
    @info "Cloning avaliable plugins from $url"
    LibGit2.clone(url, repopath)
    @info "Done..."

    @info "Searching for $name in plugins repo."
    srcpath = search(joinpath(repopath, "src"), name)[1]
    if isempty(srcpath)
        error("$name could not be found in avaliable plugins")
    else
        dstdir = joinpath(@__DIR__, "additionals")
        dstpath = joinpath(dstdir, name)
        cp(srcpath, dstpath, force=true)
        include(dstpath)
        @info "$name is added to Causal.Plugins"
    end
end

macro def_plugin(ex)
    ex.head == :struct || 
        error("Invalid usage. The expression should start with `struct`.\n$ex")
    ex.args[2].head == :(<:) && ex.args[2].args[2] == :AbstractPlugin || 
        error("Invalid usage. The type should be a subtype of AbstractPlugin.\n$ex")
    quote 
        Base.@kwdef $ex
    end |> esc 
end


# # Includes essential plugins from Causal
# foreach(include, search(joinpath(@__DIR__, "essentials"), ".jl"))

# Includes additional plugins from Causal
foreach(include, search(joinpath(@__DIR__, "additionals"), ".jl"))

# Include plugins from user working directory.
user_plugins_path = joinpath(pwd(), "plugins")
ispath(user_plugins_path) && foreach(include, search(joinpath(user_plugins_path), ".jl"))

