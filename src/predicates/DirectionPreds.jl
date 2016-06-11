module DirectionPreds

export DirectionPredicate

using ..Predicates
using ..Scenes
import ..JMain: get_score

immutable DirectionPredicate <: Predicate
    dir::Vector{Float64}
end

const THRESHOLD = .75


function get_score(p::DirectionPredicate, f::Frame, box_id::Int)
    flow = f.optical_flows[box_id, :]
    proj = dot(flow, p.dir)
    score = proj > THRESHOLD ? 1.0 : 0.0
    return score
end

end
