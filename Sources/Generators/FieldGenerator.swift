//
//  FieldGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation
import SwiftPoet

internal struct FieldGenerator {
    internal typealias ResultType = FieldSpec

    internal static func generate(fields: [Field], service: Service) -> [ResultType] {
        return fields.map { field in
            FieldGenerator.generate(field, service: service)
        }
    }

    internal static func generate(field: Field, service: Service) -> ResultType {
        let swiftType = SwiftType(apidocType: field.type, service: service, required: field.required)

        let fb = FieldSpec.builder(field.name, type: TypeName(keyword: swiftType.swiftTypeString, optional: !field.required, imports: nil))
            .addDescription(field.description)
            .addModifier(.Public)

        switch swiftType.type {
        case .ImportedType(let namespace, _):
            fb.addImport(namespace.swiftFramework)
        default: break;
        }

        return fb.build()
    }
}


// MARK: parseJSON
extension FieldGenerator {

    internal static func jsonParseCodeBlock(field: Field, service: Service) -> CodeBlock {
        let swiftType = SwiftType(apidocType: field.type, service: service)

        switch swiftType.type {

        case .ServiceDefinedType(let typeName):
            if service.contains(.Enum, typeName: typeName) {
                return EnumGenerator.jsonParseCodeBlock(field)
            } else if service.contains(.Model, typeName: typeName)  {
                return ModelGenerator.jsonParseCodeBlock(field, service: service)
            } else if service.contains(.Union, typeName: typeName) {
                return UnionGenerator.jsonParseCodeBlock(field)
            } else {
                fatalError()
            }
        case .ImportedType(let namespace, let typeName):
            if service.contains(.Enum, typeName: typeName, namespace: namespace) {
                return EnumGenerator.jsonParseCodeBlock(field)
            } else if service.contains(.Model, typeName: typeName, namespace: namespace) {
                return ModelGenerator.jsonParseCodeBlock(field, service: service)
            } else if service.contains(.Union, typeName: typeName, namespace: namespace) {
                return UnionGenerator.jsonParseCodeBlock(field)
            } else {
                fatalError()
            }

        case .Dictionary(_, let valueType):
            return DictionaryGenerator.jsonParseCodeBlock(field, swiftType: valueType)

        case .Array(let innerType):
            switch innerType.type {
            case .ServiceDefinedType(let typeName):

                if service.contains(.Enum, typeName: typeName) {
                    return ArrayGenerator.generateParseArrayEnumJson(typeName, fieldName: field.name, required: field.required)
                } else if let modelType = service.getModel(typeName) {
                    return ArrayGenerator.generateParseArrayModelJson(typeName, fieldName: field.name, required: field.required, canThrow: modelType.canThrow(service))
                } else {
                    fatalError()
                }

            case .ImportedType(let namespace, let name):

                if service.contains(.Enum, typeName: name, namespace: namespace) {
                    return ArrayGenerator.generateParseArrayEnumJson(name, fieldName: field.name, required: field.required)
                } else if service.contains(.Model, typeName: name, namespace: namespace) {
                    return ArrayGenerator.generateParseArrayModelJson(name, fieldName: field.name, required: field.required, canThrow: true)
                } else {
                    fatalError()
                }

            case .Array:
                fatalError() // Cannot handle array of arrays

            default:
                return ArrayGenerator.generateParseArraySimpleTypeJson(innerType.swiftTypeString, fieldName: field.name, required: field.required)
            }
        default:
            return SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: swiftType)
        }
        print(field.cammelCaseName)
        fatalError()
    }
}

// MARK: toJSON
extension FieldGenerator {

    internal static func toJsonCodeBlock(field: Field, service: Service) -> CodeBlock {

        let swiftType = SwiftType(apidocType: field.type, service: service, required: field.required)

        switch swiftType.type {

        case .ServiceDefinedType(let typeName):
            if service.contains(.Enum, typeName: typeName) {
                return EnumGenerator.toJsonCodeBlock(field)
            } else if service.contains(.Model, typeName: typeName) {
                return ModelGenerator.toJsonCodeBlock(field)
            } else if service.contains(.Union, typeName: typeName) {
                return UnionGenerator.toJsonCodeBlock(field)
            } else {
                fatalError()
            }

        case .ImportedType(let namespace, let typeName):
            if service.contains(.Enum, typeName: typeName, namespace: namespace) {

                return EnumGenerator.toJsonCodeBlock(field.cammelCaseName,
                    dictName: ToJsonFunctionGenerator.varName,
                    keyName: field.name,
                    required: field.required)
                
            } else if service.contains(.Model, typeName: typeName, namespace: namespace) {

                return ModelGenerator.toJsonCodeBlock(field.cammelCaseName,
                    dictName: ToJsonFunctionGenerator.varName,
                    keyName: field.name,
                    required: field.required,
                    typeName: typeName)

            } else {
                fatalError()
            }

        case .Array(let innerType):
            return ArrayGenerator.toJsonCodeBlock(field, innerType: innerType, service: service)

        case .Dictionary(_, let rightType):
            return DictionaryGenerator.toJsonCodeBlock(field, rightType: rightType, service: service)
            
        default:
            return SimpleTypeGenerator.toJsonCodeBlock(field, swiftType: swiftType)
        }
    }
}
