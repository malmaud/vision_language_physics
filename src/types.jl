immutable Point
    x::Int
    y::Int
end

immutable Detection
    ul::Point
    lr::Point
    score::Float64
    class::Symbol
end

immutable FrameDetection
    detections::Vector{Detection}
end

immutable DetectorResult
    frames::Vector{FrameDetection}
end

immutable Track
    detection_ids::Vector{Int}
end

abstract Word
abstract Predicate

immutable FarPredicate <: Predicate
end

immutable ClosePredicate <: Predicate
end

immutable StationaryPredicate <: Predicate
end

immutable StationaryButFarPredicate <: Predicate
end

immutable LeftOfPredicate <: Predicate
end

immutable PredParams
    far::Float64
    close::Float64
    pp::Float64
end

immutable FromLeftWord <: Word
end
