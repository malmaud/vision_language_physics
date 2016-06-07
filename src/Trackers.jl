module Trackers

export Tracker

using ..HMMSolver
using ..Scenes

immutable Tracker <: HMM
    scene::Scene
end

const MAX_BOXES = 4

max_boxes() = MAX_BOXES

function HMMSolver.get_initial_distribution(::Tracker)
    N = max_boxes()
    return [1/N for n in 1:N]
end

function sigmoid(t, a, β)
    return 1./(1+exp(-β*(t-a)))
end

function motion_coherence(box1::Box, box2::Box)
    return sigmoid(compute_distance(box1, box2), 50.0, -1/11)
end

function HMMSolver.get_transition_matrix(tracker::Tracker, t)
    scene = tracker.scene
    frames = get(scene.detections)
    N_prev = length(frames[t].boxes)
    if t==length(frames)
        N_next = N_prev
    else
        N_next = length(frames[t+1].boxes)
    end
    N = max_boxes()
    A = zeros(N, N)
    for row in 1:N_prev
        for col in 1:N_next
            if t==length(frames)
                A[row, col] = 1/N_next
            else
                box1 = frames[t].boxes[row]
                box2 = frames[t+1].boxes[col]  # TODO use optical flow instead
                A[row, col] = motion_coherence(box1, box2)
            end
        end
    end
    return A
end

function HMMSolver.get_likelihood(tracker::Tracker, t, state, obs)
    scene = tracker.scene
    frames = get(scene.detections)
    scores = frames[t].object_scores
    state > size(scores, 1) && return 0.0
    return maximum(scores[state, :])
end

function HMMSolver.get_props(::Tracker)
    HMMProps(n_states=max_boxes())
end

end
