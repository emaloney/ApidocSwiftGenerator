//
//  Model.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Model {
    public let name: String
    public let plural: String
    public let description: String?
    public let deprecation: String?
    public let fields: [Field]

    public init(name: String, plural: String, description: String?, deprecation: String?, fields: [Field]) {
        self.name = name
        self.plural = plural
        self.description = description
        self.deprecation = deprecation
        self.fields = fields
    }


    public init(payload: NSDictionary) {
        let name = payload["name"] as! String
        let plural = payload["plural"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String


        let fields: [Field]
        if let fieldJson = payload["fields"] as? [NSDictionary] {
            fields = fieldJson.flatMap { f in
                return Field(payload: f)
            }
        }
        else {
            fields = [Field]() // TODO
        }

        self.init(name: name, plural: plural, description: description, deprecation: deprecation, fields: fields)
    }
}
