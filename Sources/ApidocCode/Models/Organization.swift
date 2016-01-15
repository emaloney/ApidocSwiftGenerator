//
//  Organization.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation

public struct Organization {
    let key: String

    public init(key: String) {
        self.key = key
    }

    public init(payload: NSDictionary) {
        let key = payload["key"] as! String

        self.init(key: key)
    }
}
