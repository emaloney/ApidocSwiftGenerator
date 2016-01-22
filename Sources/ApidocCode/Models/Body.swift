//
//  Body.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Body {
    public let type: String
    public let description: String?
    public let deprecation: String?

    public init(type: String, description: String?, deprecation: String?) {
        self.type = type
        self.description = description
        self.deprecation = deprecation
    }

    public init(payload: NSDictionary) {
        let type = payload["type"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["description"] as? String

        self.init(type: type, description: description, deprecation: deprecation)
    }
}
