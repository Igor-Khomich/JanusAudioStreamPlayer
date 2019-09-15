
import Foundation
import WebRTC

protocol WebRTCClientDelegate: class {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
}

class WebRTCClient: NSObject {
    
    private let factory: RTCPeerConnectionFactory
    let peerConnection: RTCPeerConnection
    weak var delegate: WebRTCClientDelegate?
    var localCandidates = [RTCIceCandidate]()
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse]
    
    private var remoteStream: RTCMediaStream?
    private var localStream: RTCMediaStream?
    
    deinit {
        if let stream = peerConnection.localStreams.first {
            peerConnection.remove(stream)
        }
    }
    
    override init() {

        self.factory = RTCPeerConnectionFactory()
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
        let config = RTCConfiguration()
        
        // We use Google's public stun/turn server. For production apps you should deploy your own stun/turn servers.
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        
        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        
        // gatherContinually will let WebRTC to listen to any network changes and send any new candidates to the other client
        config.continualGatheringPolicy = .gatherContinually
        self.peerConnection = self.factory.peerConnection(with: config, constraints: constraints, delegate: nil)
        
        super.init()

        self.peerConnection.delegate = self
        self.setupLocalStream()
    }
    
    private func setupLocalStream() {
        
        localStream = factory.mediaStream(withStreamId: "streamId0")
        
        let localAudioTrack = factory.audioTrack(withTrackId: "audioid0")
        localStream?.addAudioTrack(localAudioTrack)
    }
    
    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.peerConnection.offer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }
            
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)  {
        let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
                                             optionalConstraints: nil)
        self.peerConnection.answer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }
            
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    func set(remoteCandidate: RTCIceCandidate) {
        self.peerConnection.add(remoteCandidate)
    }
    
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteStream?.videoTracks.first?.add(renderer)
    }
    
    func muteAudio() {
        self.setAudioEnabled(false)
    }
    
    func unmuteAudio() {
        self.setAudioEnabled(true)
    }
    
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        let audioTracks = self.peerConnection.senders.compactMap {
            return $0.track as? RTCAudioTrack
            
        }
        audioTracks.forEach {
            $0.isEnabled = isEnabled
        }
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("peerConnection did remote stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("peerConnection new connection state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.localCandidates.append(candidate)
        self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peerConnection did open data channel")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("peerConnection didAdd stream:")
        
        if stream == localStream {
            return
        }
        
        self.remoteStream = stream
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
           print("peerConnection didChange newState: RTCIceGatheringState, \(newState)")
           
           if newState != .complete {
               return
           }
           
   //        print("1. userList", peerConnectionUserList)
   //
   //        for user in peerConnectionUserList {
   //
   //            print("2. user, self.peerConnection[user]", user, self.peerConnections[user])
   //
   //            if self.peerConnections[user] == peerConnection {
   //                print("peerConnection connected", peerConnection)
   //                guard let callback = self.onCreatedLocalSdp, let localDescription = WebRTCUtil.jsonFromDescription(description: self.peerConnections[user]?.localDescription) else {
   //                    print("no localDescription")
   //                    return
   //                }
   //
   //                callback(localDescription)
   //                self.onCreatedLocalSdp = nil
   //
   //                print("3. peerConnection didChange")
   //            }
   //
   //        }
           
       }
}
