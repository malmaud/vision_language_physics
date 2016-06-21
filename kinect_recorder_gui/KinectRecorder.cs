using System;
using Microsoft.Kinect;
using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Collections.Generic;
using System.Collections;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Threading;
using System.Collections.Concurrent;

namespace kinect_recorder_gui
{
    struct HandPosition
    {
        public int frame_id;
        public int person_id;
        public ColorSpacePoint right_hand;
        public ColorSpacePoint left_hand;
    }

    struct VideoStats
    {
        public int frame_idx;
        public int frame_start;
        public int video_idx;
    }

    struct FramePair
    {
        public int frame_id;
        public int file_id;
    }

    struct BufferForFrame
    {
        public byte[] buffer;
        public int frame_id;
    }

    class KinectRecorder
    {
        private KinectSensor sensor;
        private DepthFrameReader depthReader;
        private ColorFrameReader colorReader;
        private BodyFrameReader bodyReader;
        private int frameTick;
        private int colorFrameTick;
        private int bodyFrameTick;

        private List<HandPosition> handPoints;
        private bool isRecording;
        public bool Recording
        {
            get { return isRecording; }
        }
        public int FlushRate { get; set; }
        public int Resolution { get; set; }
        private string recordingPath;
        private BlockingCollection<ushort[]> depthQueue;
        private BlockingCollection<BufferForFrame> colorQueue;
        private VideoStats colorIdx;
        private VideoStats depthIdx;
        //private int colorIdx;
        //private int colorIdxStart;
        //private int colorVideoIdx;
        private List<Task> encoderTasks;
        private Thread depthWriter;
        private Thread colorWriter;
        private List<FramePair> depthFrames;
        private List<FramePair> colorFrames;

        private void DepthFrameArrived(object sender, DepthFrameArrivedEventArgs e)
        {
            if (!isRecording) return;
            frameTick += 1;
            var props = sensor.DepthFrameSource.FrameDescription;
            if ((frameTick % Resolution) == 0)
            {

                bool doProcess = false;
                var buffer = new ushort[props.Width * props.Height];
                using (var frame = e.FrameReference.AcquireFrame())
                {

                    if (frame != null)
                    {
                        frame.CopyFrameDataToArray(buffer);
                        doProcess = true;
                    }
                }
                 if(doProcess) {
                    if(depthQueue.Count<5) // Just drop this frame if 5 frames are already enqueued 
                    {
                        depthQueue.Add(buffer);
                    }
                }

            }
        }

        private void ColorFrameArrived(object sender, ColorFrameArrivedEventArgs e)
        {
            if (!isRecording) return;
            colorFrameTick += 1;
            var props = sensor.ColorFrameSource.FrameDescription;
            if ((colorFrameTick % Resolution == 0))
            {
                    var buffer = new byte[props.Width * props.Height * 4];
                    bool shouldProcess = false;
                    using (var frame = e.FrameReference.AcquireFrame())
                    {
                        if (frame != null)
                        {
                            shouldProcess = true;
                            frame.CopyConvertedFrameDataToArray(buffer, ColorImageFormat.Bgra);
                        }
                    }

                    if (shouldProcess)
                    {
                      if (colorQueue.Count < 5)
                      {
                          BufferForFrame x;
                          x.buffer = buffer;
                          x.frame_id = colorFrameTick;
                          colorQueue.Add(x);
                      }
                }
            }
        }

        private void BodyFrameArrived(object sender, BodyFrameArrivedEventArgs e)
        {
            if (!isRecording) return;
            bodyFrameTick += 1;
            if (bodyFrameTick % Resolution == 0)
            {
                using (var frame = e.FrameReference.AcquireFrame())
                {
                    if (frame != null)
                    {
                        var bodies = new Body[frame.BodyCount];
                        frame.GetAndRefreshBodyData(bodies);
                        var pos = new HandPosition();
                        pos.frame_id = bodyFrameTick;
                        foreach(var body in bodies)
                        {
                            pos.person_id = (int)body.TrackingId;
                            var joints = body.Joints;
                            var hand = joints[JointType.HandRight];
                            var mapper = sensor.CoordinateMapper;
                            if (hand != null)
                            {
                                pos.right_hand = mapper.MapCameraPointToColorSpace(hand.Position);
                            }
                            hand = joints[JointType.HandLeft];
                            if(hand!=null)
                            {
                                pos.left_hand = mapper.MapCameraPointToColorSpace(hand.Position);
                            }
                            handPoints.Add(pos);
                        }
                    }
                }
            }
        }

