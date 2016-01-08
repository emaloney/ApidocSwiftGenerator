//
//  Operation.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

public struct Operation {
    public let method: Method
    public let path: String
    public let description: String?
    public let deprecation: String?
    public let body: Body?
    public let parameters: [Parameter]
    public let responses: [Response]?
}
