module ClosePreds

export ClosePredicate

using ..Predicates
using ..Scenes
import ..JMain: get_score

"""
Whether two boxes are "close" to each other.
"""
type ClosePredicate <: Predicate
end

const CLOSE_THRES = 250

function get_score(p::ClosePredicate, f::Frame, box1_id::Int, box2_id::Int)
    if box1_id > length(f.boxes) || box2_id > length(f.boxes) || box1_id==box2_id
        return 0.0
    end
    box1, box2 = f.boxes[box1_id], f.boxes[box2_id]
    distance = compute_distance(box1, box2)
    distance < CLOSE_THRES ? 1.0 : 0.0
end

end
