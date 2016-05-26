using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Diagnostics;
using System.IO;

namespace kinect_recorder_gui
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    /// 
    public partial class MainWindow : Window
    {
        private KinectRecorder recorder;

        public MainWindow()
        {
            InitializeComponent();
            recorder = new KinectRecorder();
            recorder.Initialize();
            recorder.Resolution = 1;
            recorder.FlushRate = 5000;
            this.directoryText.Text = @"C:\Users\malmaud\Desktop\kinect_shots";
        }


        private void recordButton_Click(object sender, RoutedEventArgs e)
        {
            if(recorder.Recording)
            {
                recorder.StopRecording();
                recordButton.Content = "Record";
                return;
            }
            var directory = this.directoryText.Text;
            var videoID = this.videoIDText.Text;
            Debug.Print(String.Format("Recording to {0}/{1}", directory, videoID));
            if(directory.Length==0 || videoID.Length==0)
            {
                this.ShowError("Video ID can't be empty");
                return;
            }
            if(!Directory.Exists(directory))
            {
                this.ShowError(String.Format("Directory {0} does not exist", directory));
                return;
            }
            var fullPath = Path.Combine(directory, videoID);
            if(Directory.Exists(fullPath))
            {
                var res = MessageBox.Show(String.Format("Overwrite files in {0}?", fullPath), "Warning", MessageBoxButton.YesNo);
                if(res==MessageBoxResult.No)
                {
                    return;
                }
            }
            else
            {
                Directory.CreateDirectory(fullPath);
                string[] subpaths = { "color", "depth" };
                foreach (var subpath in subpaths)
                {
                    Directory.CreateDirectory(Path.Combine(fullPath, subpath));
                }

            }
            recordButton.Content = "Stop recording";
            recorder.Record(fullPath);
        }

        private void ShowError(string errMsg)
        {
            var errText = String.Format("Error: {0}", errMsg);
            Debug.Print(errText);
            MessageBox.Show(errText, "Error");
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            recorder.StopRecording();
            recorder.Close();
        }
    }
}
