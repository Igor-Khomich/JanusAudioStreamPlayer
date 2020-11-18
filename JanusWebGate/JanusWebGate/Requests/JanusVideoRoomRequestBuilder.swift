
import Foundation

public enum RoomPType: String {
    case subscriber = "subscriber"
    case publisher = "publisher"
}

public class JanusVideoRoomRequestBuilder: JanusBaseRequestsBuilder {
    
    func createStartCommandRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String, sdp: String) -> URLRequest
    {
        let jsep = JanusJSEPOUTPUTData(type: "answer", sdp: sdp)
        let body = JanusStartRequestBody(request: "start")
        let mess = JanusOUTPUTMessageWithStartRequest(janus: "message", transaction: "\(transactionId)", body: body, jsep: jsep)
        
        let data = try? JSONEncoder().encode(mess)
        
        print("!!!!!START REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")

        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: streamPluginId)
    }
    
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
    
    func createGetVideoRoomParticipantsListRequestWith(transactionId: String, roomId: Int) -> URLRequest
    {
        let body = "{\"request\" : \"listparticipants\", \"room\" : \(roomId)}";
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
    
    func createJoinToVideoRoomRequestWith(transactionId: String, roomId: Int, feedId: Int, role: RoomPType) -> URLRequest
    {
        let body = "{\"request\" : \"join\", \"ptype\": \"\(role.rawValue)\", \"room\" : \(roomId), \"feed\" : \(feedId)}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createJoinToVideoRoomForPublishRequestWith(transactionId: String, roomId: Int) -> URLRequest
    {
        let body = "{\"request\" : \"join\", \"ptype\": \"publisher\", \"room\" : \(roomId)}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createVideoRoomPublishRequestWith(offer sdp: String, name displayName: String, transactionId: String) -> URLRequest
    {
        let jsep: JanusJSEPOUTPUTData? = JanusJSEPOUTPUTData(type: "offer", sdp: sdp)
        
        let body: VideoPublishBody = VideoPublishBody(displayName: displayName)
        
        let mess = JanusVideoRoomPublishRequest(janus: "message",
                                                transaction: "\(transactionId)",
                                                body: body,
                                                jsep: jsep)
        
        let data = try? JSONEncoder().encode(mess)
        
        print("!!!!!START createVideoRoomPublishRequestWith REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")

        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: pluginId)
    }

}
