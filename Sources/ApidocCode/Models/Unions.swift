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
}
