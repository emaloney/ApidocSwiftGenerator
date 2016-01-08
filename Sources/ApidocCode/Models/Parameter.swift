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
}
