//
//  ViewController.swift
//  AudioDemo
//
//  Created by Bansi Bhatt on 15/03/17.
//  Copyright © 2017 Bansi. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var progressView : UIProgressView!
    @IBOutlet weak var slidebar : UISlider!
    @IBOutlet weak var lblTime : UILabel!
    
    
    var recorder : AVAudioRecorder!
    var player : AVAudioPlayer!
    var soundFile : URL!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnStop.isEnabled = false
        btnPlay.isEnabled = false
        setSessionPlayAndRecord()
       // progressView.setProgress(30.0, animated: true)
       
        // Do any additional setup after loading the view, typically from a nib.
    }
   

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK:- button UIAction
    
    @IBAction func btnRecordPressed(_ sender: UISlider) {
       
        if player != nil && player.isPlaying{
            player.stop()
        }
        
        if recorder == nil {
            print("start recording")
            btnRecord.setTitle("Pause", for: UIControlState())
            btnPlay.isEnabled = false
            btnStop.isEnabled = false
            getPermissionToRecord(setup: true)
            self.setSessionPlayAndRecord()
           
            self.setupRecorder()
            self.recorder.record()
            return
        }

        if recorder != nil && recorder.isRecording{
            print("pausing")
            recorder.pause()
            btnRecord.setTitle("Continue", for: UIControlState())
            btnStop.isEnabled = true
        
        }else{
            print("Recording")
            btnRecord.setTitle("Pause", for: UIControlState())
            btnPlay.isEnabled = false
            btnStop.isEnabled = true
            // getPermissionToRecord(setup: false)
            self.setSessionPlayAndRecord()
            self.recorder.record()
        }
    }
    
    @IBAction func btnPlayPressed(_ sender: Any) {
        setSessionPlay()
        play()
    }
    
    func play(){
        
        var url:URL?
       
        if self.recorder != nil {
            url = self.recorder.url
        } else {
           url = self.soundFile!
            //url = NSURL(string: "http://radio.spainmedia.es/wp-content/uploads/2015/12/ogilvy.mp3") as URL?
        }

        print("playing \(url)")
        
      //  url = NSURL(string: "http://radio.spainmedia.es/wp-content/uploads/2015/12/ogilvy.mp3") as URL?
        do {
            
            self.player = try AVAudioPlayer(contentsOf: url!)
            btnStop.isEnabled = true
            //  player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            slidebar.maximumValue = Float(player.duration)
            slidebar.value = 0.0
        
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime(_:)), userInfo: nil, repeats: true)
                      //let p = AVPlayer(playerItem: item)
       
            player.play()
            
            btnPlay.isEnabled = false
            slidebar.isHidden = false
           
       
        } catch let error as NSError {
            self.player = nil
            print(error.localizedDescription)
        }

    }
    func updateTime(_ timer: Timer) {
        slidebar.value = Float(player.currentTime)
        
        let seconds = lroundf(slidebar.value);
        let hour = seconds / 3600
        let mins = (seconds % 3600) / 60//(seconds / 60) % 60
        let secs = seconds % 60//seconds % 60
        lblTime?.text = String(format: "%02d:%02d", mins, secs)
    }
    
    @IBAction func btnStopPressed(_ sender: Any) {
        print("stop")
        
        recorder?.stop()
        player?.stop()
        
        btnRecord.setTitle("Record", for:UIControlState())
        let session = AVAudioSession.sharedInstance()
       
        do {
            try session.setActive(false)
            btnPlay.isEnabled = true
            btnStop.isEnabled = false
            btnRecord.isEnabled = true
        } catch let error as NSError {
            print("could not make session inactive")
            print(error.localizedDescription)
        }
        
    }
    
    //MARK:- methods
    func updateAudioMeter(_ timer:Timer) {
        
        if recorder!.isRecording {
            let min = Int(recorder.currentTime / 60)
            let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
            let s = String(format: "%02d:%02d", min, sec)
            
            //statusLabel.text = s
            recorder.updateMeters()
            
            // if you want to draw some graphics...
            //var apc0 = recorder.averagePowerForChannel(0)
            //var peak0 = recorder.peakPowerForChannel(0)
        }
    }
    @IBAction func updateSlider(_ sender: UISlider) {
        progressView.isHidden = false
        player.currentTime = TimeInterval(slidebar.value)
        progressView.setProgress(Float(player.currentTime), animated: true)
        print(player.currentTime)
        let seconds = lroundf(Float(player.currentTime));
        
        lblTime.text = String(format: "%02d:%02d", (seconds / 60) % 60, seconds % 60)

    }

    func setSessionPlay(){
        let session : AVAudioSession = AVAudioSession.sharedInstance()
        
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            print("could not make session category \n errror is \(error)")
        }
        
        do {
            try session.setActive(true)
        } catch _ as NSError {
            print("could not make session active")
        }
    }
    func setSessionPlayAndRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("could not set session category")
            print(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }

    func getPermissionToRecord(setup:Bool){
        let session : AVAudioSession = AVAudioSession.sharedInstance()
        if(session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))){
            session.requestRecordPermission({ (granted : Bool)-> Void in
                if granted {
                    self.setSessionPlayAndRecord()
                    
                    if setup{
                         self.setupRecorder()
                    }
                    self.recorder.record()
                }else {
                    print("Permission to record not granted")
                }
            })
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func setupRecorder() {
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).m4a"
        print(currentFileName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.soundFile = documentsDirectory.appendingPathComponent(currentFileName)
        print("writing to soundfile url: '\(soundFile!)'")
        
        if FileManager.default.fileExists(atPath: soundFile.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFile.absoluteString) exists")
        }
        
        
        let recordSettings:[String : AnyObject] = [
            AVFormatIDKey:             NSNumber(value: kAudioFormatAppleLossless),
            AVEncoderAudioQualityKey : NSNumber(value:AVAudioQuality.max.rawValue),
            AVEncoderBitRateKey :      NSNumber(value:320000),
            AVNumberOfChannelsKey:     NSNumber(value:2),
            AVSampleRateKey :          NSNumber(value:44100.0)
        ]
        
        
        do {
            recorder = try AVAudioRecorder(url: soundFile, settings: recordSettings)
           // recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch let error as NSError {
            recorder = nil
            print(error.localizedDescription)
        }
        
    }
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: audioFilename, settings: settings)
          //  recorder.delegate = self
            recorder.record()
            
            btnRecord.setTitle("Stop", for: .normal)
        } catch {
          //  finishRecording(success: false)
        }
    }
        func recordTapped() {
            if recorder == nil {
                startRecording()
            } else {
               // finishRecording(success: true)
            }
        }
    
}

extension ViewController : AVAudioPlayerDelegate{
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing \(flag)")
        btnRecord.isEnabled = true
        btnStop.isEnabled = false
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
}

extension ViewController : AVAudioRecorderDelegate{
   
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        print("finished recording \(flag)")
        btnStop.isEnabled = false
        btnPlay.isEnabled = true
        btnRecord.setTitle("Record", for:UIControlState())
        
        // iOS8 and later
        let alert = UIAlertController(title: "Recorder",
                                      message: "Finished Recording",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep", style: .default, handler: {action in
            print("keep was tapped")
            self.recorder = nil
        }))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {action in
            print("delete was tapped")
            self.recorder.deleteRecording()
        }))
        self.present(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                          error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
    

}

