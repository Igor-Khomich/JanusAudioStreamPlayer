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

class ViewController: UIViewController, JanusSessionDelegate {

    private let janusSession = JanusSession(url: "https://janus.conf.meetecho.com/janus")

    private var webRTCClient: WebRTCClient?
    private var playingStream = false
    @IBOutlet weak var StreamIdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: routeChange)

        janusSession.delegate = self
        janusSession.audioBridgeDelegate = self
        
//        self.runStreamingPluginSequence()
        self.runAudioBridgePluginSequence()
    }
    
    private func routeChange(_ n: Notification) {
        guard let info = n.userInfo,
            let value = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: value) else { return }
        switch reason {
        case .categoryChange: try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        default: break
        }
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

//        self.playStream()
        
        self.joinAudioRoom()
    }
    
    func playStream()
    {
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
    
    func startingEventReceived() {
        print("startingEventReceived")
        self.playingStream = true

    }
    
    func trickleReceived(trickle: JanusTrickleCandidate)
    {
        let candidate: RTCIceCandidate = RTCIceCandidate(sdp: trickle.candidate, sdpMLineIndex: trickle.sdpMLineIndex, sdpMid: trickle.sdpMid)
        self.webRTCClient!.set(remoteCandidate: candidate)
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
    
    func generateLocalSdpOffer(completion: @escaping (String) -> ())
    {
        self.webRTCClient!.offer { (rtcDescription) in
            return completion(rtcDescription.sdp)
        }
    }
    
    
    
    
    func runStreamingPluginSequence()
    {
        janusSession.CreaseStreamingPluginSession { (result) in
            if result {
                //TODO: ready to watch
//                self.janusSession.GetStreamsList(completion: { (result, error) in
//                    print("GetStreamsList: \(result)")
//                })
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
 
        self.webRTCClient!.unmuteAudio()
    }
    
  //MARK: AUDIO ROOM REQUEST LIFE CYCLE
    
    func runAudioBridgePluginSequence()
    {
        janusSession.CreaseAudioBridgePluginSession{ (result) in
            if result {
                self.janusSession.GetAudioRoomsList(completion: { (result, error) in
                    print("GetStreamsList: \(result)")
                })
            }
        }
    }
    
    func joinAudioRoom()
    {
        if (!playingStream) {
            //request new stream
            self.sendJoinRoom()
        } else {
            //proceed play/pause/mute etc. here
        }
    }
    
    func sendJoinRoom()
    {
        self.webRTCClient = WebRTCClient()
        self.webRTCClient!.delegate = self
        
        let roomId: Int = Int(self.StreamIdTextField.text!)!
        self.janusSession.JoinToAudioRoomRequest(roomId: roomId) { (error) in
            print("Watch offer finished, error: \(String(describing: error))")
            
            self.generateLocalSdpOffer { (sdp) in
                
                self.janusSession.sendAudioRoomConfigureRequestWith(offer: sdp) { (error) in
                    print("configure request sent, error: \(String(describing: error))")
                    
                    self.webRTCClient!.unmuteAudio()
                }
            }
            
        }
    }
}

extension ViewController: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        print("webRTCClient didChangeConnectionState!!!")
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        //IDLE
    }
    
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
           print("didDiscoverLocalCandidate")
           self.janusSession.SendLocalCandidate(candidate: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid!) { (error) in
               print("LocalCandidate sent")
           }
       }
    
}

extension ViewController: AudioBridgeDelegate {
    
    func joinedRoom(event: JanusAudioRoomJoinedEvent) {
        print("joined to room with participants \(event.participants)")
    }

}


