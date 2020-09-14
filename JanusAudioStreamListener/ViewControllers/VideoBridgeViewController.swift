
import UIKit
import JanusWebGate
import WebRTC

class VideoBridgeViewController: BaseWebRtcReadyViewController {

    private let janusVBSession = JanusVideoRoomSession(url: Environment.instanceUrl)
    
    private var isPlaying = false
    @IBOutlet weak var roomIdTextField: UITextField!
    @IBOutlet weak var feedIdTextField: UITextField!
    
    @IBOutlet private weak var localVideoView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        roomIdTextField.delegate = self
        
        janusVBSession.delegate = self
        
        self.runAudioBridgePluginSequence()
        
        self.webRTCClient.renderRemoteVideoTo(view: self.localVideoView!)
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
        janusVBSession.createJanusSession { (result) in
            if result {
                self.janusVBSession.getVideoRoomsList(completion: { (result, error) in
                    print("GetStreamsList: \(String(describing: result))")
                })
                
                let roomId: Int = 1234 //TODO: get correct room id
                self.janusVBSession.getVideoRoomsParticipantsList(roomId: roomId) { (result, error) in
                    print("getVideoRoomsParticipantsList: \(String(describing: result))")
                }
            }
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
        let feedId: Int = Int(self.feedIdTextField.text!)!
        
        self.janusVBSession.joinToVideoRoomRequest(roomId: roomId, feedId: feedId) { (error) in
            print("Watch offer finished, error: \(String(describing: error))")
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
        let sdp = RTCSessionDescription(type: .offer, sdp: answer.jsep.sdp)
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            print("Set remoteSdp \(String(describing: error))")
            if (error == nil){
                self.createLocalSdp()
            }
        }
    }

}


