//
//  StringExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/21/16.
//
//

import Foundation

extension String {
    internal func escapedString() -> String {
        return "\"\(self)\""
    }
}
