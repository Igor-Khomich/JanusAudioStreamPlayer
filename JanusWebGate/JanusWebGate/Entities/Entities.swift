
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
    let janus: String
    let session_id : Int64
    let transaction : String
    let sender : Int64
    let plugindata : StreamingPluginData
    let jsep : JanusJSEPData
}

public struct JanusEventWithTrickle: Codable {
    let janus: String
    let session_id : Int64
    let sender : Int64
    let candidate : JanusTrickleCandidate
}

public struct JanusTrickleLocalCandidate: Encodable {
    let janus: String
    let transaction : String
    let candidate : JanusTrickleCandidate
}

public struct JanusTrickleCandidate: Encodable, Decodable {
    public let sdpMid: String
    public let sdpMLineIndex : Int32
    public let candidate : String
}

public struct JanusJSEPData: Encodable, Decodable  {
    let type: String
    let sdp : String
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
    let janus: String
    let transaction: String
    let body: JanusStartRequestBody
    let jsep: JanusJSEPData
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

