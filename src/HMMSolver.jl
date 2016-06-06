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

immutable HMMLattice <: HMM
    hmms::Vector{HMM}
end

get_props(hmm::HMMLattice) = HMMProps(prod(map(x->get_props(x).n_states, hmm.hmms)))

function get_initial_distribution(hmm::HMMLattice)
    n_states = map(x->get_props(x).n_states, hmm.hmms)
    N = prod(n_states)
    π_net = zeros(Float64, N)
    π = map(get_initial_distribution, hmm.hmms)
    i = 1
    state_idx = 1
    for state in CartesianRange((n_states...))
        π_net[state_idx] = 1.0
        for j in 1:length(state)
            state_j = state[j]
            π_net[state_idx] *= π[j][state_j]
        end
        state_idx+=1
    end
    return π_net
end

function get_transition_matrix(hmm::HMMLattice)
    n_states = (map(x->get_props(x).n_states, hmm.hmms)...)
    N = prod(n_states)
    A_net = zeros(Float64, N, N)
    A = map(get_transition_matrix, hmm.hmms)
    row_idx = 1
    col_idx = 1
    for state1 in CartesianRange(n_states)
        col_idx = 1
        for state2 in CartesianRange(n_states)
            A_net[row_idx, col_idx] = 1.0
            for i in 1:length(state1)
                state1_idx = state1[i]
                state2_idx = state2[i]
                A_net[row_idx, col_idx] *= A[i][state1_idx, state2_idx]
            end
            col_idx += 1
        end
        row_idx += 1
    end
    return A_net
end

function get_likelihood(hmms::HMMLattice, state_id, obs)
    n_states = (map(x->get_props(x).n_states, hmms.hmms)...)
    state_ids = ind2sub(n_states, state_id)
    lh = 1.0
    for (hmm, state_id) in zip(hmms.hmms, state_ids)
        lh *= get_likelihood(hmm, state_id, obs)
    end
    return lh
    # lhs = map((hmm, state_id)->get_likelihood(hmm, state_id), zip(hmms.hmms, n_states))
    # mapreduce((hmm, state_id)->get_likelihood(hmm, state_id), *, zip(hmms.hmms, state_ids))
    # return prod(lhs)
end

function get_ml_path(hmm::HMM, obs::Vector, constraint=0)
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
    if constraint == 0
        Z[T] = indmax(T1[:, T])
    else
        Z[T] = constraint
    end
    for t in T:-1:2
        Z[t-1] = T2[Z[T], t]
    end
    return Z
end

function get_ml_path(lattice::HMMLattice, obs::Vector, constraint=0)
    Z_ind = invoke(get_ml_path, (HMM, Vector, Int), lattice, obs, constraint)
    Z_sub = Vector{NTuple{length(lattice.hmms), Int}}(length(Z_ind))
    n_states = (map(x->get_props(x).n_states, lattice.hmms)...)
    N = prod(n_states)
    for i in 1:length(Z_ind)
        Z_sub[i] = ind2sub(n_states, Z_ind[i])
    end
    return Z_sub
end

function score_path(hmm::HMM, states::Vector{Int}, obs::Vector)
    s = 1.0
    π = get_initial_distribution(hmm)
    B = get_transition_matrix(hmm)
    for t in 1:length(obs)
        s *= get_likelihood(hmm, states[t], obs[t])
        if t == 1
            s *= π[states[t]]
        else
            s *= B[states[t-1], states[t]]
        end
    end
    return s
end

end
