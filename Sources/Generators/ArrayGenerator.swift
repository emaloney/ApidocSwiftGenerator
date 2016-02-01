//
//  ArrayGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/15/16.
//
//

import Foundation
import SwiftPoet

internal struct ArrayGenerator {
    /*
    [Model]
    let fieldName = try payload.requiredArrayWithType("field_name") { 
        (json: NSDictionary) -> FieldType in
            try FieldType(payload: json)
    }
    
    [Model]?
    let fieldName = (try) payload.optionalArrayWithType("field_name") {
        (json: NSDictionary) throws -> FieldType in
            try FieldType(payload: json)
    }
    // [Model?]
    N/A

    // [Enum]
    let fieldName = try payload.requiredArrayWithType("field_name") {
        (rawValue: NSString) -> FieldType? in
            return FieldType(rawValue: rawValue as String)
    }
    // [Enum]?
    let fieldName = payload.optionalArrayWithType("field_name") {
        (rawValue: NSString) -> FieldType? in
            FieldType(rawValue: rawValue as String)
    }
    // [Enum?]
    N/A

    // [SimpleType]
    let fieldName = try payload.requiredArray("field_name").flatMap { return $0 as? FieldType }
    // [SimpleType]?
    let fieldName = payload["field_name"] as? [FieldType]
    // [SimpleType?]
    N/A
    */

    internal static func generateParseArraySimpleTypeJson(typeName: String, fieldName: String, required: Bool) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(fieldName)
        let cleanTypeName = PoetUtil.cleanTypeName(typeName)

        if required {
            return CodeBlock.builder().addLiteral("let \(cammelCaseName) = try payload.requiredArray(\"\(fieldName)\").flatMap { $0 as? \(cleanTypeName) }"
            ).build()
        } else {
            return CodeBlock.builder().addLiteral("let \(cammelCaseName) = payload[\"\(fieldName)\"] as? [\(cleanTypeName)]"
                ).build()
        }
    }

    internal static func generateParseArrayEnumJson(typeName: String, fieldName: String, required: Bool) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(fieldName)
        let cleanTypeName = PoetUtil.cleanTypeName(typeName)
        return ArrayGenerator.generateParseArrayApidocType(cammelCaseName, typeName: cleanTypeName, fieldName: fieldName, required: required, isModel: false, canThrow: false)
    }

    internal static func generateParseArrayModelJson(typeName: String, fieldName: String, required: Bool, canThrow: Bool, rootJson: Bool = false) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(fieldName)
        let cleanTypeName = PoetUtil.cleanTypeName(typeName)
        return ArrayGenerator.generateParseArrayApidocType(cammelCaseName, typeName: cleanTypeName, fieldName: fieldName, required: required, isModel: true, canThrow: canThrow)
    }

    private static func generateParseArrayApidocType(cammelCaseName: String, typeName: String, fieldName: String, required: Bool, isModel: Bool, canThrow: Bool) -> CodeBlock {
        let cb = CodeBlock.builder()
        let mustTryStr = canThrow || required ? " try" : ""
        let canThrowStr = canThrow ? "try " : ""
        let requiredStr = required ? "required" : "optional"
        let closureVarName = isModel ? "json" : "rawValue"
        let closureType = isModel ? "NSDictionary" : "NSString"
        let returnType = isModel ? typeName : "\(typeName)?"
        let initParamName = isModel ? "payload" : "rawValue"
        let convertClosureType = isModel ? "" : " as String"

        cb.addCodeLine("let \(cammelCaseName) =\(mustTryStr) payload.\(requiredStr)ArrayWithType(\"\(fieldName)\")")

        let closure = ControlFlow.closureControlFlow("\(closureVarName): \(closureType)",
            canThrow: canThrow,
            returnType: returnType) {
            return CodeBlock.builder().addLiteral("\(canThrowStr)\(typeName)(\(initParamName): \(closureVarName)\(convertClosureType))"
                ).build()
        }

        cb.addEmitObjects(closure.emittableObjects)

        return cb.build()
    }
}

