module Visualizer

try
    using PyPlot
    import PyPlot: plot
end
using ..HMMSolver
using ..Scenes
using ..Sentences
using ..Words

function plot(scene::Scene, result::ViterbiResult, sentence::Sentence)
    for (frame_id, state) in enumerate(result.path)
        if state[3] == Words.get_constraint(sentence.words[1])-1
            plot(scene, frame_id, show_boxes=false, show_flow=true)
            frame = get(scene.detections)[frame_id]
            for (box_id, box) in enumerate(frame.boxes)
                if box_id == state[1]
                    plot(box, 1)
                elseif box_id == state[2]
                    plot(box, 2)
                end
            end
            break
        end
    end
end


end
