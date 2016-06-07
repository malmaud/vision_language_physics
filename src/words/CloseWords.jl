module CloseWords

export CloseWord

using ..Words
using ..HMMSolver
using ..Scenes
using ..ClosePreds
using ..JMain: get_score

"""
Whether two objects are close to each other for a non-trivial amount of time
in the scene.

eg, "The hand is close to the monkey."
"""
type CloseWord <: Word{Symbol}
    scene::Scene
end

const F0=1  # Haven't been close yet
const F1=2  # Have been close on this frame
const P=3  # Have been close at least one frame in the video so far

HMMSolver.get_props(::CloseWord) = HMMProps(n_states=3)

function HMMSolver.get_initial_distribution(word::CloseWord)
    return [1.0, 0.0, 0.0]
end

function HMMSolver.get_transition_matrix(word::CloseWord)
    return [0.5 0.5 0; 0 0 1; 0 0 1]
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
        score = get_score(pred, frames[t], box_ids[1], box_ids[2])
    end
    if box_ids[1]==box_ids[2]
        return 0.0
    end
    if state_id==1
        if t==1 && score==1
            return 1.0
        else
            return 1-score
        end
    elseif state_id==2
        return score
    else
        return 1.0
    end
end




end
