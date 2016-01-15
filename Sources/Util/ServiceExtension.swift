//
//  ServiceExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import Foundation

public extension Service {
    public func contains(type: ApidocRepresentation, typeName: String) -> Bool {
        switch type {
        case .Enum:
            return self.enums?.contains { e in
                return e.name == typeName
            } ?? false
        default:
            return false
        }
    }

//    public func getEnum(typeName: String) -> Enum {
//        switch type {
//        case .Enum:
//            return self.enums?.contains { e in
//                return e.name == typeName
//                } ?? false
//        default:
//            return false
//        }
//    }
}

public enum ApidocRepresentation: String {
    case Enum = "Enum"
    case Model = "Model"
    case Union = "Union"
    case Resource = "Resource"
}