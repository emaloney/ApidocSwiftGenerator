//
//  ModelGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/12/16.
//
//

import Foundation
import SwiftPoet

public struct ModelGenerator: Generator {
    public typealias ResultType = [Apidoc.FileName : StructSpec]?

    public static func generate(service: Service) -> ResultType {
        return service.models?.reduce([String : StructSpec]()) { (var dict, m) in
            let sb = StructSpec.builder(m.name)
                .includeDefaultInit()
                .addModifier(.Public)
                .addDescription(m.description)
                .addImport("Foundation")
                .addFieldSpecs(FieldGenerator.generate(m.fields, imports: service.imports))

            dict[PoetUtil.cleanCammelCaseString(m.name)] = sb.build()
            return dict
        }
    }

    public static func generateParseModelJson(field: Field) -> CodeBlock {
        if field.required {
            return ModelGenerator.generateParseRequiredModelJson(field)
        } else {
            return ModelGenerator.generateParseOptionalModelJson(field)
        }
    }

    /*
    let fieldNameJson = try payload.requiredDictionary("field_name")
    let fieldName = try FieldType(payload: fieldNameJson)
    */
    private static func generateParseRequiredModelJson(field: Field) -> CodeBlock {
        let globalCB = CodeBlock.builder()
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)
        let jsonVarName = "\(cammelCaseName)Json"
        let typeName = PoetUtil.cleanTypeName(field.type)

        globalCB.addCodeBlock(CodeBlock.builder().addEmitObject(.Literal, any:
            "let \(jsonVarName) = try payload.requiredDictionary(\"\(field.name)\")"
            ).build())

        globalCB.addCodeBlock(CodeBlock.builder().addEmitObject(.Literal, any:
            "let \(cammelCaseName) = try \(typeName)(payload: \(jsonVarName))"
            ).build())

        return globalCB.build()
    }

    /*
    var fieldName: FieldType? = nil
    if let fieldNameJson = payload["field_name"] as? NSDictionary {
        fieldName = FieldType([payload: fieldNameJson)
    }
    */
    private static func generateParseOptionalModelJson(field: Field) -> CodeBlock {
        let globalCB = CodeBlock.builder()
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)
        let jsonVarName = "\(cammelCaseName)Json"
        let typeName = PoetUtil.cleanTypeName(field.type)

        globalCB.addCodeBlock(CodeBlock.builder().addEmitObject(.Literal,
            any: "var \(cammelCaseName): \(typeName)? = nil").build())

        let left = CodeBlock.builder().addEmitObject(.Literal, any: "let \(jsonVarName)").build()
        let right = CodeBlock.builder().addEmitObject(.Literal, any:
            "payload[\"\(field.name)\"] as? NSDictionary").build()
        let ifCompare = ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)
        let ifBody = CodeBlock.builder().addEmitObject(.Literal,
            any: "\(cammelCaseName) = \(typeName)(payload: \(jsonVarName))").build()

        let ifControlFlow = ControlFlow.ifControlFlow(ifBody, ifCompare)

        globalCB.addCodeBlock(ifControlFlow)
        return globalCB.build()
    }
}
