
import Foundation
import WebRTC

protocol WebRTCClientDelegate: class {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
}

final class WebRTCClient: NSObject {
    
    // The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
    // A new RTCPeerConnection should be created every new call, but the factory is shared.
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    private var remoteStream: RTCMediaStream?
    private var remoteRenderView: RTCEAGLVideoView?
    private var remoteView: UIView?
//    private var remoteRenderView: RTCMTLVideoView?
    private var renderer: RTCVideoRenderer?
    
    override init() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        
        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        
        // gatherContinually will let WebRTC to listen to any network changes and send any new candidates to the other client
        config.continualGatheringPolicy = .gatherContinually
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
        self.peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)
        
        super.init()
        self.createMediaSenders()
        self.configureAudioSession()
        self.peerConnection.delegate = self
    }
    
    // MARK: Signaling
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
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
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
    
    // MARK: Media
    func startCaptureLocalVideo(view: UIView, device: AVCaptureDevice?, format: AVCaptureDevice.Format?, fps: Int?) {
        let width: CGFloat
        let height: CGFloat
        if let format = format {
            width = CGFloat(CMVideoFormatDescriptionGetDimensions(format.formatDescription).width)
            height = CGFloat(CMVideoFormatDescriptionGetDimensions(format.formatDescription).height)
        } else {
            width = CGFloat(100)
            height = CGFloat(100)
        }
        
        let localFrame = CGRect(x: 0, y: 0, width: height/2, height: width/2) //height->width is crossed becouse of portrait mode, we need more logic here in general
        let localRenderer = RTCEAGLVideoView(frame: localFrame)
        localRenderer.isHidden = false
        view.addSubview(localRenderer)
        self.startCaptureLocalVideo(renderer: localRenderer,
                                    device: device,
                                    format: format,
                                    fps: fps)
    }
    
    func startCaptureLocalVideo(renderer: RTCVideoRenderer, device: AVCaptureDevice?, format: AVCaptureDevice.Format?, fps: Int?) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }

            
        let camera: AVCaptureDevice
        if device != nil {
            camera = device!
        } else {
            camera = RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }! //TODO: IGK if no captureDevices???
        }
        
        
        let finalFormat: AVCaptureDevice.Format
        if format != nil {
            finalFormat = format!
        } else {
            finalFormat = (RTCCameraVideoCapturer.supportedFormats(for: camera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }).last! //TODO: IGK if no supportedFormats?
        }
        
        
        let finalFps: Int
        if fps != nil {
            finalFps = fps!
        } else {
            finalFps = Int(finalFormat.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last!.maxFrameRate) //TODO: IGK if no videoSupportedFrameRateRanges?
        }

        capturer.startCapture(with: camera,
                              format: finalFormat,
                              fps: finalFps)
        
        self.localVideoTrack?.add(renderer)
    }
    
    func renderRemoteVideoTo(view: UIView) {
        self.remoteRenderView = RTCEAGLVideoView()
        self.remoteRenderView?.frame = view.bounds
        self.remoteRenderView?.delegate = self
        self.remoteRenderView?.isHidden = false
        view.addSubview(remoteRenderView!)
        self.remoteView = view
    }
    
    private func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    private func createMediaSenders() {
        let streamId = "stream"
        
        // Audio
        let audioTrack = self.createAudioTrack()
        self.peerConnection.add(audioTrack, streamIds: [streamId])
        
        // Video
        let videoTrack = self.createVideoTrack()
        self.localVideoTrack = videoTrack
        self.peerConnection.add(videoTrack, streamIds: [streamId])
        self.remoteVideoTrack = self.peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        
        // Data
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannel = dataChannel
        }
    }
    
    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCClient.factory.audioSource(with: audioConstrains)
        let audioTrack = WebRTCClient.factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = WebRTCClient.factory.videoSource()
        
        #if TARGET_OS_SIMULATOR
        self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif
        
        let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }
    
    // MARK: Data Channels
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }
    
    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.remoteDataChannel?.sendData(buffer)
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
        
        //@IGK NO LOCAL STREAMS!!!
        self.remoteStream = stream
        
        if let track = stream.videoTracks.first {
            track.add(remoteRenderView!)
        }
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remote stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        self.remoteVideoTrack = peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
        self.remoteDataChannel = dataChannel
    }
}

// MARK:- Audio control
extension WebRTCClient {
    func muteAudio() {
        self.setAudioEnabled(false)
    }
    
    func unmuteAudio() {
        self.setAudioEnabled(true)
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Force speaker
    func speakerOn() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch let error {
                debugPrint("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        let audioTracks = self.peerConnection.transceivers.compactMap { return $0.sender.track as? RTCAudioTrack }
        audioTracks.forEach { $0.isEnabled = isEnabled }
    }
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.webRTCClient(self, didReceiveData: buffer.data)
    }
}

extension WebRTCClient: RTCVideoViewDelegate {
 func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
     let isLandScape = size.width < size.height
     
     guard let _renderView = remoteRenderView, let _parentView = remoteView else {
         return
     }
     
     if(isLandScape){
         let ratio = size.width / size.height
         _renderView.frame = CGRect(x: 0, y: 0, width: _parentView.frame.height * ratio, height: _parentView.frame.height)
         _renderView.center.x = _parentView.frame.width/2
     }else{
         let ratio = size.height / size.width
         _renderView.frame = CGRect(x: 0, y: 0, width: _parentView.frame.width, height: _parentView.frame.width * ratio)
         _renderView.center.y = _parentView.frame.height/2
     }
 }
}

