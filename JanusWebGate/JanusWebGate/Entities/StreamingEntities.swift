
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
