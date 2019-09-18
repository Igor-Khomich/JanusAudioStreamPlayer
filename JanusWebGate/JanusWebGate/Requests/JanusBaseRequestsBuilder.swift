//
//  CreateJanusSessionRequest.swift
//  JanusWebGate
//
//  Created by Igor Khomich on 11/25/18.
//  Copyright © 2018 Igor Khomich. All rights reserved.
//

import Foundation

public class JanusBaseRequestsBuilder {
    
    private let baseUrl: String
    
    public var pluginId: Int64?
    public var sessionId: Int64?
    public var transactionId: String?

    required init(url: String) {
        
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

    func createLongPollRequestWith(sessionId: Int64) -> URLRequest
    {
        let url = URL(string: baseUrl + "/" + String(describing: sessionId))!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        return request
    }
    
    internal func POSTRequestWith(body: String) -> URLRequest
    {
        let data = body.data(using: .utf8)
        
        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: pluginId)
        
    }
    
    internal func POSTRequestWith(body: Data, sessionId: Int64?, pluginId: Int64?) -> URLRequest
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
