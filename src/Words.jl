module Words
export Word

using ..HMMSolver

abstract Word{T} <: HMMSolver.HMM{T}

end
