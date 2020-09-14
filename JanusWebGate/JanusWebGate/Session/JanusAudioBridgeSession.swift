import Foundation

public protocol AudioBridgeDelegate: class {
    func joinedRoom(event: JanusAudioRoomJoinedEvent)
    func configuredAnswerReceived(answer: JanusAudioRoomConfigureAnswer)
}

public class JanusAudioBridgeSession: JanusBaseSession<JanusAudioBridgeRequestBuilder> {
    
    public weak var delegate: AudioBridgeDelegate?

    public override func createJanusSession(completion: @escaping (Bool) -> ())
    {
        let handler = completion
        
        //TODO: refactor this
        super.createJanusSession { (result) in
            if (result) {
                
                self.attachToAudioBridgePlugin(completion: { (result) in
                    handler(result)
                })
                
            } else {
                handler(false)
            }
        }
    }
    
    public func getAudioRoomsList(completion: @escaping (String?, Error?) -> ())
    {
        print("GetRoomsList started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(nil, error)
            return
        }

        let request = self.requestBuilder.createGetAudioRoomsListRequestWith(transactionId: self.transactionId)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let responseString = String(data: data!, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            
            //TODO: parse data
            completion(responseString, error)
            
            return
        }
        
        task.resume()
    }
    
    public func sendAudioRoomConfigureRequestWith(offer sdp: String, userConfig: AudioBridgeUserConfig? = nil, completion: @escaping (Error?) -> ())
    {
        print("sendAudioRoomConfigureRequestWith started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
                
        let request = self.requestBuilder.createAudioRoomConfigureRequestWith(offer: sdp, userConfig: userConfig, transactionId: self.transactionId)
        
        self.sendSimpleRequest(request: request, completion: completion)
    }
    
    public func sendAudioRoomChangeUserDataRequestWith(userConfig: AudioBridgeUserConfig, completion: @escaping (Error?) -> ())
    {
        print("sendAudioRoomChangeUserDataRequestWith started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
                
        let request = self.requestBuilder.createAudioRoomConfigureRequestWith(offer: nil, userConfig: userConfig, transactionId: self.transactionId)
        
        self.sendSimpleRequest(request: request, completion: completion)
    }
    
    public func leaveAudioRoomRequest(completion: @escaping (Error?) -> ())
    {
       print("sendAudioRoomLeaveRequestWith started")
       
       if self.sessionId == nil || self.pluginId == nil {
           let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
           completion(error)
           return
       }
               
       let request = self.requestBuilder.createLeaveAudioRoomRequestWith(transactionId: self.transactionId)
       
       self.sendSimpleRequest(request: request, completion: completion)
   }
    
    public func joinToAudioRoomRequest(roomId: Int, completion: @escaping (Error?) -> ())
    {
        print("SendWatchOffer started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
        
        let request = self.requestBuilder.createJoinToAudioRoomRequestWith(transactionId: self.transactionId, roomId: roomId)
        
        self.sendSimpleRequest(request: request, completion: completion)
    }

    func attachToAudioBridgePlugin(completion: @escaping (Bool) -> ())
    {
        print("AttachToAudioBridgePlugin started")
        
        guard let sessionId = self.sessionId  else {
            print("sessionID must not be null")
            return
        }
                
        let request = self.requestBuilder.attachToAudioBridgePluginRequestWith(
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
        
        if (responseString.contains("jsep") && responseString.contains("audiobridge"))
        {
            self.tryParseConfiguredEvent(data: data)
        }
    }
}

typealias JanusAudioBridgeEventsParsing = JanusAudioBridgeSession
extension JanusAudioBridgeEventsParsing {

    private func tryParseConfiguredEvent(data: Data)
    {
        guard let response:JanusAudioRoomConfigureAnswer = try? JSONDecoder().decode(JanusAudioRoomConfigureAnswer.self, from: data) else
        {
            print("json decode error")
            return
        }

        self.delegate?.configuredAnswerReceived(answer: response)
    }
     
     internal func tryParseJoinedEvent(data: Data)
     {
         guard let response: AudioBridgeJoinedEventResponse = try? JSONDecoder().decode(AudioBridgeJoinedEventResponse.self, from: data) else
         {
             print("json decode error")
             return
         }
         
         self.delegate?.joinedRoom(event: response.plugindata.data)
     }
}

