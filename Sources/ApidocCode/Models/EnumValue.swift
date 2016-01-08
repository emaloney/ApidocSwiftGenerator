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

    public init(name: String, description: String?, deprication: String?) {
        self.name = name
        self.description = description
        self.deprecation = deprication
    }

    public init(payload: NSDictionary) {
        let name = payload["name"] as! String
        let description = payload["description"] as? String
        let deprication = payload["deprication"] as? String

        self.init(name: name, description: description, deprication: deprication)
    }
}
