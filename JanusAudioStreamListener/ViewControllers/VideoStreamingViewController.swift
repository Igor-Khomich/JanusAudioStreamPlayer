
import UIKit
import JanusWebGate
import WebRTC

class VideoStreamingViewController: BaseWebRtcReadyViewController {

    private let janusStreamingSession = JanusStreamingSession(url: Environment.instanceUrl)

    private var playingStream = false
    
    @IBOutlet weak var StreamIdTextField: UITextField!
    @IBOutlet private weak var localVideoView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.runStreamingPluginSequence()
        
        StreamIdTextField.delegate = self
        janusStreamingSession.delegate = self


        self.webRTCClient.renderRemoteVideoTo(view: self.localVideoView!)

    }

    @IBAction func StopStream(_ sender: Any) {
        self.janusStreamingSession.sendStopStreamCommand { (result) in
            //TODO: do something
            self.playingStream = false
        }
    }
    
    @IBAction func PauseStream(_ sender: Any) {
        self.janusStreamingSession.sendPauseStreamCommand { (result) in
            //TODO: do something
        }
    }
    
    @IBAction func PlayStream(_ sender: Any) {
        self.playStream()
    }
    
    func playStream()
    {
        if (!playingStream) {
            //request new stream
            self.sendWatch()
        } else {
            //start playing paused stream
            self.janusStreamingSession.sendReStartPausedStreamCommand { (result) in
                //TODO: do something
            }
        }
    }
    
    func createLocalSdp()
    {
        self.webRTCClient.answer { (localSdp) in
            self.janusStreamingSession.sendStartCommand(sdp: localSdp.sdp, completion: { (error) in
                 print("Start request finished, error: \(String(describing: error))")
                self.startingEventReceived()
            })
        }
    }

    func runStreamingPluginSequence()
    {
        janusStreamingSession.createJanusSession { (result) in
            if result {
               
                //TODO: ready to watch
//                self.janusStreamingSession.getStreamsList(completion: { (result, error) in
//                    print("GetStreamsList: \(result!)")
//                })
            }
        }
    }
    
    func sendWatch()
    {
        //TODO: add checks
        let streamId: Int = Int(self.StreamIdTextField.text!)!
        self.janusStreamingSession.sendWatchRequest(streamId: streamId) { (error) in
            print("Watch offer finished, error: \(String(describing: error))")
        }
 
        self.webRTCClient.unmuteAudio()
    }
    
    
    override func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
       print("didDiscoverLocalCandidate")
       self.janusStreamingSession.sendLocalCandidate(candidate: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid!) { (error) in
           print("LocalCandidate sent")
       }
    }
 
}

extension VideoStreamingViewController: JanusStreamingSessionDelegate {
    
    func startingEventReceived() {
        print("startingEventReceived")
        self.playingStream = true
    }
    
    func trickleReceived(trickle: JanusTrickleCandidate)
    {
        let candidate: RTCIceCandidate = RTCIceCandidate(sdp: trickle.candidate, sdpMLineIndex: trickle.sdpMLineIndex, sdpMid: trickle.sdpMid)
        self.webRTCClient.set(remoteCandidate: candidate)
    }
    
    func offerReceived(sdp: String)
    {
        let sdp = RTCSessionDescription(type: .offer, sdp: sdp)
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            print("Set remoteSdp \(String(describing: error))")
            if (error == nil){
                self.createLocalSdp()
            }
        }
    }
}
