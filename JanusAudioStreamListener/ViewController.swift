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
    
   private let janusSession = JanusSession(url: "ttps://janus.conf.meetecho.com/janus")

    private var webRTCClient: WebRTCClient?
    private var playingStream = false
    @IBOutlet weak var StreamIdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: routeChange)

        self.janusSession.delegate = self
        
        self.runStreamingPluginSequence()
        
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
    
    var loccandidatesCount: Int = 0
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("didDiscoverLocalCandidate")
        self.janusSession.SendLocalCandidate(candidate: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid!) { (error) in
            print("LocalCandidate sent")
            self.loccandidatesCount = self.loccandidatesCount + 1
            
//            if (self.loccandidatesCount == 2)
//            {
//                self.janusSession.SendLocalCandidateComplete(completion: { (error) in
//                    print("SendLocalCandidateComplete sent")
//                })
//            }
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

        #if arch(arm64)
        let remoteRenderer = RTCMTLVideoView(frame: self.view.frame)
        remoteRenderer.videoContentMode = .scaleAspectFill
        #else
        let remoteRenderer = RTCEAGLVideoView(frame: self.view.frame)
        #endif

        // We use Google's public stun/turn server. For production apps you should deploy your own stun/turn servers.
        self.webRTCClient = WebRTCClient(iceServers: ["stun:stun.l.google.com:19302"])
        self.webRTCClient!.delegate = self
        self.webRTCClient!.renderRemoteVideo(to: remoteRenderer)
        
        self.embedView(remoteRenderer, into: self.view)
        
        
        //TODO: add checks
        let streamId: Int = Int(self.StreamIdTextField.text!)!
        self.janusSession.SendWatchRequest(streamId: streamId) { (error) in
            print("Watch offer finished, error: \(String(describing: error))")
        }
 
    }

    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
        
        containerView.sendSubviewToBack(view)
    }
    
}

