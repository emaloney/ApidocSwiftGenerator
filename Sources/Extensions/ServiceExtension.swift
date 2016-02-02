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
    internal var capitalizedName: String {
        return PoetUtil.cleanTypeName(self.name)
    }

    internal func contains(type: ApidocRepresentation, typeName: String) -> Bool {
        switch type {
        case .Enum:
            return (enums?.filter { PoetUtil.cleanTypeName($0.name) == PoetUtil.cleanTypeName(typeName) })?.count == 1
        case .Model:
            return (models?.filter { PoetUtil.cleanTypeName($0.name) == PoetUtil.cleanTypeName(typeName) })?.count == 1
        case .Union:
            return (unions?.filter { PoetUtil.cleanTypeName($0.name) == PoetUtil.cleanTypeName(typeName) })?.count == 1
        default:
            return false
        }
    }

    internal func contains(typeName: String) -> Bool {
        return (enums?.contains { $0.name == typeName }) == true || (models?.contains { $0.name == typeName }) == true || (unions?.contains { $0.name == typeName }) == true
    }

    internal func contains(type: ApidocRepresentation, typeName: String, namespace: Namespace) -> Bool {
        guard let importModel = (imports?.filter { namespace.match($0.namespace) })?.first else {
            return false
        }

        var result = false

        switch type {
        case .Enum:
            if (importModel.enums?.filter { PoetUtil.cleanTypeName($0) == PoetUtil.cleanTypeName(typeName) })?.count == 1 {
                result = true
                break
            }
        case .Model:
            if (importModel.models?.filter { PoetUtil.cleanTypeName($0) == PoetUtil.cleanTypeName(typeName) })?.count == 1 {
                result = true
                break
            }
        case .Union:
            if (importModel.unions?.filter { PoetUtil.cleanTypeName($0) == PoetUtil.cleanTypeName(typeName) })?.count == 1 {
                result = true
                break
            }
        default: break
        }
        return result
    }

    internal func getEnum(typeName: String) -> Enum? {
        return self.enums?.filter { PoetUtil.cleanTypeName($0.name) == PoetUtil.cleanTypeName(typeName) }.first
    }

    internal func getModel(typeName: String) -> Model? {
        return self.models?.filter { PoetUtil.cleanTypeName($0.name) == PoetUtil.cleanTypeName(typeName) }.first
    }

    internal func getUnion(typeName: String) -> Union? {
        return self.unions?.filter { PoetUtil.cleanTypeName($0.name) == PoetUtil.cleanTypeName(typeName) }.first
    }
}
