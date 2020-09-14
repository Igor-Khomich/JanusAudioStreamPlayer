//
//  BaseWebRtcReadyViewController.swift
//  JanusAudioStreamListener
//
//  Created by Igor Khomich on 9/18/19.
//  Copyright © 2019 Igor Khomich. All rights reserved.
//

import UIKit
import Foundation
import WebRTC

class BaseWebRtcReadyViewController: UIViewController, WebRTCClientDelegate, UITextFieldDelegate {
    
    internal var webRTCClient: WebRTCClient = WebRTCClient()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: routeChange)
        
        self.webRTCClient.delegate = self
        
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

    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        print("webRTCClient didChangeConnectionState!!!")
    }
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        //IDLE
    }

    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
       print("didDiscoverLocalCandidate")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           self.view.endEditing(true)
           return false
    }
}
