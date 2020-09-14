
import Foundation

public class JanusVideoRoomRequestBuilder: JanusBaseRequestsBuilder {
    
    func attachToVideoBridgePluginRequestWith(sessionId: Int64, transactionId: String) -> URLRequest
    {
        let body = "{\"janus\":\"attach\",\"plugin\":\"janus.plugin.videoroom\",\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body)
    }
    
    func createGetVideoRoomsListRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"list\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createVideoRoomConfigureRequestWith(offer sdp: String?, userConfig: AudioBridgeUserConfig?, transactionId: String) -> URLRequest
    {
        var jsep: JanusJSEPOUTPUTData? = nil
        if let sdp = sdp {
           jsep = JanusJSEPOUTPUTData(type: "offer", sdp: sdp)
        }
        
        var body: AudioBridgeUserConfig
        
        if let userConfig = userConfig {
            body = userConfig
        } else {
            body = AudioBridgeUserConfig()
        }
        
        let mess = JanusAudioRoomConfigureRequest(janus: "message", transaction: "\(transactionId)", body: body, jsep: jsep)
        
        let data = try? JSONEncoder().encode(mess)
        
        print("!!!!!START createAudioRoomConfigureRequestWith REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")

        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: pluginId)
    }
    
    func createLeaveVideoRoomRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"leave\"}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createJoinToVideoRoomRequestWith(transactionId: String, roomId: Int) -> URLRequest
    {
        let body = "{\"request\" : \"join\", \"ptype\": \"publisher\", \"room\" : \(roomId)}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }


}
