//
//  Field.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Field {
    public let name: String
    public let type: String
    public let description: String?
    public let deprecation: String?
    public let _default: String?
    public let required: Bool
    public let minimum: Int?
    public let maximum: Int?
    public let example: String?

    public init(name: String, type: String, description: String?, deprecation: String?, _default: String?, required: Bool, minimum: Int?, maximum: Int?, example: String?) {
        self.name = name
        self.type = type
        self.description = description
        self.deprecation = deprecation
        self._default = _default
        self.required = required
        self.minimum = minimum
        self.maximum = maximum
        self.example = example
    }


    public init(payload: NSDictionary) {
        let name = payload["name"] as! String
        let type = payload["type"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String
        let _default = payload["default"] as? String
        let required = payload["required"] as! Bool
        let minimum = payload["minimum"] as? Int
        let maximum = payload["maximum"] as? Int
        let example = payload["example"] as? String

        self.init(name: name, type: type, description: description, deprecation: deprecation, _default: _default, required: required, minimum: minimum, maximum: maximum, example: example)
    }
}
