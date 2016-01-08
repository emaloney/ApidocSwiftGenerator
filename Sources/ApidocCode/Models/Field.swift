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
    public let minimin: Int?
    public let maximum: Int?
    public let example: String?
}
