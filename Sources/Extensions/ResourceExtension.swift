//
//  ResourceExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/29/16.
//
//

import Foundation
import SwiftPoet

extension Resource {
    internal func capitalizedName(operation: Operation) -> String {
        return PoetUtil.cleanTypeName(self.type) + operation.capitalizedName
    }

    internal func description(operation: Operation) -> String? {
        if let left = self.description {
            if let right = operation.description {
                return "\(left) \(right)"
            }
            return left
        }
        if let right = operation.description {
            return right
        }
        return nil
    }
}
