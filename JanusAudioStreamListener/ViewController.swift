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
    private let webRTCClient = WebRTCClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.webRTCClient.delegate = self
        self.janusSession.delegate = self
        
        self.runStreamingPluginSequence()
    }
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("didDiscoverLocalCandidate")
    }
    
    func startingEventReceived() {
        print("startingEventReceived")
        self.webRTCClient.answer { (sdp) in
            print("\(sdp)")
        }
    }
    
    func offerReceived(sdp: String)
    {
        let sdp = RTCSessionDescription(type: .offer, sdp: sdp)
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            
            print("!!!set remoteSdp \(String(describing: error))")
            if (error == nil){
                
                self.createLocalSdp()
                
            }
        }
    }
    
    func createLocalSdp()
    {
        self.webRTCClient.answer { (localSdp) in
            self.janusSession.SendStartCommand(sdp: localSdp.sdp, completion: { (result) in
                print("!!!ANSWER SENT!!! : \(localSdp.sdp) ")
                self.webRTCClient.unmuteAudio()
            })
        }
    }
    
    func runStreamingPluginSequence()
    {
        janusSession.CreaseStreamingPluginSession { (result) in
            if result {
                self.sendWatch()
            }
        }
    }
    
    func sendWatch()
    {
        self.janusSession.SendWatchRequest(streamId: 3, completion: {
            print("Watch offer finished!")
        })
       
    }

}

