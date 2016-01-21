//
//  ServiceExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import Foundation
import SwiftPoet

public extension Service {
    public func contains(type: ApidocRepresentation, typeName: String) -> Bool {
        switch type {
        case .Enum:
            return (enums?.filter { $0.name == typeName })?.count == 1
        case .Model:
            return (models?.filter { $0.name == typeName })?.count == 1
        default:
            return false
        }
    }

    public func contains(type: ApidocRepresentation, typeName: String, namespace: Namespace) -> Bool {
        guard let importModel = (imports?.filter { namespace.match($0.namespace) })?.first else {
            return false
        }

        var result = false

        switch type {
        case .Enum:
            if (importModel.enums?.filter { PoetUtil.cleanTypeName($0) == typeName })?.count == 1 {
                result = true
                break
            }
        case .Model:
            if (importModel.models?.filter { PoetUtil.cleanTypeName($0) == typeName })?.count == 1 {
                result = true
                break
            }
        default: break
        }
        return result
    }

    public func getEnum(typeName: String) -> Enum? {
        return self.enums?.filter { $0.name == typeName }.first
    }

    public func getModel(typeName: String) -> Model? {
        return self.models?.filter { $0.name == typeName }.first
    }
}

public enum ApidocRepresentation: String {
    case Enum = "Enum"
    case Model = "Model"
    case Union = "Union"
    case Resource = "Resource"
}