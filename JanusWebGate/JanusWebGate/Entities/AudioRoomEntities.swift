public typealias Participants = [String]

public struct AudioBridgeUserConfig: Codable {
    let request: String = "configure"
    let muted: Bool
    let displayName: String?
    let quality: UInt8?
    let volume: UInt8?

    enum CodingKeys : String, CodingKey {
        case request = "request"
        case muted = "muted"
        case displayName = "display"
        case quality = "quality"
        case volume = "volume"
    }
    
    // volume - 1..100..??  default 100
    // quality - 1..10  default 4
    public init(userName: String? = nil, muted: Bool = false, volume: UInt8? = nil, quality: UInt8? = nil) {
        self.displayName = userName
        self.muted = muted
        self.volume = volume

        if let quality = quality {
            self.quality = quality < UInt8(11) ? quality : 4
        } else {
            self.quality = nil
        }
        
    }
}

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
