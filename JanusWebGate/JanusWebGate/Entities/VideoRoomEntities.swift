
public struct JanusVideoRoomJoinedEvent: Codable {
    public let videoroom: String
    public let room: Int64
    public let description: String
    public let id: Int64
    public let private_id: Int64
    
    public let publishers: [JanusVideoRoomPublisher]?
    public let attendees: [JanusVideoRoomAttendee]?
}

public struct JanusVideoRoomPublisher: Codable {
    public let id: Int64
    public let display: String
    public let audio_codec: String
    public let video_codec: String
    public let simulcast: String
    public let talking: Bool
}

public struct JanusVideoRoomAttendee: Codable {
    public let id: Int64
    public let display: String
}

public struct JanusVideoRoomConfigureAnswer: Codable {
   public let janus: String
   public let transaction: String
   public let sessionId: Int64
   public let sender: Int64
   public let jsep: JanusJSEPData
    
    enum CodingKeys : String, CodingKey {
        case sessionId = "session_id"
        case janus = "janus"
        case transaction = "transaction"
        case sender = "sender"
        case jsep = "jsep"
    }
}

// MARK: RESPONSES
// MARK: ---------

public struct VideoBridgeJoinedEventResponse: Codable {
    let janus: String
    let transaction: String
    let sessionId: Int64
    let sender: Int64
    let plugindata: VideoBridgeJoinedPluginData
    
    enum CodingKeys : String, CodingKey {
        case sessionId = "session_id"
        case janus = "janus"
        case transaction = "transaction"
        case sender = "sender"
        case plugindata = "plugindata"
    }
}

public struct VideoBridgeJoinedPluginData: Codable {
    let plugin: String
    let data : JanusVideoRoomJoinedEvent
}

public struct JanusVoideoRoomJoinedEvent: Codable {
    public let audiobridge: String
    public let room: Int64
    public let id: Int64
    public let participants: [JanusVideoRoomParticipant]
}

public struct JanusVideoRoomParticipant: Codable {
    public let id: Int64
    public let display: String?
    public let setup: Bool
    public let muted: Bool
    public let talking: Bool?
}

public struct JanusVideoRoomErrorResponse: Codable
{
    public let videoroom: String
    public let error_code: Int64
    public let error: String
}

public struct JanusVideoRoomPublishRequest: Encodable {
    let janus: String
    let transaction: String
    let body: VideoPublishBody
    let jsep: JanusJSEPOUTPUTData?
}

public struct VideoPublishBody: Codable {
    let request: String = "configure"
    let displayName: String?
    let audio: Bool = true
    let video: Bool = true
    
    enum CodingKeys : String, CodingKey {
        case request = "request"
        case displayName = "display"
        case audio = "audio"
        case video = "video"
    }
}
