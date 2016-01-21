//
//  ModelExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/20/16.
//
//

import Foundation

extension Model {
    public func canThrow(service: Service) -> Bool {
        // Fully initialize service before calling this method
        var result = false
        fields.forEach { field in
            if result {
                return // don't do work you don't have to do ;)
            }
            if field.required {
                result = true
                return
            }
            guard let swiftType = SwiftType(apidocType: field.type, imports: service.imports) else {
                return
            }
            switch swiftType {
            case .ExternalType(let name):
                if let _ = service.getEnum(name) {
                    // enums cannot throw. They do have fialable initializers, but nil cases get flat mapped over
                    return
                } else if let modelType = service.getModel(name) {
                    if modelType.canThrow(service) {
                        result = true
                        return
                    }
                }
            case .ImportedType:
                result = true // I don't think this is going to work in all cases :'(
                return
            default:
                break
            }
        }
        return result
    }
}
