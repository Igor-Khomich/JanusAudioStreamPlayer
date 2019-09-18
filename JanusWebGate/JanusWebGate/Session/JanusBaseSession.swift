
import Foundation

public enum JanusSessionError: Error {
    case sessionWasNotInitialisedProperly
    case undefinedResponseError
}

public class JanusBaseSession<T: JanusBaseRequestsBuilder> {
        
    internal var requestBuilder: T
    
    internal var sessionId : Int64?
    {
        didSet{
            self.requestBuilder.sessionId = self.sessionId
        }
    }
    
    internal var transactionId: String
    {
        get {
            let id = Utilites.randomString(length: 12)
            self.requestBuilder.transactionId = id
            
            return id
        }
    }
    
    internal var pluginId : Int64?
    {
        didSet{
            self.requestBuilder.pluginId = self.pluginId
        }
    }

    public init(url : String) {
        self.requestBuilder = T(url: url)
    }
    
    internal func createJanusSession(completion: @escaping (Bool) -> ())
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
            self.sendLongPollEventsHandler()
            
            completion(true)
            
        }
        
        task.resume()
    }
    
    
    
    
    
    private func sendLongPollEventsHandler() // events handler and keep alive request simultaneously
    {
        print("SendLongPollEventsHandler started")
        
        let request = self.requestBuilder.createLongPollRequestWith(sessionId: self.sessionId!)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
      
            guard let data = data else {
                print("No data in LongPoll response")
                return
            }
            
            self.proceedLongPollResponseData(data)
            
            self.sendLongPollEventsHandler() //TODO: condition to stop!!!!

        }
        
        task.resume()
    }
    
    internal func proceedLongPollResponseData(_ data: Data)
    {
        fatalError("must be overriden")
    }
    
    internal func proceedResponse<T: Decodable>(_ dump: T.Type, _ data: Data?, _ response: URLResponse?, _ error: Error?) -> T? {

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
    
    internal func isResponseCorrect(_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Error? {
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
    
    internal func sendSimpleRequest(request: URLRequest, completion: @escaping (Error?) -> ())
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
