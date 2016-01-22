//
//  ResponseCode.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public protocol ResponseCode {}

internal struct ResponseCodeImpl {
    static func toModel(payload: NSDictionary) -> ResponseCode {
        if let int = payload["integer"] as? NSDictionary {
            return int["value"] as! Int
        }
        else {
            return ResponseCodeOption(rawValue: payload["response_code_option"] as! String)!
        }
    }
}

extension Int: ResponseCode {}

extension ResponseCodeOption: ResponseCode {}