//
//  Generator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import Foundation

internal protocol Generator {
    typealias ResultType

    static func generate(service: Service) -> ResultType
}
