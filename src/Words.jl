module Words
export Word, @make_word, get_constraint

using ..HMMSolver
using ..Scenes
using MacroTools
using ..Util

abstract Word{T} <: HMMSolver.HMM{T}

function _make_word(arity, rest)
    works = @capture rest begin
        type TypeName_
            fields__
        end
    end
    works || error("Invalid syntax to @make_work")
    quote
        type $TypeName <: Word
            scene::Scene
            tracks::NTuple{$arity, Int}
            $(fields...)
            $TypeName() = new()
        end
        function $(esc(TypeName))(scene::Scene)
            x = $(esc(TypeName))()
            x.scene = scene
            x
        end
    end
end

macro make_word(arity, rest)
    _make_word(arity, rest)
end

@not_impl get_constraint(::Word)

end
