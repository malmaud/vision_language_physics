module HMMSolver

export HMM, HMMProps

using ..Util

abstract HMM{ObsT}

immutable HMMProps
    n_states::Int
end

@not_impl get_transition_matrix(::HMM)

@not_impl get_likelihood(::HMM, state_id, obs)

@not_impl get_props(::HMM)

@not_impl get_initial_distribution(::HMM)

function get_ml_path{ObsT}(hmm::HMM{ObsT}, obs::Vector{ObsT}, constraint=0)
    K = get_props(hmm).n_states
    T = length(obs)
    π = get_initial_distribution(hmm)
    T1 = Array(Float64, K, T)
    T2 = Array(Int, K, T)
    for s in 1:K
        T1[s, 1] = π[s]*get_likelihood(hmm, s, obs[1])
        T2[s, 1] = s
    end
    trans_scores = Array(Float64, K)
    A = get_transition_matrix(hmm)
    for t=2:T
        for s in 1:K
            for s2 in 1:K
                trans_scores[s2] = T1[s2, t-1] * A[s2, s] * get_likelihood(hmm, s, obs[t])
            end
            T1[s, t] = maximum(trans_scores)
            T2[s, t] = indmax(trans_scores)
        end
    end
    Z = Array(Int, T)
    if constraint==0
        Z[T] = indmax(T1[:, T])
    else
        Z[T] = constraint
    end
    for t=T:-1:2
        Z[t-1] = T2[Z[T], t]
    end
    T1, T2
    return Z
end

function score_path{ObsT}(hmm::HMM{ObsT}, states::Vector{Int}, obs::Vector{ObsT})
    s=1
    π = get_initial_distribution(hmm)
    B = get_transition_matrix(hmm)
    for t=1:length(obs)
        s *= get_likelihood(hmm, states[t], obs[t])
        if t==1
            s *= π[states[t]]
        else
            s *= B[states[t-1], states[t]]
        end
    end
    return s
end

end
