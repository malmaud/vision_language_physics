

using JLD

scene=load("/storage/malmaud/kinect/pickup1/scene.jld")["scene"]
sentence=parse(Sentences.Sentence, "A person picks up a rat")
# sentence.words[1] = CloseWords.CloseWord(scene)
# sentence.words[1].tracks=(1,2)

res = get_score(scene, sentence)
using PyPlot
clf();plot(scene, res, sentence)
res.score

tokens=Sentences.parse(Vector{Sentences.Token},"A person puts down a rat.")

tokens[6]
