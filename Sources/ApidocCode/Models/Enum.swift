//
//  Enum.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Enum {
    public let name: String
    public let plural: String
    public let description: String?
    public let deprecation: String?
    public let values: [EnumValue]

    public init(name: String, plural: String, description: String?, deprecation: String?, values: [EnumValue]) {
        self.name = name
        self.plural = plural
        self.description = description
        self.deprecation = deprecation
        self.values = values
    }

    public init(payload: NSDictionary) {
        let name = payload["name"] as! String
        let plural = payload["plural"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String


        let values: [EnumValue]
        if let valueJson = payload["values"] as? [NSDictionary] {
            values = valueJson.flatMap { v in
                return EnumValue(payload: v)
            }
        }
        else {
            values = [EnumValue]() // TODO
        }

        self.init(name: name, plural: plural, description: description, deprecation: deprecation, values: values)
    }
}