        private void WriteDepthFiles()
        {
            var props = sensor.DepthFrameSource.FrameDescription;
            var processedBuffer = new byte[props.Width * props.Height];
            var depthBitmap = new WriteableBitmap(props.Width, props.Height, 96, 96, PixelFormats.Gray8, null);

            while (true)
            {
                var buffer = depthQueue.Take();
                for (int i = 0; i < props.Width * props.Height; ++i)
                {
                    double conv = 8000.0 / 256.0;
                    int newByte = (int)(buffer[i] / conv);
                    if (newByte >= 0 && newByte <= 255)
                    {
                        processedBuffer[i] = (byte)newByte;
                    }
                    else
                    {
                        processedBuffer[i] = 0;
                    }
                }
                //Debug.WriteLine(String.Format("Frame {0}: Got depth {1}", frameTick, buffer[0]));
                var fullPath = Path.Combine(recordingPath, "depth", String.Format("shot_{0:D5}.jpg", depthIdx.frame_idx));
                var encoder = new JpegBitmapEncoder();
                depthBitmap.WritePixels(new System.Windows.Int32Rect(0, 0, depthBitmap.PixelWidth, depthBitmap.PixelHeight),
                    processedBuffer, depthBitmap.PixelWidth, 0);
                encoder.Frames.Add(BitmapFrame.Create(depthBitmap));
                using (var fs = new FileStream(fullPath, FileMode.Create))
                {
                    encoder.Save(fs);
                    depthIdx.frame_idx += 1;
                    if (depthIdx.frame_idx % FlushRate == 0)
                    {
                        var c1 = depthIdx.frame_start;
                        var c2 = depthIdx.frame_idx;
                        var c3 = depthIdx.video_idx;
                        var encodeTask = Task.Run(() => makeVideo(c1, c2, c3, "depth"));
                        depthIdx.frame_start += FlushRate;
                        depthIdx.video_idx += 1;
                        encoderTasks.Add(encodeTask);
                    }
                }
            }
        }

        private void WriteColorFiles()
        {
            var props = sensor.ColorFrameSource.FrameDescription;
            var colorBitmap = new WriteableBitmap(props.Width, props.Height, 96, 96, PixelFormats.Bgra32, null);
            while (true)
            {
                var bufferForFrame = colorQueue.Take();
                var buffer = bufferForFrame.buffer;
                Debug.Print(String.Format("Queue has {0} elements", colorQueue.Count));
                colorBitmap.WritePixels(new System.Windows.Int32Rect(0, 0, colorBitmap.PixelWidth, colorBitmap.PixelHeight), buffer, 4 * colorBitmap.PixelWidth, 0);
                var colorEncoder = new JpegBitmapEncoder();
                colorEncoder.Frames.Add(BitmapFrame.Create(colorBitmap));
                var fullPath = Path.Combine(recordingPath, "color", String.Format("shot_{0:D5}.jpg", colorIdx.frame_idx));

                using (var fs = new FileStream(fullPath, FileMode.Create))
                {
                    //var a1 = colorEncoder;
                    //var a2 = fs;
                    colorEncoder.Save(fs);
                    buffer = null;
                    FramePair colorFrame;
                    colorFrame.file_id = colorIdx.frame_idx;
                    colorFrame.frame_id = bufferForFrame.frame_id;
                    colorFrames.Add(colorFrame);
                    this.colorIdx.frame_idx += 1;
                    if (colorIdx.frame_idx % FlushRate == 0)
                    {
                        var c1 = colorIdx.frame_start;
                        var c2 = colorIdx.frame_idx;
                        var c3 = colorIdx.video_idx;
                        var encodeTask = Task.Run(() => makeVideo(c1, c2, c3, "color"));
                        colorIdx.frame_start += FlushRate;
                        colorIdx.video_idx += 1;
                        encoderTasks.Add(encodeTask);
                    }
                }
            }
        }

        public KinectRecorder()
        {
            this.Resolution = 60;
            this.handPoints = new List<HandPosition>();
            this.isRecording = false;
            this.encoderTasks = new List<Task>();
            this.FlushRate = 100;
            this.depthQueue = new BlockingCollection<ushort[]>(10);
            this.colorQueue = new BlockingCollection<BufferForFrame>(10);
            this.depthWriter = new Thread(WriteDepthFiles);
            this.colorWriter = new Thread(WriteColorFiles);
            this.depthFrames = new List<FramePair>();
            this.colorFrames = new List<FramePair>();
        }

        public void Initialize()
        {
            sensor = KinectSensor.GetDefault();
            depthReader = sensor.DepthFrameSource.OpenReader();
            var props = sensor.DepthFrameSource.FrameDescription;
            depthReader.FrameArrived += DepthFrameArrived;
            sensor.IsAvailableChanged += AvailableChanged;
            colorReader = sensor.ColorFrameSource.OpenReader();
            colorReader.FrameArrived += ColorFrameArrived;
            var colorProps = sensor.ColorFrameSource.FrameDescription;
            bodyReader = sensor.BodyFrameSource.OpenReader();
            bodyReader.FrameArrived += BodyFrameArrived;
            depthWriter.Start();
            colorWriter.Start();

            sensor.Open();
        }