// MARK: toJSON
extension ArrayGenerator {
    /*
    switch paramName.toJSON() {
    case .Succeeded(let json):
        dictName[keyName] = json
    case .Failed:
        return .Failed(DataTransactionError.DataFormatError("Invalid typeName data"))
    }
    OR
    resultJSON["file_name"] = fieldName.map { return innerType.rawValue }
    OR
    resultJSON["file_name"] = fieldName.map { return innerType.stringUUID }
    OR
    resultJSON["field_name"] = fieldName
    */
    internal static func toJsonCodeBlock(field: Field, innerType: SwiftType, service: Service) -> CodeBlock {
        return ToJsonFunctionGenerator.generate(field.cammelCaseName, required: field.required) {
            switch innerType.type {
            case .Array: fatalError()
            case .ImportedType(let namespace, let typeName):

                if service.contains(.Enum, typeName: typeName, namespace: namespace) {

                    return ArrayGenerator.leftSide(ToJsonFunctionGenerator.varName,
                        keyName: field.name.escapedString(),
                        rightSide: "\(field.cammelCaseName).map { return \(EnumGenerator.toJsonCodeBlock(nil).toString()) }")

                } else if service.contains(.Model, typeName: typeName, namespace: namespace) {

                    return ModelGenerator.toJsonCodeBlock(field.cammelCaseName,
                        dictName: ToJsonFunctionGenerator.varName,
                        keyName: field.name.escapedString(),
                        required: true,
                        typeName: typeName)

                } else if service.contains(.Union, typeName: typeName, namespace: namespace) {
                    return UnionGenerator.toJsonCodeBlock(field.cammelCaseName,
                        dictName: ToJsonFunctionGenerator.varName,
                        keyName: field.name.escapedString(),
                        required: true,
                        typeName: typeName)
                } else {
                    fatalError()
                }

            case .ServiceDefinedType(let typeName):

                if service.contains(.Enum, typeName: typeName) {
                    return ArrayGenerator.leftSide(ToJsonFunctionGenerator.varName,
                        keyName: field.name.escapedString(),
                        rightSide: "\(field.cammelCaseName).map { return \(EnumGenerator.toJsonCodeBlock(nil).toString()) }")

                } else if service.contains(.Model, typeName: typeName) {

                    return ModelGenerator.toJsonCodeBlock(field.cammelCaseName,
                        dictName: ToJsonFunctionGenerator.varName,
                        keyName: field.name.escapedString(),
                        required: true,
                        typeName: typeName)
                } else if service.contains(.Union, typeName: typeName) {
                    return UnionGenerator.toJsonCodeBlock(field.cammelCaseName,
                        dictName: ToJsonFunctionGenerator.varName,
                        keyName: field.name.escapedString(),
                        required: true,
                        typeName: typeName)

                } else {
                    fatalError()
                }

            case .SwiftString, .Long, .Integer, .Boolean, .Decimal, .Double:

                return ArrayGenerator.leftSide(ToJsonFunctionGenerator.varName,
                    keyName: field.name.escapedString(),
                    rightSide: field.cammelCaseName)

            default:
                return ArrayGenerator.leftSide(ToJsonFunctionGenerator.varName,
                    keyName: field.name.escapedString(),
                    rightSide: ArrayGenerator.mapValue(field.cammelCaseName, swiftType: innerType))
            }
        }
    }

    // fieldName.map { return $0.toStringFn() }
    private static func mapValue(paramName: String, swiftType: SwiftType) -> String {
        return "\(paramName).map { return \(swiftType.toString(nil)) }"
    }

    // resultJSON["field_name"] = `rightSide`
    private static func leftSide(dictName: String, keyName: String, rightSide: String) -> CodeBlock {
        return "\(dictName)[\(keyName)] = \(rightSide)".toCodeBlock()
    }
}
