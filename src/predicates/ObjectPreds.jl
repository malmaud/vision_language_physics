module ObjectPreds

export ObjectPredicate

using ..Predicates
using ..Scenes

"""
Whether a track is a certain object class
"""
immutable ObjectPredicate <: Predicate
    obj_name::Symbol
end

function get_score(p::ObjectPredicate, f::Frame, track::Int)
    box_id = findfirst(f.track_ids==track)
    return f.object_scores[box_id, TRACK_MAP[String(p.obj_name)]]
    # if track == TRACK_MAP[String(p.obj_name)]
    #     return 1.0
    # else
    #     return 0.0
    # end
end

end