        public void Record(string path)
        {
            if (isRecording) return;
            frameTick = 0;
            colorFrameTick = 0;
            bodyFrameTick = 0;
            colorIdx.frame_idx = 0;
            colorIdx.frame_start = 0;
            colorIdx.video_idx = 0;
            depthIdx.frame_idx = 0;
            depthIdx.frame_start = 0;
            depthIdx.video_idx = 0;
            handPoints.Clear();
            recordingPath = path;
            isRecording = true;
        }

        void AvailableChanged(object sender, IsAvailableChangedEventArgs e)
        {
            Debug.WriteLine("availability changed");
            if (e.IsAvailable)
            {
                Debug.WriteLine("Ready");
            }
        }

        void saveHandPoints()
        {
            var fullPath = Path.Combine(recordingPath, "hand_points.csv");
            using (var fs = new StreamWriter(fullPath, true))
            {
                fs.WriteLine("frame_id, person_id, right_hand_x, right_hand_y, left_hand_x, left_hand_y");
                foreach (var pos in handPoints)
                {
                    fs.WriteLine(String.Format("{0}, {1}, {2}, {3}, {4}, {5}", pos.frame_id, pos.person_id, pos.right_hand.X, pos.right_hand.Y, pos.left_hand.X, pos.left_hand.Y));
                }
            }
        }

        private void makeVideo(int start_frame, int end_frame, int video_id, string subfolder)
        {
            Debug.WriteLine(String.Format("Making video {0}/{1}/{2} {3}", start_frame, end_frame, video_id, subfolder));
            var ffmpeg = new Process();
            ffmpeg.StartInfo.FileName = @"C:\Users\malmaud\Desktop\ffmpeg.exe";
            ffmpeg.StartInfo.UseShellExecute = false;
            ffmpeg.StartInfo.Arguments =
                String.Format("-start_number {0} -framerate 30 -f image2 -i shot_%05d.jpg -vframes {1} -vcodec libx264 -b 5000k  movie_{2}.avi",
                start_frame, end_frame-start_frame, video_id);
            ffmpeg.StartInfo.WorkingDirectory = Path.Combine(recordingPath, subfolder);
            ffmpeg.Start();
            ffmpeg.WaitForExit();

            Directory.SetCurrentDirectory(Path.Combine(recordingPath, subfolder));
            for(int frame_id=start_frame;frame_id<end_frame;++frame_id)
            {
                File.Delete(String.Format("shot_{0:D5}.jpg", frame_id));
            }
        }

        private void concatVideo(string subfolder)
        {
            Directory.SetCurrentDirectory(Path.Combine(recordingPath, subfolder));
            int movie_id;
            int endIdx;
            if (subfolder == "color")
            {
                endIdx = colorIdx.video_idx;
            }
            else
            {
                endIdx = depthIdx.video_idx;
            }
            using (var fs = new StreamWriter("video_list.txt", true))
            {

                for (movie_id = 0; movie_id < endIdx; ++movie_id) {
                    fs.WriteLine(String.Format("file 'movie_{0}.avi'", movie_id));
                }
            }
            var ffmpeg = new Process();
            ffmpeg.StartInfo.FileName = @"C:\Users\malmaud\Desktop\ffmpeg.exe";
            ffmpeg.StartInfo.Arguments = "-f concat -i video_list.txt -c copy movie.avi";
            ffmpeg.Start();
            ffmpeg.WaitForExit();
            for(movie_id=0; movie_id<endIdx; ++movie_id)
            {
                File.Delete(String.Format("movie_{0}.avi", movie_id));
            }
        }

        void saveColorFrames()
        {
            var path = Path.Combine(recordingPath, "color", "frame_correspondance.csv");
            using (var fs = new StreamWriter(path, true))
            {
                fs.WriteLine("file_id, frame_id");
                foreach (var entry in colorFrames)
                {
                    fs.WriteLine(String.Format("{0}, {1}", entry.file_id, entry.frame_id));
                }
            }
        }

        public void StopRecording()
        {
            if (!isRecording) return;
            isRecording = false;
            saveHandPoints();
            var c3 = colorIdx.video_idx;
            encoderTasks.Add(Task.Run(() => makeVideo(colorIdx.frame_start, colorIdx.frame_idx, c3, "color")));
            var c4 = depthIdx.video_idx;
            encoderTasks.Add(Task.Run(() => makeVideo(depthIdx.frame_start, depthIdx.frame_idx, c4, "depth")));
            colorIdx.video_idx += 1;
            depthIdx.video_idx += 1;
            foreach(var task in encoderTasks)
            {
                task.Wait();
            }
            concatVideo("color");
            concatVideo("depth");
            saveColorFrames();
        }

        public void Close()
        {
            depthReader.Dispose();
            colorReader.Dispose();
            bodyReader.Dispose();
            sensor.Close();
        }
    }
}
