
import UIKit
import JanusWebGate
import WebRTC

class VideoBridgeViewController: BaseWebRtcReadyViewController {

    private let janusVBSession = JanusVideoRoomSession(url: Environment.instanceUrl)
    
    private var isPlaying = false
    private var myPictureView: UIView? = nil
    
    @IBOutlet weak var roomIdTextField: UITextField!
    @IBOutlet weak var feedIdTextField: UITextField!
    
    @IBOutlet private weak var localVideoView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        roomIdTextField.delegate = self
        
        janusVBSession.delegate = self
        
        self.runAudioBridgePluginSequence()
        self.webRTCClient.renderRemoteVideoTo(view: self.localVideoView!)
        self.initializeLocalStream()

    }

    func initializeLocalStream() {
        let streamResolutionWidth = 320
        
        let frontCamera = RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }
        var format: AVCaptureDevice.Format?
        if let frontCamera = frontCamera {
            let formatsList = RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }
            
            for item in formatsList {
                if CMVideoFormatDescriptionGetDimensions(item.formatDescription).width >= streamResolutionWidth {
                    format = item
                    break
                }
            }
        }

        self.webRTCClient.startCaptureLocalVideo(view: localVideoView!,
                                                 device: frontCamera,
                                                 format: format,
                                                 fps: 30)
    }
    
    
    @IBAction func joinButtonTouched(_ sender: Any) {
        self.joinVideoRoom()
    }
    
    @IBAction func leaveRoomButtonTouched(_ sender: Any) {
        self.sendLeaveRoom()
    }
    
    func generateLocalSdpOffer(completion: @escaping (String) -> ())
    {
        self.webRTCClient.offer { (rtcDescription) in
            return completion(rtcDescription.sdp)
        }
    }
    
    func runAudioBridgePluginSequence()
    {
        janusVBSession.createJanusSession {[unowned self] (result) in
            if result {
                self.janusVBSession.getVideoRoomsList(completion: { (result, error) in
                    print("GetStreamsList: \(String(describing: result))")
                })
                
                self.getParticipantsList()
            }
        }
    }
    
    func getParticipantsList() {
        let roomId: Int = 1234 //TODO: get correct room id
        self.janusVBSession.getVideoRoomsParticipantsList(roomId: roomId) { (result, error) in
            print("getVideoRoomsParticipantsList: \(String(describing: result))")
        }
    }
    
    func joinVideoRoom()
    {
        if (!isPlaying) {
            //request new stream
            self.sendJoinRoom()
        } else {
            //proceed play/pause/mute etc. here
        }
    }
    
    func sendJoinRoom()
    {
        let roomId: Int = Int(self.roomIdTextField.text!)!
        
        
        //as subscriber!!!!
//        let feedId: Int = Int(self.feedIdTextField.text!)!
//        self.janusVBSession.joinToVideoRoomRequest(roomId: roomId, feedId: feedId) { (error) in
//            print("Watch offer finished, error: \(String(describing: error))")
//        }
        
        //as publisher
        self.janusVBSession.publishToVideoRoomRequest(roomId: roomId) { [unowned self] (error) in
            print("Watch offer finished, error: \(String(describing: error))")
            self.webRTCClient.offer { (sdp) in
                self.janusVBSession.startPublishingToVideoRoomRequest(displayname: "Newbie", sdpOffer: sdp.sdp) { (error) in
                    print("wideo publishing started, error: \(String(describing: error))")
                    self.getParticipantsList()
                }
            }
        }
        
    }
    
    func sendLeaveRoom()
    {
        self.janusVBSession.leaveVideoRoomRequest { (error) in
            print("leave audio room request finished, error: \(String(describing: error))")
        }
    }

    func createLocalSdp()
    {
        self.webRTCClient.answer { (localSdp) in
            self.janusVBSession.sendStartCommand(sdp: localSdp.sdp, completion: { (error) in
                 print("Start request finished, error: \(String(describing: error))")
            })
        }
    }
} 

extension VideoBridgeViewController: VideoBridgeDelegate {
    
    func joinedRoom(event: JanusVideoRoomJoinedEvent) {
        print("joined to room with publishers \(String(describing: event.publishers))")
        print("joined to room with attendees \(String(describing: event.attendees))")
    }
    
    func configuredAnswerReceived(answer: JanusVideoRoomConfigureAnswer) {
        var sdpType: RTCSdpType
        if answer.jsep.type == "answer" {
            sdpType = .answer
        } else {
            sdpType = .offer
        }
        let sdp = RTCSessionDescription(type: sdpType, sdp: answer.jsep.sdp)
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            print("Set remoteSdp \(String(describing: error))")
            if (error == nil){
                self.createLocalSdp()
            }
        }
    }

}


