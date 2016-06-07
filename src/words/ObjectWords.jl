module ObjectWords

export ObjectWord

using ..Words
using ..HMMSolver
using ..ObjectPreds
using ..Scenes
import ..JMain: get_score

type ObjectWord <: Word
    obj_name::Symbol
    scene::Scene
end

HMMSolver.get_props(::ObjectWord) = HMMProps(n_states=1)

function HMMSolver.get_initial_distribution(::ObjectWord)
    return [1.0]
end

function HMMSolver.get_transition_matrix(::ObjectWord)
    ones(1,1)
end

function HMMSolver.get_likelihood(word::ObjectWord, t, state_id, obs, box_ids)
    pred = ObjectPredicate(word.obj_name)
    frames = get(word.scene.detections)
    return get_score(pred, frames[t], box_ids[1])
end


end
