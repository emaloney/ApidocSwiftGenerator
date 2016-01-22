//
//  Resource.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Resource {
    public let type: String
    public let plural: String
    public let description: String?
    public let deprecation: String?
    public let operations: [Operation]

    public init(type: String, plural: String, description: String?, deprecation: String?, operations: [Operation]) {
        self.type = type
        self.plural = plural
        self.description = description
        self.deprecation = deprecation
        self.operations = operations
    }

    public init(payload: NSDictionary) {
        let type = payload["type"] as! String
        let plural = payload["plural"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String

        let operationJson = payload["operations"] as! [NSDictionary]
        let operations = operationJson.flatMap { json in
            return Operation(payload: json)
        }

        self.init(type: type, plural: plural, description: description, deprecation: deprecation, operations: operations)
    }
}
