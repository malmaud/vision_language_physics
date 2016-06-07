module ObjectPreds

export ObjectPredicate

using ..Predicates
using ..Scenes
import ..JMain: get_score

"""
Whether a track is a certain object class
"""
immutable ObjectPredicate <: Predicate
    obj_name::Symbol
end

function get_score(p::ObjectPredicate, f::Frame, box_id::Int)
    return f.object_scores[box_id, TRACK_MAP[string(p.obj_name)]]
    # if track == TRACK_MAP[String(p.obj_name)]
    #     return 1.0
    # else
    #     return 0.0
    # end
end

end
