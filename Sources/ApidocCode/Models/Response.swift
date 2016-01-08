//
//  Response.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Response {
    let code: ResponseCode
    let type: String
    let description: String?
    let deprecation: String?
}
