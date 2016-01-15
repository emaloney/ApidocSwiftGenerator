//
//  Unions.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Union {
    public let name: String
    public let plural: String
    public let description: String?
    public let deprecation: String?
    public let types: [UnionType]

    public init(name: String, plural: String, description: String?, deprecation: String?, types: [UnionType]) {
        self.name = name
        self.plural = plural
        self.description = description
        self.deprecation = deprecation
        self.types = types
    }


    public init(payload: NSDictionary) {
        let name = payload["name"] as! String
        let plural = payload["plural"] as! String
        let description = payload["description"] as? String
        let deprecation = payload["deprecation"] as? String


        let types: [UnionType]
        if let typeJson = payload["types"] as? [NSDictionary] {
            types = typeJson.flatMap { ut in
                return UnionType(payload: ut)
            }
        }
        else {
            types = [UnionType]() // TODO
        }

        self.init(name: name, plural: plural, description: description, deprecation: deprecation, types: types)
    }
}
