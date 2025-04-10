//
//  HttpRequest.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/12/24.
//

import Foundation

class HttpRequest {
    
    private var components: URLComponents?
    private var request: URLRequest?
    private var retry: Int = 0
    
    init(_ url: String) {
        self.components = .init(string: url)
    }
    
    func setPath(_ path: String) -> Self {
        components?.path = path
        return self
    }
    
    func setParams(name: String, value: String?) -> Self {
        if self.components?.queryItems == nil {
            self.components?.queryItems = [
                URLQueryItem(name: name, value: value)
            ]
        } else {
            self.components?.queryItems?.append(URLQueryItem(name: name, value: value))
        }
        
        return self
    }
    
    func setMethod(_ method: String) -> Self {
        guard let url = components?.url else { return self }
        
        request = URLRequest(url: url)
        request?.httpMethod = method
        
        return self
    }
    
    func setBody(_ body: String) -> Self {
        request?.httpBody = body.data(using: .utf8)
        return self
    }
    
    func sendRequest(onSuccess: @escaping (String) -> (), onFailure: @escaping () -> ()) {
        guard let request else {
            print("request Error")
            onFailure()
            return
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                #if DEBUG
                print("HttpRequest/sendRequest: error from server - \(error)")
                #endif
                if self.retry < 2 {
                    self.retry += 1
                    self.sendRequest(onSuccess: onSuccess, onFailure: onFailure)
                } else {
                    print("retry Error")
                    onFailure()
                }
                return
            }
            guard let data else { return }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode/100 > 3 {
                    print("reponse Error")
                    onFailure()
                } else {
                    guard let str = String(data: data, encoding: .utf8) else { return }
                    print("returned Str = \(str)")
                    onSuccess(str)
                }
            }
        }
        task.resume()
    }
}
