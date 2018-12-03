//
//  ViewController.swift
//  JanusAudioStreamListener
//
//  Created by Igor Khomich on 11/25/18.
//  Copyright © 2018 Igor Khomich. All rights reserved.
//

import UIKit
import JanusWebGate
import WebRTC

class ViewController: UIViewController, WebRTCClientDelegate, JanusSessionDelegate {
    
    private let janusSession = JanusSession(url: "http://webrtc.urancompany.com:8088/janus/")
    private var webRTCClient: WebRTCClient?
    private var playingStream = false
    @IBOutlet weak var StreamIdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.janusSession.delegate = self
        
        self.runStreamingPluginSequence()
        
    }
    
    @IBAction func StopStream(_ sender: Any) {
        self.janusSession.SendStopStreamCommand { (result) in
            //TODO: do something
            self.playingStream = false
        }
    }
    
    @IBAction func PauseStream(_ sender: Any) {
        self.janusSession.SendPauseStreamCommand { (result) in
            //TODO: do something
        }
    }
    
    @IBAction func PlayStream(_ sender: Any) {
        if (!playingStream) {
            //request new stream
            self.sendWatch()
        } else {
            //start playing paused stream
            self.janusSession.SendReStartPausedStreamCommand { (result) in
                //TODO: do something
            }
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("didDiscoverLocalCandidate")
    }
    
    func startingEventReceived() {
        print("startingEventReceived")
        self.playingStream = true
    }
    
    func offerReceived(sdp: String)
    {
        let sdp = RTCSessionDescription(type: .offer, sdp: sdp)
        self.webRTCClient!.set(remoteSdp: sdp) { (error) in
            print("Set remoteSdp \(String(describing: error))")
            if (error == nil){
                self.createLocalSdp()
            }
        }
    }
    
    
    func createLocalSdp()
    {
        self.webRTCClient!.answer { (localSdp) in
            self.janusSession.SendStartCommand(sdp: localSdp.sdp, completion: { (error) in
                 print("Start request finished, error: \(String(describing: error))")
                self.startingEventReceived()
            })
        }
    }
    
    func runStreamingPluginSequence()
    {
        janusSession.CreaseStreamingPluginSession { (result) in
            if result {
                //TODO: ready to watch
            }
        }
    }
    
    func sendWatch()
    {
        self.webRTCClient = WebRTCClient()
        self.webRTCClient!.delegate = self

        //TODO: add checks
        let streamId: Int = Int(self.StreamIdTextField.text!)!
        self.janusSession.SendWatchRequest(streamId: streamId) { (error) in
            print("Watch offer finished, error: \(String(describing: error))")
        }
 
    }

}

