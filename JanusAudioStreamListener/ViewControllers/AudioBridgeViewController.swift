
import UIKit
import JanusWebGate
import WebRTC

class AudioBridgeViewController: BaseWebRtcReadyViewController {

    private let janusABSession = JanusAudioBridgeSession(url: Environment.instanceUrl)
    
    private var isPlaying = false
    @IBOutlet weak var roomIdTextField: UITextField!
    @IBOutlet weak var mutedSwitch: UISwitch! 
    override func viewDidLoad() {
        super.viewDidLoad()

        roomIdTextField.delegate = self
        
        janusABSession.delegate = self
        
        self.runAudioBridgePluginSequence()
    }

    @IBAction func joinButtonTouched(_ sender: Any) {
        self.joinAudioRoom()
    }
    
    @IBAction func leaveRoomButtonTouched(_ sender: Any) {
        self.sendLeaveRoom()
    }
    
    @IBAction func muteStateChanged(_ sender: UISwitch) {
        self.sendChangeUserData()
    }
    
    func generateLocalSdpOffer(completion: @escaping (String) -> ())
    {
        self.webRTCClient.offer { (rtcDescription) in
            return completion(rtcDescription.sdp)
        }
    }
    
    func runAudioBridgePluginSequence()
    {
        janusABSession.createJanusSession { (result) in
            if result {
                self.janusABSession.getAudioRoomsList(completion: { (result, error) in
                    print("GetStreamsList: \(String(describing: result))")
                })
            }
        }
    }
    
    func joinAudioRoom()
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
        
        self.janusABSession.joinToAudioRoomRequest(roomId: roomId) { (error) in
            print("Watch offer finished, error: \(String(describing: error))")
        }
    }
    
    func sendLeaveRoom()
    {
        self.janusABSession.leaveAudioRoomRequest { (error) in
            print("leave audio room request finished, error: \(String(describing: error))")
        }
    }
    
    func sendChangeUserData() {
        let userConfig = AudioBridgeUserConfig(userName: "Bugaga",
                                               muted: mutedSwitch.isOn,
                                               volume: 70,
                                               quality: 5)
               
        self.janusABSession.sendAudioRoomChangeUserDataRequestWith(userConfig: userConfig) { (error) in
            print("sendAudioRoomChangeUserDataRequestWith was sent with error: \(String(describing:error?.localizedDescription))")
        }
    }
}

extension AudioBridgeViewController: AudioBridgeDelegate {
    
    func joinedRoom(event: JanusAudioRoomJoinedEvent) {
        print("joined to room with participants \(event.participants)")
        
        var isUserMuted = false
        DispatchQueue.main.async {
            isUserMuted = self.mutedSwitch.isOn
        }
        
        self.generateLocalSdpOffer { (sdp) in
            
            let userConfig = AudioBridgeUserConfig(userName: "Bugaga",
                                                   muted: isUserMuted,
                                                   volume: 70,
                                                   quality: 5)
            
            self.janusABSession.sendAudioRoomConfigureRequestWith(offer: sdp, userConfig: userConfig) { (error) in
                print("configure request sent, error: \(String(describing: error))")
            }
        }
    }
    
    func configuredAnswerReceived(answer: JanusAudioRoomConfigureAnswer) {
        let rtc = RTCSessionDescription(type: .prAnswer, sdp: answer.jsep.sdp)
        self.webRTCClient.set(remoteSdp: rtc) { (error) in
            print("configure answer sent to WebRTC with error: \(String(describing: error))")
        }
    }

}


