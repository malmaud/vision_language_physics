using JLD
examples=JMain.ROIDetector.extract(Vector{JMain.ROIDetector.Example}, "/storage/malmaud/kinect")
save(examples, "/Users/malmaud/Desktop/train.txt")
