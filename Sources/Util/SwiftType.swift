//
//  SwiftType.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/12/16.
//
//


import Foundation
import SwiftPoet

internal struct SwiftType {
    let type: SimpleSwiftType
    let optional: Bool

    private var optionalStr: String {
        return optional ? "?" : ""
    }

    internal init(apidocType: String, service: Service?, required: Bool = true) {
        self.optional = !required
        self.type = SimpleSwiftType(apidocType: apidocType, service: service)
    }

    private init(simpleSwiftType: SimpleSwiftType, required: Bool) {
        self.type = simpleSwiftType
        self.optional = !required
    }

    internal var swiftTypeString: String {
        return type.swiftTypeString
    }

    internal func toString(paramName: String?) -> String {
        let name = paramName ?? "$0"
        switch self.type {
        case .UUID:
            return "\(name)\(optionalStr).UUIDString"
        case .DateISO8601, .DateTimeISO8601:
            return "\(name)\(optionalStr).asISO8601()"
        case .Unit:
            return "nil"
        default:
            return name
        }
    }

    var asRequiredType: SwiftType {
        return SwiftType(simpleSwiftType: self.type, required: true)
    }
}

extension SwiftType {
    internal static let StringType = SwiftType(apidocType: "string", service: nil, required: true)
    internal static let Integer = SwiftType(apidocType: "integer", service: nil, required: true)
}
