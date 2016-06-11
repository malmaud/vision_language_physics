module ObjectWords

export ObjectWord

using ..Words
using ..HMMSolver
using ..ObjectPreds
using ..Scenes
import ..JMain: get_score

@make_word 1 type ObjectWord
    obj_name::Symbol
end

HMMSolver.get_props(::ObjectWord) = HMMProps(n_states=1)

function HMMSolver.get_initial_distribution(::ObjectWord)
    return log([1.0])
end

function HMMSolver.get_transition_matrix!(A::Matrix{Float64}, ::ObjectWord)
    A[1] = log(1.0)
    return A
end

function HMMSolver.get_likelihood(word::ObjectWord, t, state_id, obs, box_ids)
    pred = ObjectPredicate(word.obj_name)
    frames = get(word.scene.detections)
    return get_score(pred, frames[t], box_ids[word.tracks[1]])
end

Words.get_constraint(::ObjectWord) = 1

end
