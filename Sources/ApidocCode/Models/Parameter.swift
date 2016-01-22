//
//  Parameter.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Parameter {
    public let name: String
    public let type: String
    public let location: ParameterLocation
    public let description: String?
    public let deprecation: String?
    public let required: Bool
    public let _default: String?
    public let minimum: Int?
    public let maximum: Int?
    public let example: String?

    public init(name: String, type: String, location: ParameterLocation, description: String?, deprecation: String?, required: Bool, _default: String?, minimum: Int?, maximum: Int?, example: String?) {
        self.name = name
        self.type = type
        self.location = location
        self.description = description
        self.deprecation = deprecation
        self.required = required
        self._default = _default
        self.minimum = minimum
        self.maximum = maximum
        self.example = example
    }

    public init(payload: NSDictionary) {
        let name = payload["name"] as! String
        let type = payload["type"] as! String
        let location = ParameterLocation(rawValue: payload["location"] as! String)!
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String
        let required = payload["required"] as! Bool
        let _default = payload["default"] as? String
        let minimum = payload["minimum"] as? Int
        let maximum = payload["maximum"] as? Int
        let example = payload["example"] as? String

        self.init(name: name, type: type, location: location, description: description, deprecation: deprecation, required: required, _default: _default, minimum: minimum, maximum: maximum, example: example)
    }
}
