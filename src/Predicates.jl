module Predicates

export Predicate

using ..Util
using ..Scenes

abstract Predicate

@not_impl get_score(p::Predicate, f::Scenes.Frame, track::Int)
@not_impl get_score(p::Predicate, f::Scenes.Frame, track1::Int, track2::Int)

end
