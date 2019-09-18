//
//  JanusAudioRoomRequestBuilder.swift
//  JanusWebGate
//
//  Created by Igor Khomich on 9/18/19.
//  Copyright © 2019 Igor Khomich. All rights reserved.
//

import Foundation

public class JanusAudioBridgeRequestBuilder: JanusBaseRequestsBuilder {
    
    func attachToAudioBridgePluginRequestWith(sessionId: Int64, transactionId: String) -> URLRequest
    {
        let body = "{\"janus\":\"attach\",\"plugin\":\"janus.plugin.audiobridge\",\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body)
    }
    
    func createGetAudioRoomsListRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"list\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createAudioRoomConfigureRequestWith(offer sdp: String, transactionId: String) -> URLRequest
    {
        
        let jsep = JanusJSEPOUTPUTData(type: "offer", sdp: sdp)
        let body = JanusAudioRoomConfigureBody(request: "configure", muted: false)
        let mess = JanusAudioRoomConfigureRequest(janus: "message", transaction: "\(transactionId)", body: body, jsep: jsep)
        
        let data = try? JSONEncoder().encode(mess)
        
        print("!!!!!START createAudioRoomConfigureRequestWith REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")

        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: pluginId)
    }
    
    
    
    func createJoinToAudioRoomRequestWith(transactionId: String, roomId: Int) -> URLRequest
    {
        let body = "{\"request\" : \"join\", \"muted\": false, \"quality\": 5, \"volume\": 100, \"room\" : \(roomId)}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }

}
