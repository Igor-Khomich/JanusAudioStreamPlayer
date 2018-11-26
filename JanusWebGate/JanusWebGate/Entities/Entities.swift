
import Foundation

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

public struct RTPForwardResponse: Decodable {
    let janus: String
    let transaction: String
    let sessionId: Int64
    let sender: Int64
    let plugindata: AudiobridgePluginData
    
    func isSuccessfull() -> Bool
    {
        return (janus == "success")
    }
    
    enum CodingKeys : String, CodingKey {
        case sessionId = "session_id"
        case janus = "janus"
        case transaction = "transaction"
        case sender = "sender"
        case plugindata = "plugindata"
    }
}

public struct AudiobridgePluginData: Decodable {
    let plugin: String
    let data : AudiobridgePluginAdditionalData
}

public struct AudiobridgePluginAdditionalData: Decodable {
    let audiobridge: String
    let room : Int
    let streamId : Int64
    let host : String
    let port : UInt32
    
    enum CodingKeys : String, CodingKey {
        case audiobridge = "audiobridge"
        case room = "room"
        case streamId = "stream_id"
        case host = "host"
        case port = "port"
    }
}

public struct JanusEventWithJSEP: Decodable {
    let janus: String
    let session_id : Int64
    let transaction : String
    let sender : Int64
    let plugindata : StreamingPluginData
    let jsep : JanusJSEPData
}

public struct JanusJSEPData: Codable {
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

public struct JanusStartRequestBody: Encodable {
    let request: String
}




