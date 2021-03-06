module ObjectPreds

export ObjectPredicate

using ..Predicates
using ..Scenes
using ..Trackers: MISSING_BOX
import ..JMain: get_score

"""
Whether a box is a certain object class
"""
immutable ObjectPredicate <: Predicate
    obj_name::Symbol
end

function get_score(p::ObjectPredicate, f::Frame, box_id::Int)
    if box_id == MISSING_BOX
        return -1000.0
    else
        if p.obj_name == :hand
            left_hand_score = get_score(ObjectPredicate(:left_hand), f, box_id)
            right_hand_score = get_score(ObjectPredicate(:right_hand), f, box_id)
            return max(left_hand_score, right_hand_score)
        else
            return f.object_scores[box_id, TRACK_MAP[string(p.obj_name)]] |> log
        end
    end
end

end
