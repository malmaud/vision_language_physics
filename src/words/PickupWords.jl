module PickupWords

export PickupWord

using ..Words
using ..HMMSolver
using ..Scenes
using ..ClosePreds
using ..DirectionPreds
using ..JMain: get_score

@make_word 2 type PickupWord
end

const F0=1
const F1=2
const F2=3
const F3=4
const P=5

Words.get_constraint(::PickupWord) = 5
HMMSolver.get_props(::PickupWord) = HMMProps(n_states=5)

function HMMSolver.get_initial_distribution(word::PickupWord)
    return log(Float64[1, 0, 0, 0, 0])
end

function HMMSolver.get_transition_matrix!(A::Matrix{Float64}, word::PickupWord)
    A[:] = log(Float64[.5 .5 0 0 0;.5 0 .5 0 0;.5 0 0 .5 0;.5 0 0 0 .5;0 0 0 0 1])
end

function HMMSolver.get_likelihood(word::PickupWord, t, state_id, obs, box_ids)
    close_pred = ClosePredicate()
    up_pred = DirectionPredicate([0.0, -1.0])
    frame = get(word.scene.detections)[t]
    agent, patient = word.tracks
    score = get_score(close_pred, frame, box_ids[agent], box_ids[patient]) *
            get_score(up_pred, frame, box_ids[2])
    score = log(score)
    if state_id == F0
        return log(.5)
    elseif state_id ∈ F1:F3
        return score
    elseif state_id == P
        return log(.5)
    end
end

end
