//
//  AudioPlayer.swift
//  AudioDemo
//
//  Created by Bansi Bhatt on 17/03/17.
//  Copyright © 2017 Bansi. All rights reserved.
//

import UIKit
import AVFoundation

class AudioPlayer: NSObject {
    
     var btnRecord: UIButton!
     var btnPlay: UIButton!
     var btnStop: UIButton!
     var progressView : UIProgressView!
     var slidebar : UISlider!
     var lblTime : UILabel!
    
    var recorder : AVAudioRecorder!
    var player : AVAudioPlayer!
    var soundFile : URL!
    
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
}
extension AudioPlayer : AVAudioPlayerDelegate{
    
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

extension AudioPlayer : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        print("finished recording \(flag)")
        btnStop.isEnabled = false
        btnPlay.isEnabled = true
        btnRecord.setTitle("Record", for:UIControlState())
        showAlert()
        }
    
    func showAlert(){
        let controller: UIViewController! = UIViewController()
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
        controller?.present(alert, animated:true, completion:nil)

    }
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                          error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
    
    
}

