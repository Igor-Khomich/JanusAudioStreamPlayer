
import Foundation

public enum JanusSessionError: Error {
    case sessionWasNotInitialisedProperly
    case undefinedResponseError
}

public protocol JanusSessionDelegate: class {
    func offerReceived(sdp: String)
    func trickleReceived(trickle: JanusTrickleCandidate)
    func startingEventReceived()
}

public protocol AudioBridgeDelegate: class {
    func joinedRoom(event: JanusAudioRoomJoinedEvent)
    func configuredAnswerReceived(answer: JanusAudioRoomConfigureAnswer)
}

public class JanusSession{
    
    private var requestBuilder: JanusRequestsBuilder
    
    private var sessionId : Int64?
    {
        didSet{
            self.requestBuilder.sessionId = self.sessionId
        }
    }
    
    private var transactionId: String
    {
        get {
            let id = Utilites.randomString(length: 12)
            self.requestBuilder.transactionId = id
            
            return id
        }
    }
    
    private var pluginId : Int64?
    {
        didSet{
            self.requestBuilder.pluginId = self.pluginId
        }
    }

    public weak var delegate: JanusSessionDelegate?
    public weak var audioBridgeDelegate: AudioBridgeDelegate?
    
    public init(url : String) {
        self.requestBuilder = JanusRequestsBuilder(url: url)
    }
    
    private func CreateJanusSession(completion: @escaping (Bool) -> ())
    {
        print("CreateJanusSession started")
        
        let request = self.requestBuilder.createJanusSessionRequestWith(transactionId: self.transactionId)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let createResponse = self.proceedResponse(CreateSessionResponse.self, data, response, error)
            
            guard let result = createResponse else {
                completion(false)
                return
            }
            
            self.sessionId = result.data.id
            self.SendLongPollEventsHandler()
            completion(true)
            
        }
        
        task.resume()
    }
    
    public func SendLocalCandidate(candidate: String, sdpMLineIndex : Int32, sdpMid: String, completion: @escaping (Error?) -> ())
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
        
        self.SendSimpleRequest(request: request, completion: completion)
        
    }
    
    func SendLocalCandidateComplete(completion: @escaping (Error?) -> ())
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
        
        self.SendSimpleRequest(request: request, completion: completion)
        
    }
    
    private func SendLongPollEventsHandler() // events handler and keep alive request simultaneously
    {
        print("SendLongPollEventsHandler started")
        
        let request = self.requestBuilder.createLongPollRequestWith(sessionId: self.sessionId!)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
      
            guard let data = data else {
                print("No data in LongPoll response")
                return
            }
            
            self.proceedLongPollResponseData(data)
            
            self.SendLongPollEventsHandler() //TODO: condition to stop!!!!

        }
        
        task.resume()
    }
    
    private func proceedLongPollResponseData(_ data: Data)
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
        
        if (responseString.contains("joined"))
        {
            self.tryParseJoinedEvent(data: data)
        }
        
        if (responseString.contains("jsep") && responseString.contains("audiobridge"))
        {
            self.tryParseConfiguredEvent(data: data)
        }
    }
    
    public func tryParseConfiguredEvent(data: Data)
    {
        guard let response:JanusAudioRoomConfigureAnswer = try? JSONDecoder().decode(JanusAudioRoomConfigureAnswer.self, from: data) else
        {
            print("json decode error")
            return
        }

        self.audioBridgeDelegate?.configuredAnswerReceived(answer: response)
    }
    
    public func tryParseJoinedEvent(data: Data)
    {
        guard let response: AudioBridgeJoinedEventResponse = try? JSONDecoder().decode(AudioBridgeJoinedEventResponse.self, from: data) else
        {
            print("json decode error")
            return
        }
        
        self.audioBridgeDelegate?.joinedRoom(event: response.plugindata.data)
    }
    
    public func tryParseTrickle(data: Data)
    {
        guard let response:JanusEventWithTrickle = try? JSONDecoder().decode(JanusEventWithTrickle.self, from: data) else
        {
            print("json decode error")
            return
        }

       self.delegate?.trickleReceived(trickle: response.candidate)
    }
    
    public func tryParseSEPOffer(data: Data)
    {
        guard let response:JanusEventWithJSEP = try? JSONDecoder().decode(JanusEventWithJSEP.self, from: data) else
        {
            print("json decode error")
            return
        }
        
        self.delegate?.offerReceived(sdp: response.jsep.sdp)
    }
    
}

