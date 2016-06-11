module Trackers

export Tracker

using ..HMMSolver
using ..Scenes
using ..Util

immutable Tracker <: HMM
    scene::Scene
end

const MAX_BOXES = 5
const MISSING_BOX=MAX_BOXES

max_boxes() = MAX_BOXES

function HMMSolver.get_initial_distribution(::Tracker)
    N = max_boxes()
    return log([1/N for n in 1:N])
end

function sigmoid(t, a, β)
    return 1./(1+exp(-β*(t-a)))
end

function motion_coherence(box1::Box, box2::Box)
    return sigmoid(compute_distance(box1, box2), 50.0, -1/11)
end

function HMMSolver.get_transition_matrix!(A, tracker::Tracker, t)
    scene = tracker.scene
    frames = get(scene.detections)
    N_prev = length(frames[t].boxes)
    if t==length(frames)
        N_next = N_prev
    else
        N_next = length(frames[t+1].boxes)
    end
    N = max_boxes()
    A[:] = 0.0
    # A = zeros(N, N)
    for row in 1:N_prev
        for col in 1:N_next
            if t==length(frames)
                A[row, col] = log(1/N_next)
            else
                if row == MAX_BOXES && col == MAX_BOXES
                    A[row, col] = 0.0
                elseif row == MAX_BOXES || col == MAX_BOXES
                    A[row, col] = -1000.0
                else
                    box1 = frames[t].boxes[row]
                    box2 = frames[t+1].boxes[col]  # TODO use optical flow instead
                    # flow = frames[t].optical_flows[row, :]

                    A[row, col] = motion_coherence(box1, box2)
                end
            end
        end
    end
    # A[:] = log(A./sum(A,2))
    for row in 1:size(A,1)
        A[row, :] = A[row, :] - logsumexp(A[row, :])
    end
    return A
end

function HMMSolver.get_likelihood(tracker::Tracker, t, state, obs)
    if state == MAX_BOXES
        return -1000.0
    end
    scene = tracker.scene
    frames = get(scene.detections)
    scores = frames[t].object_scores
    state > size(scores, 1) && return 0.0
    return maximum(scores[state, :]) |> log
end

function HMMSolver.get_props(::Tracker)
    HMMProps(n_states=max_boxes())
end

end
