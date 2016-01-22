//
//  StringUtil.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/21/16.
//
//

import Foundation


internal struct StringUtil {
    static func concat(left: String?, right: String?) -> String? {
        if let left = left {
            if let right = right {
                return "\(left) \(right)"
            }
            return left
        }
        if let right = right {
            return right
        }
        return nil
    }
}