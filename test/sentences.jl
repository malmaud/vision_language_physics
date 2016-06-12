

using JLD

scene=load("/storage/malmaud/kinect/pickup1/scene.jld")["scene"]
sentence=parse(Sentences.Sentence, "A person picks up a rat")
sentence.words[1] = CloseWords.CloseWord(scene)
sentence.words[1].tracks=(1,2)

res = get_score(scene, sentence)
res.score
res.path
for i in 1:size(res.T1, 1)
    x=find(res.T1[:,i].>-Inf)
    if isempty(x)
        @show i
    end
end

x=find(res.T1[:, end].>-Inf)

sizes=(5,5,5,1,1)
[ind2sub(sizes, _) for _ in x]
for word in sentence.words
    word.scene=scene
end

lattice=HMMSolver.HMMLattice([Trackers.Tracker(scene), Trackers.Tracker(scene), sentence.words...])

N=HMMSolver.get_props(lattice).n_states

A=zeros(N,N)

HMMSolver.get_transition_matrix!(A, lattice, 1)

using PyPlot

using PyCall

@pyimport seaborn

seaborn.heatmap(A)

res.path

idx1 = sub2ind(sizes, res.path[1]...)
idx2=sub2ind(sizes,res.path[2]...)
A[12,112]

h=sentence.words[1]

A=zeros(5,5)
HMMSolver.get_transition_matrix!(A, h, 1)
A[1,2]
