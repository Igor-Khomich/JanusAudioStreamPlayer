//
//  JanusStreamingRequestBuilder.swift
//  JanusWebGate
//
//  Created by Igor Khomich on 9/18/19.
//  Copyright © 2019 Igor Khomich. All rights reserved.
//

import Foundation

public class JanusStreamingRequestBuilder: JanusBaseRequestsBuilder {
    
    func createStartCommandRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String, sdp: String) -> URLRequest
    {
        let jsep = JanusJSEPOUTPUTData(type: "answer", sdp: sdp)
        let body = JanusStartRequestBody(request: "start")
        let mess = JanusOUTPUTMessageWithStartRequest(janus: "message", transaction: "\(transactionId)", body: body, jsep: jsep)
        
        let data = try? JSONEncoder().encode(mess)
        
        print("!!!!!START REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")

        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createTrickleCandidateRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String, candidate: String, sdpMLineIndex : Int32, sdpMid: String) -> URLRequest
    {
        let candidate = JanusTrickleCandidate(sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex, candidate: candidate)
        let body = JanusTrickleLocalCandidate(
            janus: "trickle",
            transaction : transactionId,
            candidate : candidate
        )
        
        let data = try? JSONEncoder().encode(body)
        
        print("TRICKLE REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")
        
        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func attachToStreamPluginRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"janus\":\"attach\",\"plugin\":\"janus.plugin.streaming\",\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body)
    }
    
    func createGetStreamsListRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"list\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createWatchOfferRequestWith(transactionId: String, streamId: Int) -> URLRequest
    {
        let body = "{\"request\" : \"watch\", \"id\" : \(streamId)}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createRestartActiveStreamRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"start\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createLocalCandidateCompleteRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"janus\":\"trickle\",\"candidate\":{\"completed\":true},\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body)
    }
    
    func createPauseActiveStreamRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"pause\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createStopActiveStreamRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"stop\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
}

