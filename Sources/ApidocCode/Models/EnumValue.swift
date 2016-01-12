//
//  EnumValue.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct EnumValue {
    public let name: String
    public let description: String?
    public let deprecation: String?

    public init(name: String, description: String?, deprecation: String?) {
        self.name = name
        self.description = description
        self.deprecation = deprecation
    }

    public init(payload: NSDictionary) {
        let name = payload["name"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String

        self.init(name: name, description: description, deprecation: deprecation)
    }
}
