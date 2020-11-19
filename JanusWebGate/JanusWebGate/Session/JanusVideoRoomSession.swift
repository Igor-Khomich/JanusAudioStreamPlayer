import Foundation

public protocol VideoBridgeDelegate: class {
    func joinedRoom(event: JanusVideoRoomJoinedEvent)
    func configuredAnswerReceived(answer: JanusVideoRoomConfigureAnswer)
}

public class JanusVideoRoomSession: JanusBaseSession<JanusVideoRoomRequestBuilder> {
    
    public weak var delegate: VideoBridgeDelegate?

    public override func createJanusSession(completion: @escaping (Bool) -> ())
    {
        let handler = completion
        
        //TODO: refactor this
        super.createJanusSession { (result) in
            if (result) {
                
                self.attachToVideoBridgePlugin(completion: { (result) in
                    handler(result)
                })
                
            } else {
                handler(false)
            }
        }
    }
    
    public func getVideoRoomsList(completion: @escaping (String?, Error?) -> ())
    {
        print("GetRoomsList started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(nil, error)
            return
        }

        let request = self.requestBuilder.createGetVideoRoomsListRequestWith(transactionId: self.transactionId)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let responseString = String(data: data!, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            
            //TODO: parse data
            completion(responseString, error)
            
            return
        }
        
        task.resume()
    }
    
    public func getVideoRoomsParticipantsList(roomId: Int,completion: @escaping (String?, Error?) -> ())
    {
        print("getVideoRoomsParticipantsList started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(nil, error)
            return
        }

        let request = self.requestBuilder.createGetVideoRoomParticipantsListRequestWith(transactionId: self.transactionId, roomId: roomId)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let responseString = String(data: data!, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            
            //TODO: parse data
            completion(responseString, error)
            
            return
        }
        
        task.resume()
    }
    
    public func leaveVideoRoomRequest(completion: @escaping (Error?) -> ())
    {
       print("sendAudioRoomLeaveRequestWith started")
       
       if self.sessionId == nil || self.pluginId == nil {
           let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
           completion(error)
           return
       }
  
       let request = self.requestBuilder.createLeaveVideoRoomRequestWith(transactionId: self.transactionId)
       
       self.sendSimpleRequest(request: request, completion: completion)
   }
    
    public func joinToVideoRoomRequest(roomId: Int, feedId: Int, completion: @escaping (Error?) -> ())
    {
        print("joinToVideoRoomRequest started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
        
        let request = self.requestBuilder.createJoinToVideoRoomRequestWith(transactionId: self.transactionId, roomId: roomId, feedId: feedId, role: .subscriber)
        
        self.sendSimpleRequest(request: request, completion: completion)
    }
    
    public func publishToVideoRoomRequest(roomId: Int, completion: @escaping (Error?) -> ())
    {
        print("joinToVideoRoomRequest started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
        
        let request = self.requestBuilder.createJoinToVideoRoomForPublishRequestWith(transactionId: self.transactionId, roomId: roomId)
        
        self.sendSimpleRequest(request: request, completion: completion)
    }
    
    public func startPublishingToVideoRoomRequest(displayname: String, sdpOffer: String, completion: @escaping (Error?) -> ())
    {
        print("startPublishingToVideoRoomRequest started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
        
        let request = self.requestBuilder.createVideoRoomPublishRequestWith(offer: sdpOffer, name: displayname, transactionId: self.transactionId)
        
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
    
    func attachToVideoBridgePlugin(completion: @escaping (Bool) -> ())
    {
        print("attachToVideoBridgePlugin started")
        
        guard let sessionId = self.sessionId  else {
            print("sessionID must not be null")
            return
        }
                
        let request = self.requestBuilder.attachToVideoBridgePluginRequestWith(
            sessionId: sessionId,
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
    
    override func proceedLongPollResponseData(_ data: Data)
    {
        let responseString: String = String(data: data, encoding: .utf8)!
        
        print("EVENT HAVE COME: \(String(describing: responseString))")
        
        if (responseString.contains("joined"))
        {
            self.tryParseJoinedEvent(data: data)
        }
        
        if (responseString.contains("jsep"))
        {
            self.tryParseConfiguredEvent(data: data)
        }
    }
}

typealias JanusVideoBridgeEventsParsing = JanusVideoRoomSession
extension JanusVideoBridgeEventsParsing {

    private func tryParseConfiguredEvent(data: Data)
    {
        guard let response: JanusVideoRoomConfigureAnswer = try? JSONDecoder().decode(JanusVideoRoomConfigureAnswer.self, from: data) else
        {
            print("json decode error")
            return
        }

        self.delegate?.configuredAnswerReceived(answer: response)
    }
     
     internal func tryParseJoinedEvent(data: Data)
     {
         guard let response: VideoBridgeJoinedEventResponse = try? JSONDecoder().decode(VideoBridgeJoinedEventResponse.self, from: data) else
         {
             print("json decode error")
             return
         }
         
         self.delegate?.joinedRoom(event: response.plugindata.data)
     }
}

