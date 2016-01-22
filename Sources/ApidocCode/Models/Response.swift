//
//  Response.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Response {
    let code: ResponseCode
    let type: String
    let description: String?
    let deprecation: String?

    public init(code: ResponseCode, type: String, description: String?, deprecation: String?) {
        self.code = code
        self.type = type
        self.description = description
        self.deprecation = deprecation
    }

    public init(payload: NSDictionary) {
        let code = ResponseCodeImpl.toModel(payload["code"] as! NSDictionary)
        let type = payload["type"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String

        self.init(code: code, type: type, description: description, deprecation: deprecation)
    }
}
