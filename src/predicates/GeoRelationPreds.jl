module GeoRelationPreds

export GeoRelationPredicate

using ..Predicates
using ..Scenes
import ..JMain: get_score

@enum Relation Above Below Right Left

immutable GeoRelationPredicate <: Predicate
    relation::Relation
end

function get_score(p::GeoRelationPredicate, f::Frame, box_id_1::Int, box_id_2::Int)
    rel = p.relation
    N = length(f.boxes)
    if box_id_1 > N || box_id_2 > N || box_id_1 == box_id_2
        return 0.0
    end
    box1 = f.boxes[box_id_1]
    box2 = f.boxes[box_id_2]
    if rel == Above
        box1.top_left.y < box2.top_left.y && return 1.0
    end
    return 0.0
end

end
