"""
Entry point for loading all files.
"""
module JMain

"""
Generic function which generally returns a value between 0 and 1 indicate how compatible its arguments are.
"""
function get_score
end

include("Util.jl")
include("Scenes.jl")
include("HMMSolver.jl")
include("Trackers.jl")
include("Predicates.jl")
include("Words.jl")

function load_folder(folder_name)
    word_path = joinpath(dirname(@__FILE__), folder_name)
    for word_file in filter(file->ismatch(r"jl$", file), readdir(word_path))
        include(joinpath(word_path, word_file))
    end
end

foreach(load_folder, ["predicates", "words"])

end
