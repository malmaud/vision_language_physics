immutable Point
    x::Int
    y::Int
end

immutable Box
    top_left::Point
    bottom_right::Point
end

center(b::Box) = Point((b.top_left.x+b.bottom_right.x)//2, (b.bottom_right.y+b.top_left.y)//2)
compute_distance(b1::Box, b2::Box) = compute_distance(center(b1), center(b2))

function compute_distance(p1::Point, p2::Point)
    return sqrt((p1.x-p2.x)^2 + (p1.y-p2.y)^2)
end

immutable VideoData
    color::Array{Float64, 4}
    depth::Array{Float64, 3}
    detections::Vector{Vector{Box}}
    scores::Vector{Matrix{Float64}}
end

const MONKEY_DETECTOR=1

typealias Detections Vector{Vector{Box}}

abstract Predicate
abstract Word

immutable IsMonkey <: Predicate
end

immutable IsHand <: Predicate
end

immutable IsPickUp <: Predicate
end

immutable IsTrue <: Predicate
end

immutable IsNear <: Predicate
end

immutable MonkeyWord <: Word
end

immutable HandWord <: Word
end

immutable PickupWord <: Word
end

const PredicateList = [IsMonkey(), IsHand(), IsPickUp()]
const WordList = [MonkeyWord(), HandWord(), PickupWord()]


#compute_score(p::Predicate, box::Box, data::VideoData)
#compute_score(p::Predicate, box1::Box, box2::Box, data::VideoData)
#lookup_predicate(w::Word, state::Int)
#compute_score(w::Word, state::Int, box::Box, data::VideoData)
#compute_score(w::Word, state1::Int, state2::Int, data::VideoData)

get_predicate(::MonkeyWord, state_id) = IsMonkey()

function compute_score(::IsMonkey, frame_id, detection_id, data)
    scores = data.scores
    return scores[frame_id][detection_id, MONKEY_DETECTOR]  # todo normalize
end

compute_score(::IsTrue, frame_id, detection_id, data) = 0.0

function compute_score(::IsNear, frame_id, detection_id_1, detection_id_2, data)
    box1 = data.detections[frame_id][detection_id_1]
    box2 = data.detections[frame_id][detection_id_2]
    distance = compute_distance(box1, box2)
    return distance
end

function get_predicate(::PickupWord, state_id)
    if state_id==1
        return IsTrue()
    elseif state_id==2
        return IsNear()
    elseif state_id==3
        return IsTrue()
    end
end

function compute_score(word::Word, state_id, frame_id, detection_id, data)
    predicate = get_predicate(word, state_id)
    return compute_score(predicate, frame_id, detection_id, data)
end

compute_score(::Word, state1::Int, state2::Int) = 0.0

const AGENT_TRACK = 1
const PATIENT_TRACK = 2

function compute_score(J::Matrix{Int}, K::Matrix{Int}, track_map::Matrix{Int}, data::VideoData)
    score = 0.0
    for word_id in 1:sizeof(K, 1)
        track_id_1, track_id_2 = track_map[word_id, 1], track_map[word_id, 2]
        for frame_id in 1:sizeof(K, 2)
            state_id = K[word_id, frame_id]
            if track_id_2 == 0
                detection_id_1 = J[track_id_1, frame_id]
                score += compute_score(WordList[word_id], state_id, frame_id, detection_id_1, data)
            else
                detection_id_1 = J[track_id_1, frame_id]
                detection_id_2 = J[track_id_2, frame_id]
                score += compute_score(WordList[word_id], state_id, frame_id, detection_id_1, detection_id_2, data)
            end
            if frame_id > 1
                score += compute_score(WordList[word_id], K[word_id, frame_id-1], state_id)
            end
        end
    end
    return score
end

function optimize_score(J, track_map, data)
    
end
