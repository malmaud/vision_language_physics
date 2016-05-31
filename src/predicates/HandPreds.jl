module HandPreds

export HandPredicate

using ..Predicates
using ..Scenes

"""
Determines if the track is a hand
"""
type HandPredicate <: Predicate
end

function get_score(p::HandPredicate, f::Frame, track::Int)
    # We manually assign hands to track 1 or 2 earlier in the processing pipeline
    (track ∈ [1, 2]) ? 1.0 : 0.0
end

end
