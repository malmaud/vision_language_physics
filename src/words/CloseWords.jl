"""
Whether two objects are close to each other for a non-trivial amount of time
in the scene.

eg, "The hand is close to the monkey."
"""
module CloseWords

export CloseWord

using ..Words
using ..HMMSolver
using ..Scenes
using ..ClosePreds
using ..JMain: get_score


# type CloseWord <: Word{Symbol}
#     scene::Scene
# end

@make_word 2 type CloseWord

end

const F0=1  # Haven't been close yet
const F1=2  # Have been close on this frame
const F2=3
const F3=4
const P=5  # Have been close at least one frame in the video so far

HMMSolver.get_props(::CloseWord) = HMMProps(n_states=5)

function HMMSolver.get_initial_distribution(word::CloseWord)
    return log([1.0, 0.0, 0.0, 0.0, 0.0])
end

function HMMSolver.get_transition_matrix!(A::Matrix{Float64}, word::CloseWord)
    A[:] = log([0.5 0.5 0 0 0; .5 0 .5 0 0; .5 0 0 .5 0; .5 0 0 0 .5; 0 0 0 0 1])
    return A
end

function HMMSolver.get_likelihood(word::CloseWord, t, state_id, obs, box_ids)
    pred = ClosePredicate()
    frames = get(word.scene.detections)
    if length(box_ids)<3
        score = -Inf
        for box_ids in CartesianRange((length(frames[t].boxes), length(frames[t].boxes)))
            if box_ids[1]==box_ids[2]
                continue
            end
            score = max(score, get_score(pred, frames[t], box_ids[1], box_ids[2]))
        end
    else
        score = get_score(pred, frames[t], box_ids[word.tracks[1]], box_ids[word.tracks[2]]) |> log
    end
    if box_ids[1]==box_ids[2]
        score =  -Inf
    end
    if state_id == F0
        if t==1 && score==1
            return log(1.0)
        else
            return log(1-exp(score))  # 1-P
        end
    elseif state_id ∈ F1:F3
        return score
    else  # state_id == P
        return 0.0
    end
end

Words.get_constraint(::CloseWord) = 5




end
