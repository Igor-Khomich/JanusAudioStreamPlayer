
import Foundation

public typealias Participants = [String]

public struct CreateSessionResponse: Decodable {
    let janus: String
    let transaction: String
    let data: ResponseData
    
    func isSuccessfull() -> Bool
    {
        return (janus == "success")
    }
}

public struct AttachToPluginResponse: Decodable {
    let janus: String
    let transaction: String
    let data: ResponseData
    
    func isSuccessfull() -> Bool
    {
        return (janus == "success")
    }
}

public struct ResponseData: Decodable {
    let id: Int64
}

public struct JanusEventWithJSEP: Decodable {
   public let janus: String
   public let session_id : Int64
   public let transaction : String
   public let sender : Int64
   public let plugindata : StreamingPluginData
   public let jsep : JanusJSEPData
}

public struct JanusEventWithTrickle: Codable {
   public let janus: String
   public let session_id : Int64
   public let sender : Int64
   public let candidate : JanusTrickleCandidate
}

public struct JanusTrickleLocalCandidate: Encodable {
  public let janus: String
  public let transaction : String
  public let candidate : JanusTrickleCandidate
}

public struct JanusTrickleCandidate: Encodable, Decodable {
    public let sdpMid: String
    public let sdpMLineIndex : Int32
    public let candidate : String
}

public struct JanusJSEPData: Codable  {
   public let type: String
   public let sdp : String
}

public struct JanusJSEPOUTPUTData: Codable {
    let type: String
    let sdp : String
}

public struct StreamingPluginData: Decodable {
    let plugin: String
    let data : StreamingPluginAdditionalData
}

public struct StreamingPluginAdditionalData: Decodable {
    let streaming: String
    let result : StreamingPluginStatus
}

public struct StreamingPluginStatus: Decodable {
    let status: String
}

public struct JanusMessageWithStartRequest: Encodable {
   public let janus: String
   public let transaction: String
   public let body: JanusStartRequestBody
   public let jsep: JanusJSEPData
}

public struct JanusOUTPUTMessageWithStartRequest: Encodable {
    let janus: String
    let transaction: String
    let body: JanusStartRequestBody
    let jsep: JanusJSEPOUTPUTData
}

public struct JanusStartRequestBody: Encodable {
    let request: String
}

//MARK: AUDIO BRIDGE

public struct AudioBridgeJoinedEventResponse: Codable {
    let janus: String
    let transaction: String
    let sessionId: Int64
    let sender: Int64
    let plugindata: AudiobridgeJoinedPluginData
    
    enum CodingKeys : String, CodingKey {
        case sessionId = "session_id"
        case janus = "janus"
        case transaction = "transaction"
        case sender = "sender"
        case plugindata = "plugindata"
    }
}

public struct AudiobridgeJoinedPluginData: Codable {
    let plugin: String
    let data : JanusAudioRoomJoinedEvent
}

public struct JanusAudioRoomJoinedEvent: Codable {
    public let audiobridge: String
    public let room: Int64
    public let id: Int64
    public let participants: [JanusAudioRoomParticipant]
}

public struct JanusAudioRoomParticipant: Codable {
    public let id: Int64
    public let display: String?
    public let setup: Bool
    public let muted: Bool
    public let talking: Bool?
}

public struct JanusAudioRoomConfigureRequest: Encodable {
    let janus: String
    let transaction: String
    let body: AudioBridgeUserConfig
    let jsep: JanusJSEPOUTPUTData?
}

public struct JanusAudioRoomConfigureBody: Encodable {
    let request: String
    let muted: Bool
}

public struct JanusAudioRoomConfigureAnswer: Codable {
   public let janus: String
   public let transaction: String
   public let sessionId: Int64
   public let sender: Int64
   public let plugindata: AudiobridgeConfiguredPluginData
   public let jsep: JanusJSEPData
    
    enum CodingKeys : String, CodingKey {
        case sessionId = "session_id"
        case janus = "janus"
        case transaction = "transaction"
        case sender = "sender"
        case plugindata = "plugindata"
        case jsep = "jsep"
    }
}

public struct AudiobridgeConfiguredPluginData: Codable {
   public let plugin: String
   public let data : JanusAudioRoomConfiguredEvent
}

public struct JanusAudioRoomConfiguredEvent: Codable {
   public let audiobridge: String
   public let result : String
}
