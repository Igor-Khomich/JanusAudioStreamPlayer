//
//  JanusSreamingSession.swift
//  JanusWebGate
//
//  Created by Igor Khomich on 9/18/19.
//  Copyright © 2019 Igor Khomich. All rights reserved.
//

import Foundation

public protocol JanusStreamingSessionDelegate: class {
    func offerReceived(sdp: String)
    func trickleReceived(trickle: JanusTrickleCandidate)
    func startingEventReceived()
}

public class JanusStreamingSession: JanusBaseSession<JanusStreamingRequestBuilder> {
    
    public weak var delegate: JanusStreamingSessionDelegate?
    
    public override func createJanusSession(completion: @escaping (Bool) -> ())
    {
        let handler = completion
        
        //TODO: refactor this
        super.createJanusSession { (result) in
            if (result) {
                
                self.attachToStreamingPlugin(completion: { (result) in
                    handler(result)
                })
                
            } else {
                handler(false)
            }
        }
    }
    
    private func attachToStreamingPlugin(completion: @escaping (Bool) -> ())
    {
        print("AttachToStreamingPlugin started")
        
       if self.sessionId == nil {
            print("sessionID must not be null")
            return
        }
        
        let request = self.requestBuilder.attachToStreamPluginRequestWith(
            transactionId: self.transactionId
        )
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let attachResponse = self.proceedResponse(AttachToPluginResponse.self, data, response, error)

            guard let result = attachResponse else {
                completion(false)
                return
            }
            
            if (result.isSuccessfull())
            {
                self.pluginId = result.data.id
                completion(true)
            }
        }
        
        task.resume()
    }
    
    public func sendLocalCandidateComplete(completion: @escaping (Error?) -> ())
    {
        print("SendLocalCandidateComplete started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }

        let request = self.requestBuilder.createLocalCandidateCompleteRequestWith(
            transactionId: self.transactionId
        )
        
        self.sendSimpleRequest(request: request, completion: completion)
        
    }
    
    public func sendLocalCandidate(candidate: String, sdpMLineIndex : Int32, sdpMid: String, completion: @escaping (Error?) -> ())
    {
        print("SendLocalCandidate started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.pluginId  else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }
            
        let request = self.requestBuilder.createTrickleCandidateRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId,
            candidate: candidate,
            sdpMLineIndex : sdpMLineIndex,
            sdpMid: sdpMid
        )
        
        self.sendSimpleRequest(request: request, completion: completion)
    }
    
    public func getStreamsList(completion: @escaping (String?, Error?) -> ())
    {
        print("AddStreamsList started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(nil, error)
            return
        }
        
       let request = self.requestBuilder.createGetStreamsListRequestWith(
        transactionId: self.transactionId
        )
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let responseString = String(data: data!, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            
            //TODO: parse data
            completion(responseString, error)
            
            return
        }
        
        task.resume()
    }
    
    public func sendWatchRequest(streamId: Int, completion: @escaping (Error?) -> ())
    {
        print("SendWatchOffer started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
        
       let request = self.requestBuilder.createWatchOfferRequestWith(
        transactionId: self.transactionId,
        streamId: streamId
        )
        
        self.sendSimpleRequest(request: request, completion: completion)

    }
    
    public func sendStartCommand(sdp: String, completion: @escaping (Error?) -> ())
    {
        print("SendStartCommand started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.pluginId  else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }

       let request = self.requestBuilder.createStartCommandRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId,
            sdp: sdp
        )
        
        self.sendSimpleRequest(request: request, completion: completion)

    }
   
    public func sendReStartPausedStreamCommand(completion: @escaping (Error?) -> ())
    {
        print("SendReStartPausedStreamCommand started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
 
        let request = self.requestBuilder.createRestartActiveStreamRequestWith(
            transactionId: self.transactionId
        )
        
        self.sendSimpleRequest(request: request, completion: completion)

    }
    
    public func sendPauseStreamCommand(completion: @escaping (Error?) -> ())
    {
        print("SendPauseStreamCommand started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }

        let request = self.requestBuilder.createPauseActiveStreamRequestWith(
            transactionId: self.transactionId
        )
        
        self.sendSimpleRequest(request: request, completion: completion)

    }
    
    public func sendStopStreamCommand(completion: @escaping (Error?) -> ())
    {
        print("SendStopStreamCommand started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
        
        let request = self.requestBuilder.createStopActiveStreamRequestWith(
            transactionId: self.transactionId
        )
        
        self.sendSimpleRequest(request: request, completion: completion)
    }
    
    override func proceedLongPollResponseData(_ data: Data)
    {
        let responseString: String = String(data: data, encoding: .utf8)!
        
        print("EVENT HAVE COME: \(String(describing: responseString))")
    
        //TODO: we need better way to classify data type
        if (responseString.contains("starting"))
        {
            self.delegate?.startingEventReceived()
        }
    
        if (responseString.contains("offer"))
        {
            self.tryParseSEPOffer(data: data)
        }
        
        if (responseString.contains("trickle"))
        {
            self.tryParseTrickle(data: data)
        }

    }
}

typealias JanusStreamingEventsParsing = JanusStreamingSession
extension JanusStreamingEventsParsing {

       internal func tryParseTrickle(data: Data)
       {
           guard let response:JanusEventWithTrickle = try? JSONDecoder().decode(JanusEventWithTrickle.self, from: data) else
           {
               print("json decode error")
               return
           }

          self.delegate?.trickleReceived(trickle: response.candidate)
       }
       
       internal func tryParseSEPOffer(data: Data)
       {
           guard let response:JanusEventWithJSEP = try? JSONDecoder().decode(JanusEventWithJSEP.self, from: data) else
           {
               print("json decode error")
               return
           }
           
           self.delegate?.offerReceived(sdp: response.jsep.sdp)
       }
}
