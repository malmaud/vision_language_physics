module Sentences

export Sentence, Token

using ..Trackers
using ..Words
using ..HMMSolver
using ..Scenes
import ..JMain: get_score
import Base: parse
using ..MoveWords
using ..ObjectWords
using ..CloseWords
using PyCall
@pyimport nltk.stem.porter as porter

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


type Sentence
    words::Vector{Word}
    n_tracks::Int
    query::String
    tokens::Vector{Token}
end

Sentence() = Sentence(Word[], 0, "", Token[])

function get_score(scene::Scene, sentence::Sentence)
    trackers = Tracker[]
    hmms = HMM[]
    for agent in 1:sentence.n_tracks
        tracker = Tracker(scene)
        push!(trackers, tracker)
        push!(hmms, tracker)
    end
    for word in sentence.words
        word.scene = scene
        push!(hmms, word)
    end
    lattice = HMMSolver.HMMLattice{length(hmms)}(hmms)
    frames = get(scene.detections)
    constraints = ([get_constraint(word) for word in sentence.words]...)
    return HMMSolver.get_ml_path(lattice, zeros(length(frames)), constraints)
end



function parse(::Type{Vector{Token}}, query::String; port::Int = 5000)
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

function parse(::Type{Sentence}, query::String; kwargs...)
    tokens = parse(Vector{Token}, query; kwargs...)
    sentence =  parse(Sentence, tokens)
    sentence.tokens = tokens
    sentence.query = query
    return sentence
end

function word_for_verb(verb)
    if verb == "pick"
        word = MoveWord()
        word.dir = [0.0, 1.0]
    elseif verb == "put"
        word = MoveWord()
        word.dir = [0.0, -1.0]
    end
    return word
end

function parse(::Type{Sentence}, tokens::Vector{Token}, cur_token_id=0, my_track=0, sentence=Sentence())
    if cur_token_id == 0
        cur_token_id = findfirst([token.head==0 for token in tokens])
    end
    cur_token = tokens[cur_token_id]
    name_map = Dict("person"=>:left_hand, "monkey"=>:monkey, "rat"=>:rat, "car"=>:car, "bottle"=>:bottle, "jug"=>:bottle)
    stemmer = porter.PorterStemmer()
    stemmed_word = stemmer[:stem](cur_token.word)
    const transitive_verbs = ["pick", "put"]
    if stemmed_word ∈ transitive_verbs
        agent = sentence.n_tracks + 1
        patient = sentence.n_tracks + 2
        word = word_for_verb(stemmed_word)
        # word = MoveWord()
        # word.dir = [0.0, 1.0]
        word.tracks = (agent, patient)
        push!(sentence.words, word)
        sentence.n_tracks += 2
        for (idx, token) in enumerate(tokens)
            if token.head == cur_token_id
                if token.label == "dobj"
                    parse(Sentence, tokens, idx, patient, sentence)
                elseif token.label == "nsubj"
                    parse(Sentence, tokens, idx, agent, sentence)
                end
            end
        end
    elseif stemmed_word == "close"
        agent = sentence.n_tracks + 1
        patient = sentence.n_tracks + 2
        sentence.n_tracks += 2
        word = CloseWord()
        word.tracks = (agent, patient)
        push!(sentence.words, word)
        for (idx, token) in enumerate(tokens)
            if token.head == cur_token_id
                if token.label == "nsubj"
                    parse(Sentence, tokens, idx, agent, sentence)
                elseif token.label == "prep" && token.word == "to"
                    for (idx2, token2) in enumerate(tokens)
                        if token2.head == idx
                            if token2.label == "pobj"
                                parse(Sentence, tokens, idx2, patient, sentence)
                            end
                        end
                    end
                end
            end
        end
    elseif stemmed_word ∈ keys(name_map)
        if my_track == 0
            my_track = sentence.n_tracks + 1
            sentence.n_tracks += 1
        end
        word = ObjectWord()
        word.obj_name = name_map[stemmed_word]
        word.tracks = (my_track,)
        push!(sentence.words, word)
    else
        for (idx, token) in enumerate(tokens)
            if token.head == cur_token_id
                parse(Sentence, tokens, idx, my_track, sentence)
            end
        end
    end
    return sentence
end

end
