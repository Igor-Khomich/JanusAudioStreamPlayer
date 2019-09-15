//
//  CreateJanusSessionRequest.swift
//  JanusWebGate
//
//  Created by Igor Khomich on 11/25/18.
//  Copyright © 2018 Igor Khomich. All rights reserved.
//

import Foundation

class JanusRequestsBuilder {
    
    private let baseUrl: String
    
    public var pluginId: Int64?
    public var sessionId: Int64?
    public var transactionId: String?

    init(url: String) {
        
        var tempUrl = url
        while tempUrl.last == "/" {
            tempUrl.removeLast()
        }
        
        self.baseUrl = tempUrl
    }
    
    func createJanusSessionRequestWith(transactionId: String) -> URLRequest
    {
        let body = "{\"janus\":\"create\",\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body)
    }
    
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
    
    func createLongPollRequestWith(sessionId: Int64) -> URLRequest
    {
        let url = URL(string: baseUrl + "/" + String(describing: sessionId))!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        return request
    }
    
    private func POSTRequestWith(body: String) -> URLRequest
    {
        let data = body.data(using: .utf8)
        
        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: pluginId)
        
    }
    
    private func POSTRequestWith(body: Data, sessionId: Int64?, pluginId: Int64?) -> URLRequest
    {
        var urlString = baseUrl
        
        if (sessionId != nil) {
            urlString = urlString + "/" + String(describing: sessionId!)
        }
        
        if (pluginId != nil) {
            urlString = urlString + "/" + String(describing: pluginId!)
        }
        
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("max-age=0", forHTTPHeaderField: "Cache-Control")
        request.httpMethod = "POST"
        
        request.httpBody = body
        
        return request
        
    }
}

private typealias AudioBridgePluginRequestsBuilder = JanusRequestsBuilder
extension AudioBridgePluginRequestsBuilder
{
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
        let body = "{\"request\" : \"configure\", \"muted\" : \"false\"}"
        let jsepOffer = "{\"type\":\"offer\",\"sdp\": \"\(sdp)\"}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body), \"jsep\" : \(jsepOffer)}"
        
        return self.POSTRequestWith(body: rBody)
    }
    
    func createJoinToAudioRoomRequestWith(transactionId: String, roomId: Int) -> URLRequest
    {
        let body = "{\"request\" : \"join\", \"room\" : \(roomId)}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody)
    }
}

private typealias StreamPluginRequestsBuilder = JanusRequestsBuilder
extension StreamPluginRequestsBuilder
{
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
