
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
