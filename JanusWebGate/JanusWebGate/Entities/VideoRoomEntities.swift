
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
