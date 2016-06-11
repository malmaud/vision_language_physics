

using JLD

scene=load("/storage/malmaud/kinect/pickup1/scene.jld")["scene"]
sentence=parse(Sentences.Sentence, "A person picks up a rat")
sentence.words[1] = CloseWords.CloseWord(scene)
sentence.words[1].tracks=(1,2)

res = get_score(scene, sentence)

res.path


pick_up = PickupWords.PickupWord(scene)
pick_up.tracks = (1,2)
left_hand = ObjectWords.ObjectWord(scene)
left_hand.obj_name=:left_hand
left_hand.tracks=(1,)
rat = ObjectWords.ObjectWord(scene)
rat.obj_name = :rat
rat.tracks = (2,)
lattice=HMMSolver.HMMLattice([Trackers.Tracker(scene), Trackers.Tracker(scene), pick_up, left_hand, rat])

N=HMMSolver.get_props(lattice).n_states

A=zeros(N,N)

HMMSolver.get_transition_matrix!(A, lattice, 560)
for i=70
    lh = HMMSolver.get_likelihood(lattice, 561, i, 0)
    @show i, lh
end



using PyPlot
using PyCall
@pyimport seaborn

clf(); seaborn.heatmap(exp(A))
