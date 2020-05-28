# This file includes intregratro construction

############################ Dynamic System integrator construction
function construct_integrator(deproblem, input, righthandside, state, t, modelargs=(), solverargs=(); 
    alg=nothing, stateder=state, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=3)
    interpolant = input === nothing ? nothing : Interpolant(numtaps, length(input))
    if deproblem == SDEProblem 
        problem = deproblem(righthandside[1], righthandside[2], state, (t, Inf), interpolant, modelargs...; 
        modelkwargs...)
    elseif deproblem == DDEProblem
        problem = deproblem(righthandside[1], state, righthandside[2], (t, Inf), interpolant, modelargs...;
         modelkwargs...)
    elseif deproblem == DAEProblem
        problem = deproblem(righthandside, stateder, state, (t, Inf), interpolant, modelargs...; 
        modelkwargs...)
    else
        problem = deproblem(righthandside, state, (t, Inf), interpolant, modelargs...; 
        modelkwargs...)
    end
    init(problem, alg, solverargs...; save_everystep=false, dense=true, solverkwargs...)
end
