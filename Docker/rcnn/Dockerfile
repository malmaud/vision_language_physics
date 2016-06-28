FROM py-faster-rcnn
RUN apt-get install -y tmux
WORKDIR /home/py-faster-rcnn
RUN ./data/scripts/fetch_faster_rcnn_models.sh
ADD batch_classify.py tools
CMD ["/home/conda/bin/python", "/home/py-faster-rcnn/tools/batch_classify.py"]
