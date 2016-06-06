using .HMMSolver
using Base.Test

type HealthHMM <: HMMSolver.HMM
end

function HMMSolver.get_initial_distribution(::HealthHMM)
    Float64[.6, .4]
end

function HMMSolver.get_transition_matrix(::HealthHMM)
    Float64[.7 .3; .4 .6]
end

function HMMSolver.get_props(::HealthHMM)
    return HMMProps(2)
end

function HMMSolver.get_likelihood(::HealthHMM, state_id, obs)
    O = Float64[.5 .4 .1; .1 .3 .6]
    O[state_id, obs]
end

@test HMMSolver.get_ml_path(HealthHMM(), [1, 2, 3]) == [1, 1, 2]

lattice = HMMSolver.HMMLattice([HealthHMM()])

HMMSolver.get_ml_path(lattice, [1,2,3])
