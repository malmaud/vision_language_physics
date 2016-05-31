module ClosePreds

export ClosePredicate

using ..Predicates
using ..Scenes

"""
Whether two tracks are "close" to each other for a non-trivial amount of time in the scene
"""
type ClosePredicate <: Predicate
end

const CLOSE_THRES = 5.0

function get_score(p::ClosePredicate, f::Frame, track1::Int, track2::Int)
    box1, box2 = f.boxes[track1], f.boxes[track2]
    distance = compute_distance(box1, box2)
    distance < CLOSE_THRES ? 1.0 : 0.0
end

end
