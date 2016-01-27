//
//  ArrayGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/15/16.
//
//

import Foundation
import SwiftPoet

public struct ArrayGenerator {
    /*
    [Model]
    let fieldName = try payload.requiredArrayWithType("field_name") { 
        (json: NSDictionary) -> FieldType in
            try FieldType(payload: json)
    }
    
    [Model]?
    let fieldName = try payload.optionalArrayWithType("field_name") {
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

    public static func generateParseArraySimpleTypeJson(typeName: String, fieldName: String, required: Bool) -> CodeBlock {
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

    public static func generateParseArrayEnumJson(typeName: String, fieldName: String, required: Bool) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(fieldName)
        let cleanTypeName = PoetUtil.cleanTypeName(typeName)
        return ArrayGenerator.generateParseArrayApidocType(cammelCaseName, typeName: cleanTypeName, fieldName: fieldName, required: required, isModel: false, canThrow: false)
    }

    public static func generateParseArrayModelJson(typeName: String, fieldName: String, required: Bool, canThrow: Bool, rootJson: Bool = false) -> CodeBlock {
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

    /*
    switch fieldName.toJson() {
    case .Succeeded(let json):
        resultJSON[OrderPayloadKey.PaymentMethods.rawValue] = json
    case .Failed:
        return .Failed(DataTransactionError.FormatError("Invalid FieldType data"))
    }
    OR
    resultJSON["file_name"] = fieldName.map { return innerType.rawValue }
    OR
    resultJSON["file_name"] = fieldName.map { return innerType.stringUUID }
    OR
    resultJSON["field_name"] = fieldName
    */
    public static func toJsonCodeBlock(field: Field, innerType: SwiftType, service: Service) -> CodeBlock {
        return ToJsonFunctionGenerator.generate(field) { field in
            switch innerType {
            case .Array: fatalError()
            case .ImportedType(let namespace, let typeName):
                if service.contains(.Enum, typeName: typeName, namespace: namespace) {
                    return ArrayGenerator.toJsonCodeBlock(field) {
                        return ArrayGenerator.rightSideWithMap(field) { return EnumGenerator.toJsonCodeBlock() }
                    }
                } else if service.contains(.Model, typeName: typeName, namespace: namespace) {
                    return ArrayGenerator.toJsonCodeBlockArray(field)
                } else {
                    fatalError()
                }
            case .ExternalType(let typeName):
                if service.contains(.Enum, typeName: typeName) {
                    return ArrayGenerator.toJsonCodeBlock(field) {
                        return ArrayGenerator.rightSideWithMap(field) { return EnumGenerator.toJsonCodeBlock() }
                    }
                } else if service.contains(.Model, typeName: typeName) {
                    return ArrayGenerator.toJsonCodeBlockArray(field)
                } else {
                    fatalError()
                }
            default:
                guard let rightSide = SimpleTypeGenerator.toString(innerType) else {
                    return ArrayGenerator.toJsonCodeBlock(field) {
                        return CodeBlock.builder().addLiteral(field.cammelCaseName).build()
                    }
                }
                return ArrayGenerator.toJsonCodeBlock(field) {
                    return ArrayGenerator.rightSideWithMap(field) { return CodeBlock.builder().addLiteral("\(field.cammelCaseName).\(rightSide)").build() }
                }
            }
        }
    }

    private static func toJsonCodeBlock(field: Field, innerFn: () -> CodeBlock) -> CodeBlock {
        return CodeBlock.builder().addLiteral("\(MethodGenerator.toJSONVarName)[\"\(field.name)\"] = \(innerFn().toString())"
        ).build()
    }

    private static func rightSideWithMap(field: Field, innerFn: () -> CodeBlock) -> CodeBlock {
        return CodeBlock.builder().addLiteral("\(field.cammelCaseName).map { return \(innerFn().toString()) }"
        ).build()
    }

    /*
    switch fieldName.toJson() {
    case .Succeeded(let json):
        result["field_name"] = json
    case .Failed:
        return .Failed(DataTransactionError.FormatError("Invalid FieldType data"))
    }
    */
    private static func toJsonCodeBlockArray(field: Field) -> CodeBlock {
        return ControlFlow.switchControlFlow("\(field.cammelCaseName).toJSON()", cases:
            [(".Succeeded(let json)", CodeBlock.builder().addLiteral("\(MethodGenerator.toJSONVarName)[\"\(field.name)\"] = json").build()),
            (".Failed", CodeBlock.builder().addLiteral("return .Failed(DataTransactionError.FormatError(\"Invalid \(field.cleanTypeName) data\"))").build())]
        )
    }
}
