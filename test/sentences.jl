

using JLD

scene=load("/storage/malmaud/kinect/pickup1/scene.jld")["scene"]
<<<<<<< Updated upstream
sentence=parse(Sentences.Sentence, "A person is close to a rat")
# sentence.words[1] = CloseWords.CloseWord(scene)
# sentence.words[1].tracks=(1,2)
||||||| merged common ancestors
sentence=parse(Sentences.Sentence, "A person picks up a rat")
# sentence.words[1] = CloseWords.CloseWord(scene)
# sentence.words[1].tracks=(1,2)
=======
sentence=parse(Sentences.Sentence, "A person puts down a rat.")
>>>>>>> Stashed changes

res = get_score(scene, sentence)
res.score
using PyPlot
clf();plot(scene, res, sentence)
res.score

tokens=Sentences.parse(Vector{Sentences.Token},"A person is close to a rat.")

tokens[5]
