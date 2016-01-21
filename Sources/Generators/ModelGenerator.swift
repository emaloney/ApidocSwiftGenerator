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
        return service.models?.reduce([String : StructSpec]()) { (var dict, model) in
            let sb = StructSpec.builder(model.name)
                .includeDefaultInit()
                .addModifier(.Public)
                .addDescription(model.description)
                .addImport("Foundation")
                .addFieldSpecs(FieldGenerator.generate(model.fields, imports: service.imports))
                .addMethodSpec(MethodGenerator.generateJsonParsingInit(service, model: model))
                .addMethodSpec(MethodGenerator.modelToJson(service, model: model))

            dict[PoetUtil.cleanCammelCaseString(model.name)] = sb.build()
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

    public static func generateParseModelJson(name: String, type: String, required: Bool) -> CodeBlock {
        return ModelGenerator.generateParseModelJson(Field(name: name, type: type, description: nil, deprecation: nil, _default: nil, required: required, minimum: nil, maximum: nil, example: nil))
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


    /*
    switch fieldName.toJSON() {
    case .Succeeded(let json):
        resultJSON["field_name"] = json
    case .Failed:
        return .Failed(DataTransactionError.FormatError("Invalid FieldName data"))
    }
    */
    public static func toJsonFunction(field: Field) -> CodeBlock {
        return ToJsonFunctionGenerator.generate(field) { field in
            let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)

            return ControlFlow.switchControlFlow(
                "\(cammelCaseName).toJSON()",
                cases: [
                    (".Succeeded(let json)", ModelGenerator.toJsonSucceededCodeBlock(field)),
                    (".Failed", ModelGenerator.toJsonFailedCodeBlock(field))
                ])
        }
    }

    private static func toJsonSucceededCodeBlock(field: Field) -> CodeBlock {
        return CodeBlock.builder().addEmitObject(.Literal, any:
            "\(MethodGenerator.toJSONVarName)[\"\(field.name)\"] = json"
        ).build()
    }

    private static func toJsonFailedCodeBlock(field: Field) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)
        return CodeBlock.builder().addEmitObject(.Literal, any:
            "return .Failed(DataTransactionError.FormatError(\"Invalid \(cammelCaseName) data\"))"
            ).build()
    }
}
