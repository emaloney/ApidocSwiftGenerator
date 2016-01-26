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
    public typealias ResultType = [PoetFile]?

    public static func generate(service: Service) -> ResultType {
        return service.models?.map { model in
            let sb = StructSpec.builder(model.name)
                .addFramework(service.name)
                .includeDefaultInit()
                .addModifier(.Public)
                .addDescription(model.description)
                .addImport("Foundation")
                .addFieldSpecs(FieldGenerator.generate(model.fields, imports: service.imports))
                .addMethodSpec(MethodGenerator.generateJsonParsingInit(service, model: model))
                .addMethodSpec(MethodGenerator.modelToJson(service, model: model))

            return sb.build().toFile()
        }
    }

    public static func generateParseModelJson(field: Field, rootJson: Bool = false) -> CodeBlock {
        if rootJson || field.required {
            return ModelGenerator.generateParseRequiredModelJson(field, rootJson: rootJson)
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
    private static func generateParseRequiredModelJson(field: Field, rootJson: Bool = false) -> CodeBlock {
        let jsonVarName = rootJson ? "payload" : "\(field.cammelCaseName)Json"
        let cb = CodeBlock.builder()

        if !rootJson {
            cb.addCodeLine("let \(jsonVarName) = try payload.requiredDictionary(\"\(field.name)\")")
        }
        cb.addCodeLine("let \(field.cammelCaseName) = try \(field.cleanTypeName)(payload: \(jsonVarName))")

        return cb.build()
    }

    /*
    var fieldName: FieldType? = nil
    if let fieldNameJson = payload["field_name"] as? NSDictionary {
        fieldName = FieldType([payload: fieldNameJson)
    }
    */
    private static func generateParseOptionalModelJson(field: Field) -> CodeBlock {
        let jsonVarName = "\(field.cammelCaseName)Json"

        let cb = CodeBlock.builder()

        cb.addCodeLine("var \(field.cammelCaseName): \(field.cleanTypeName)? = nil")

        let left = CodeBlock.builder().addLiteral("let \(jsonVarName)").build()
        let right = CodeBlock.builder().addLiteral("payload[\"\(field.name)\"] as? NSDictionary").build()

        cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return CodeBlock.builder().addLiteral("\(field.cammelCaseName) = \(field.cleanTypeName)(payload: \(jsonVarName))").build()
        })

        return cb.build()
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
        return CodeBlock.builder().addLiteral("\(MethodGenerator.toJSONVarName)[\"\(field.name)\"] = json"
        ).build()
    }

    private static func toJsonFailedCodeBlock(field: Field) -> CodeBlock {
        return CodeBlock.builder().addLiteral("return .Failed(DataTransactionError.FormatError(\"Invalid \(field.cammelCaseName) data\"))"
            ).build()
    }
}
