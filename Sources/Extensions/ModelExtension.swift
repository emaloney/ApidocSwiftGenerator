//
//  ModelExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/20/16.
//
//

import Foundation

extension Model {
    internal func canThrow(service: Service) -> Bool {
        // Fully initialize service before calling this method
        for field in fields {
            if field.required {
                return true
            }

            switch SwiftType(apidocType: field.type, service: service, required: field.required).type {
            case .ServiceDefinedType(let name):
                if service.contains(.Enum, typeName: name) {
                    // enums cannot throw. They do have failable initializers, but nil cases get flat mapped over
                    continue
                } else if let modelType = service.getModel(name) {
                    if modelType.canThrow(service) {
                        return true
                    }
                    break
                } else if let _ = service.getUnion(name) {
                    return true
                }
            case .ImportedType:
                return true // Not all imported types can fail but we don't know that so air on the side of caution
            default:
                continue
            }
        }
        return true
    }
}
