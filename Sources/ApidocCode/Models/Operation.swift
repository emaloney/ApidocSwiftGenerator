//
//  Operation.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Operation {
    public let method: Method
    public let path: String
    public let description: String?
    public let deprecation: String?
    public let body: Body?
    public let parameters: [Parameter]
    public let responses: [Response]?

    public init(method: Method, path: String, description: String?, deprecation: String?, body: Body?, parameters: [Parameter], responses: [Response]?) {
        self.method = method
        self.path = path
        self.description = description
        self.deprecation = deprecation
        self.body = body
        self.parameters = parameters
        self.responses = responses
    }

    public init(payload: NSDictionary) {
        let method = Method(rawValue: payload["method"] as! String)!
        let path = payload["path"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String

        let bodyJson = payload["body"] as? NSDictionary
        var body: Body? = nil
        if let bodyJson = bodyJson {
            body = Body(payload: bodyJson)
        }

        let parametersJson = payload["parameters"] as! [NSDictionary]
        let parameters = parametersJson.flatMap { json in
            return Parameter(payload: json)
        }

        let responseJson = payload["responses"] as? [NSDictionary]
        let responses = responseJson?.flatMap { json in
            return Response(payload: json)
        }

        self.init(method: method, path: path, description: description, deprecation: deprecation, body: body, parameters: parameters, responses: responses)
    }
}
