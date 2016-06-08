module Sentences

using ..Trackers
using ..Words
using ..HMMSolver
using ..Scenes
import ..JMain: get_score

type Sentence
    words::Vector{Word}
    n_agents::Int
end

Sentence() = Sentence(Word[], 0)

function get_score(scene::Scene, sentence::Sentence)
    trackers = Tracker[]
    hmms = HMM[]
    for agent in 1:sentence.n_agents
        tracker = Tracker(scene)
        push!(trackers, tracker)
        push!(hmms, tracker)
    end
    for word in sentence.words
        word.scene = scene
        push!(hmms, word)
    end
    lattice = HMMSolver.HMMLattice(hmms)
    frames = get(scene.detections)
    constraints = ([get_constraint(word) for word in sentence.words]...)
    return HMMSolver.get_ml_path(lattice, zeros(length(frames)), constraints)
end

@enum BreakLevel NO_BREAK SPACE_BREAK LINE_BREAK SENTENCE_BREAK

immutable Token
    word::String
    start_pos::Int
    end_pos::Int
    head::Int
    tag::String
    category::String
    label::String
    break_level::BreakLevel
end


function Base.parse(::Type{Sentence}, query::String; port = 5000)
    sentence = Sentence()
    socket = connect(port)
    write(socket, length(query.data))
    write(socket, query.data)
    N = read(socket, Int)
    msg = read(socket, N)
    data = readcsv(IOBuffer(String(msg)))
    tokens = Token[]
    for row_idx in 1:size(data, 1)
        row = data[row_idx, :]
        token = Token(row[1], row[2]+1, row[3]+1, row[4]+1, row[5], row[6], row[7], BreakLevel(row[8]))
        push!(tokens, token)
    end
    return tokens
end



end
