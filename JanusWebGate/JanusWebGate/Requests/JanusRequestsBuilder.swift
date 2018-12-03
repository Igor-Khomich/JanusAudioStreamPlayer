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
    
    func createGetStreamsListRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"list\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createWatchOfferRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String, streamId: Int) -> URLRequest
    {
        let body = "{\"request\" : \"watch\", \"id\" : \(streamId)}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createRestartActiveStreamRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"start\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createPauseActiveStreamRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"pause\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createStopActiveStreamRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest
    {
        let body = "{\"request\" : \"stop\"}";
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createStartCommandRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String, sdp: String) -> URLRequest
    {
        let jsep = JanusJSEPData(type: "answer", sdp: sdp)
        let body = JanusStartRequestBody(request: "start")
        let mess = JanusMessageWithStartRequest(janus: "message", transaction: "\(transactionId)", body: body, jsep: jsep)
        
        let data = try? JSONEncoder().encode(mess)
        
        print("!!!!!START REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")

        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    
    func attachToStramPluginRequestWith(sessionId: Int64, transactionId: String) -> URLRequest
    {
        let body = "{\"janus\":\"attach\",\"plugin\":\"janus.plugin.streaming\",\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body, sessionId: sessionId)
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
        return self.POSTRequestWith(body: body, sessionId: nil, pluginId: nil)
    }
    
    private func POSTRequestWith(body: String, sessionId: Int64?) -> URLRequest
    {
        return self.POSTRequestWith(body: body, sessionId: sessionId, pluginId: nil)
    }
    
    private func POSTRequestWith(body: String, sessionId: Int64?, pluginId: Int64?) -> URLRequest
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
        request.httpMethod = "POST"
        
        request.httpBody = body
        
        return request
        
    }
}

