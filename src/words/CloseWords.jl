module CloseWords

export CloseWord

using ..Words
using ..HMMSolver

type CloseWord <: Word{Symbol}
end

const F0=1
const F1=2
const P=3

HMMSolver.get_props(::CloseWord) = HMMProps(3)

function HMMSolver.get_transition_matrix(::CloseWord)
    return Float64[1 1 0; 0 0 1; 0 0 1;]
end

function HMMSolver.get_initial_distribution(::CloseWord)
    return Float64[1, 0, 0]
end

function HMMSolver.get_likelihood(::CloseWord, state_id, obs::Symbol)
    if obs==:CLOSE
        return Float64[0, 1, 1][state_id]
    elseif obs==:NOT_CLOSE
        return Float64[1, 0, 1][state_id]
    end
end

y=HMMSolver.get_ml_path(CloseWord(), [:NOT_CLOSE, :NOT_CLOSE, :NOT_CLOSE, :NOT_CLOSE], 3)

HMMSolver.score_path(CloseWord(), y, [:NOT_CLOSE, :NOT_CLOSE, :CLOSE, :NOT_CLOSE])

end
