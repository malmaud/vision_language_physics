module HMMSolver

export HMM, HMMProps

using ..Util
using NumericFuns

abstract HMM{ObsT}

immutable HMMProps
    n_states::Int
end

HMMProps(;n_states=0) = HMMProps(n_states)

@not_impl get_transition_matrix!(A::Matrix{Float64}, ::HMM)

@not_impl get_likelihood(::HMM, state_id, obs)

@not_impl get_props(::HMM)

@not_impl get_initial_distribution(::HMM)

get_transition_matrix!(A, hmm::HMM, t) = get_transition_matrix!(A, hmm)
get_likelihood(hmm::HMM, t, state, obs) = get_likelihood(hmm, state, obs)
get_likelihood(hmm::HMM, t, state, obs, lattice_states) = get_likelihood(hmm, t, state, obs)

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
            π_net[state_idx] += π[j][state_j]
        end
        state_idx+=1
    end
    return π_net
end


function get_transition_matrix!(A_net::Matrix{Float64}, hmm::HMMLattice, t)
    n_states = (map(x->get_props(x).n_states, hmm.hmms)...)
    N = prod(n_states)
    # A = map(hmm->get_transition_matrix(hmm, t), hmm.hmms)
    A = Matrix{Float64}[]
    for h in hmm.hmms  # TODO avoid doing this step every iteration
        N_hmm = get_props(h).n_states
        push!(A, zeros(N_hmm, N_hmm))
        get_transition_matrix!(A[end], h, t)
    end
    row_idx = 1
    col_idx = 1
    for state1 in CartesianRange(n_states)
        col_idx = 1
        for state2 in CartesianRange(n_states)
            A_net[row_idx, col_idx] = 0.0
            for i in 1:length(state1)
                state1_idx = state1[i]
                state2_idx = state2[i]
                A_net[row_idx, col_idx] += A[i][state1_idx, state2_idx]
            end
            col_idx += 1
        end
        row_idx += 1
    end
    return A_net
end

function get_likelihood(hmms::HMMLattice, t, state_id, obs)
    n_states = (map(x->get_props(x).n_states, hmms.hmms)...)
    state_ids = ind2sub(n_states, state_id)
    lh = 0.0
    for (hmm, state_id) in zip(hmms.hmms, state_ids)
        state_lh = get_likelihood(hmm, t, state_id, obs, state_ids)
        @show state_id, state_lh
        lh += state_lh
    end
    return lh
end

immutable ViterbiResult{T}
    path::T
    score::Float64
    T1::Matrix{Float64}
    T2::Matrix{Int}
end

immutable ConstraintResult
    index::Int
    score::Float64
end

function satisfy_constraint(T1, T, constraint::Int)
    if constraint==0
        score, index = findmax(T1[:, T])
    else
        index =  constraint
        score = T1[constraint, T]
    end
    return ConstraintResult(index, score)
end

immutable LatticeConstraint{T, Q}
    sizes::NTuple{T, Int}
    constraint::NTuple{Q, Int}
end

function satisfy_constraint(T1, T, constraint::LatticeConstraint)
    sizes = constraint.sizes
    state_constraint = constraint.constraint
    cur_max = -Inf
    cur_max_ind = 0
    for state in 1:size(T1, 1)
        state_tuple = ind2sub(sizes, state)
        if state_tuple[(end-length(state_constraint)+1):end] == state_constraint
            if cur_max_ind==0 || T1[state, T] > cur_max
                cur_max = T1[state, T]
                cur_max_ind = state
            end
        end
    end
    return ConstraintResult(cur_max_ind, cur_max)
end

function get_ml_path(hmm::HMM, obs::Vector, constraint=0)
    K = get_props(hmm).n_states
    T = length(obs)
    π = get_initial_distribution(hmm)
    T1 = Array(Float64, K, T)
    T2 = Array(Int, K, T)
    other_states = Int[]
    for s in 1:K
        T1[s, 1] = π[s] + get_likelihood(hmm, 1, s, obs[1], other_states)
        T2[s, 1] = s
    end
    trans_scores = Array(Float64, K)
    # A = get_transition_matrix(hmm)
    A = zeros(K, K)
    for t=2:T
        # A = get_transition_matrix(hmm, t-1)
        get_transition_matrix!(A, hmm, t-1)
        for s in 1:K
            lh = get_likelihood(hmm, t, s, obs[t], other_states)
            for s2 in 1:K
                trans_scores[s2] = T1[s2, t-1] + A[s2, s] + lh
            end
            T1[s, t] = maximum(trans_scores)
            T2[s, t] = indmax(trans_scores)
        end
    end
    Z = Array(Int, T)
    satisfied_constraint = satisfy_constraint(T1, T, constraint)
    Z[T] = satisfied_constraint.index
    for t in T:-1:2
        Z[t-1] = T2[Z[t], t]
    end
    return ViterbiResult(Z, satisfied_constraint.score, T1, T2)
end

function get_ml_path(lattice::HMMLattice, obs::Vector, constraint=(0,))
    n_states = (map(x->get_props(x).n_states, lattice.hmms)...)
    full_constraint = LatticeConstraint(n_states, constraint)
    result = invoke(get_ml_path, (HMM, Vector, Any), lattice, obs, full_constraint)
    Z_ind = result.path
    Z_sub = Vector{NTuple{length(lattice.hmms), Int}}(length(Z_ind))

    N = prod(n_states)
    for i in 1:length(Z_ind)
        Z_sub[i] = ind2sub(n_states, Z_ind[i])
    end
    return ViterbiResult(Z_sub, result.score, result.T1, result.T2)
end

# function score_path(hmm::HMM, states::Vector{Int}, obs::Vector)
#     s = 1.0
#     π = get_initial_distribution(hmm)
#     for t in 1:length(obs)
#         B = get_transition_matrix(hmm, t)
#         s *= get_likelihood(hmm, t, states[t], obs[t])
#         if t == 1
#             s *= π[states[t]]
#         else
#             s *= B[states[t-1], states[t]]
#         end
#     end
#     return s
# end

end