private typealias StreamingPlugin = JanusSession
public extension StreamingPlugin
{
    func CreaseStreamingPluginSession(completion: @escaping (Bool) -> ())
    {
        let handler = completion
        
        //TODO: refactor this
        self.CreateJanusSession { (result) in
            if (result) {
                
                self.AttachToStreamingPlugin(completion: { (result) in
                    handler(result)
                })
                
            } else {
                handler(false)
            }
        }
    }
    
    private func AttachToStreamingPlugin(completion: @escaping (Bool) -> ())
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
    
    func GetStreamsList(completion: @escaping (String?, Error?) -> ())
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
    
    func SendWatchRequest(streamId: Int, completion: @escaping (Error?) -> ())
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
        
        self.SendSimpleRequest(request: request, completion: completion)

    }
    
    func SendStartCommand(sdp: String, completion: @escaping (Error?) -> ())
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
        
        self.SendSimpleRequest(request: request, completion: completion)

    }
   
    func SendReStartPausedStreamCommand(completion: @escaping (Error?) -> ())
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
        
        self.SendSimpleRequest(request: request, completion: completion)

    }
    
    func SendPauseStreamCommand(completion: @escaping (Error?) -> ())
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
        
        self.SendSimpleRequest(request: request, completion: completion)

    }
    
    func SendStopStreamCommand(completion: @escaping (Error?) -> ())
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
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    private func SendSimpleRequest(request: URLRequest, completion: @escaping (Error?) -> ())
    {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //TODO: Expecting starting in long poll
            let error = self.isResponseCorrect(data, response as? HTTPURLResponse, error)
            completion(error)
            return
        }
        
        task.resume()
    }
    
}

private typealias RequestsProcessing = JanusSession
public extension RequestsProcessing
{
    private func proceedResponse<T: Decodable>(_ dump: T.Type, _ data: Data?, _ response: URLResponse?, _ error: Error?) -> T? {

        guard let data = data else {
            return nil
        }
        
        let responseString = String(data: data, encoding: .utf8)
        print("responseString = \(String(describing: responseString))")
        
        guard let result = try? JSONDecoder().decode(T.self, from: data) else
        {
            print("json decode error")
            return nil
        }
        
        return result
    }
    
    private func isResponseCorrect(_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Error? {
        if error != nil  {
            return error
        }
        
        if (response == nil || data == nil)
        {
            return JanusWebGateError.runtimeError("Network errror, unexpected response format")
        }
        
        if (response!.statusCode < 200 || response!.statusCode >= 300)  {
            return JanusWebGateError.runtimeError("Network errror, unexpected status code: \(response!.statusCode)")
        }
        
        return nil
        
    }
}

private typealias AudioBridgePlugin = JanusSession
public extension AudioBridgePlugin
{
    func CreaseAudioBridgePluginSession(completion: @escaping (Bool) -> ())
    {
        let handler = completion
        
        //TODO: refactor this
        self.CreateJanusSession { (result) in
            if (result) {
                
                self.AttachToAudioBridgePlugin(completion: { (result) in
                    handler(result)
                })
                
            } else {
                handler(false)
            }
        }
    }
    
    func GetAudioRoomsList(completion: @escaping (String?, Error?) -> ())
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
    
    public func sendAudioRoomConfigureRequestWith(offer sdp: String, completion: @escaping (Error?) -> ())
    {
        print("sendAudioRoomConfigureRequestWith started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
                
        let request = self.requestBuilder.createAudioRoomConfigureRequestWith(offer: sdp, transactionId: self.transactionId)
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    func JoinToAudioRoomRequest(roomId: Int, completion: @escaping (Error?) -> ())
    {
        print("SendWatchOffer started")
        
        if self.sessionId == nil || self.pluginId == nil {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(error)
            return
        }
        
        let request = self.requestBuilder.createJoinToAudioRoomRequestWith(transactionId: self.transactionId, roomId: roomId)
        
        self.SendSimpleRequest(request: request, completion: completion)
    }

    func AttachToAudioBridgePlugin(completion: @escaping (Bool) -> ())
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

}
