//
//  Namespace.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/20/16.
//
//

import Foundation
import SwiftPoet

public struct Namespace {
    let fullyQuallified: String
    let swiftFramework: String

    public init(namespace: String, applicationKey: String) {
        var components = namespace.componentsSeparatedByString(".")
        components.removeLast()

        fullyQuallified = components.joinWithSeparator(".")
        swiftFramework = PoetUtil.cleanTypeName(applicationKey)
    }

    public func match(namesapce: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: fullyQuallified, options: NSRegularExpressionOptions.CaseInsensitive)
            if regex.matchesInString(namesapce, options: [], range: NSMakeRange(0, namesapce.characters.count)).count > 0 {
                return true
            }
        } catch {
            return false
        }
        return false
    }
}
