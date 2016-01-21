//
//  FieldGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation
import SwiftPoet

public struct FieldGenerator {
    public typealias ResultType = FieldSpec

    public static func generate(fields: [Field], imports: [Import]?) -> [ResultType] {
        return fields.map { field in
            FieldGenerator.generate(field, imports: imports)
        }
    }

    public static func generate(field: Field, imports: [Import]?) -> ResultType {
        let swiftType = SwiftType(apidocType: field.type, imports: imports)
        let typeStr = swiftType?.swiftTypeString ?? "nil"
        let typeName = TypeName(keyword: typeStr, optional: !field.required)
        let fb = FieldSpec.builder(field.name, type: typeName)
            .addDescription(field.description)
            .addModifier(.Public)

        if let swiftType = swiftType {
            switch swiftType {
            case .ImportedType(let namespace, _):
                fb.addImport(namespace.swiftFramework)
            default: break;
            }
        }
        return fb.build()
    }

    public static func generateJsonParse(field: Field, service: Service) -> CodeBlock {
        let cb = CodeBlock.builder()

        guard let swiftType = SwiftType(apidocType: field.type, imports: service.imports) else {
            return cb.build()
        }

        switch swiftType {

        case .ExternalType(let typeName):
            if let _ = service.getEnum(typeName) {
                cb.addCodeBlock(EnumGenerator.generateEnumParseJsonBlock(field))
            } else if let _ = service.getModel(typeName) {
                cb.addCodeBlock(ModelGenerator.generateParseModelJson(field))
            }
            break
        case .ImportedType(let namespace, let typeName):
            let importedField = field.clone(withTypeName: typeName)

            if service.contains(.Enum, typeName: typeName, namespace: namespace) {
                cb.addCodeBlock(EnumGenerator.generateEnumParseJsonBlock(importedField))
            } else if service.contains(.Model, typeName: typeName, namespace: namespace) {
                cb.addCodeBlock(ModelGenerator.generateParseModelJson(importedField))
            } else {
                fatalError()
            }

        case .Array(let innerType):
            switch innerType {
            case .ExternalType(let typeName):

                if let _ = service.getEnum(typeName) {
                    cb.addCodeBlock(ArrayGenerator.generateParseArrayEnumJson(typeName, fieldName: field.name, required: field.required))
                } else if let modelType = service.getModel(typeName) {
                    cb.addCodeBlock(ArrayGenerator.generateParseArrayModelJson(typeName, fieldName: field.name, required: field.required, canThrow: modelType.canThrow(service)))
                }

            case .ImportedType(let namespace, let name):

                if service.contains(.Enum, typeName: name, namespace: namespace) {
                    cb.addCodeBlock(ArrayGenerator.generateParseArrayEnumJson(name, fieldName: field.name, required: field.required))
                } else if service.contains(.Model, typeName: name, namespace: namespace) {
                    cb.addCodeBlock(ArrayGenerator.generateParseArrayModelJson(name, fieldName: field.name, required: field.required, canThrow: true))
                } else {
                    fatalError()
                }

            case .Array:

                fatalError() // Cannot handle array of arrays

            default:

                cb.addCodeBlock(ArrayGenerator.generateParseArraySimpleTypeJson(innerType.swiftTypeString, fieldName: field.name, required: field.required))
            }
        default:

            cb.addCodeBlock(SimpleTypeGenerator.generateParseJson(field, swiftType: swiftType))
        }

        return cb.build()
    }

    public static func toJsonCodeBlock(field: Field, service: Service) -> CodeBlock {
        let cb = CodeBlock.builder()

        guard let swiftType = SwiftType(apidocType: field.type, imports: service.imports) else {
            return cb.build()
        }

        switch swiftType {
        case .ExternalType(let typeName):
            if let _ = service.getEnum(typeName) {
                cb.addCodeBlock(EnumGenerator.toJsonFunction(field))
            } else if let _ = service.getModel(typeName) {
                cb.addCodeBlock(ModelGenerator.toJsonFunction(field))
            }
            break
        case .ImportedType(let namespace, let typeName):
            let importedField = field.clone(withTypeName: typeName)

            if service.contains(.Enum, typeName: typeName, namespace: namespace) {
                cb.addCodeBlock(EnumGenerator.toJsonFunction(importedField))
            } else if service.contains(.Model, typeName: typeName, namespace: namespace) {
                cb.addCodeBlock(ModelGenerator.toJsonFunction(importedField))
            } else {
                fatalError()
            }

        case .Array(let innerType):
            cb.addCodeBlock(ArrayGenerator.toJsonCodeBlock(field, innerType: innerType, service: service))
        default:
            cb.addCodeBlock(SimpleTypeGenerator.toJsonCodeBlock(field, swiftType: swiftType))
        }

        return cb.build()
    }
}
