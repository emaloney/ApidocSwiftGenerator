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
    let fieldName = try payload.requiredArray("field_name") as! [FieldType]
    // [SimpleType]?
    let fieldName = payload["field_name"] as? [FieldType]
    // [SimpleType?]
    N/A
    */

    public static func generateParseArrayJson(typeName: String, fieldName: String, required: Bool, isModel: Bool) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(fieldName)
        let cleanTypeName = PoetUtil.cleanTypeName(typeName)

        return testInner(cammelCaseName, typeName: cleanTypeName, fieldName: fieldName, required: required, isModel: isModel, canThrow: true)
    }

    private static func testInner(cammelCaseName: String, typeName: String, fieldName: String, required: Bool, isModel: Bool, canThrow: Bool) -> CodeBlock {
        let globalCB = CodeBlock.builder()
        let mustTryStr = canThrow || required ? "try" : ""
        let requiredStr = required ? "required" : "optional"
        let closureVarName = isModel ? "json" : "rawValue"
        let closureType = isModel ? "NSDictionary" : "NSString"
        let returnType = isModel ? typeName : "\(typeName)?"
        let initParamName = isModel ? "payload" : "rawValue"
        let convertClosureType = isModel ? "" : " as String"

        globalCB.addEmitObject(.Literal, any:
            "let \(cammelCaseName) = \(mustTryStr) payload.\(requiredStr)ArrayWithType(\"\(fieldName)\")")


        let parameters = CodeBlock.builder().addEmitObject(.Literal, any: "\(closureVarName): \(closureType)").build()
        let returnTypeCB = CodeBlock.builder().addEmitObject(.Literal, any: returnType).build()
        let execution = CodeBlock.builder().addEmitObject(.Literal, any:
            "\(typeName)(\(initParamName): \(closureVarName)\(convertClosureType))"
        ).build()

        let closure = ControlFlow.closureControlFlow(parameters, canThrow: canThrow, returnType: returnTypeCB, execution: execution)

        return globalCB.addEmitObjects(closure.emittableObjects).build()
    }
}
