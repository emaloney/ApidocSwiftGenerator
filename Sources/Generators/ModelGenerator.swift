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
        var models: [PoetFile]? = service.models?.map { model in
            let sb = StructSpec.builder(model.name)
                .addFramework(service.name)

                .addModifier(.Public)
                .addDescription(model.description)
                .addProtocol(TypeName(keyword: "JSONDataModel"))
                .addProtocol(TypeName(keyword: "BinaryDataModel"))
                .addImport("Foundation")
                .addFieldSpecs(FieldGenerator.generate(model.fields, imports: service.imports))
                .addMethodSpec(MethodGenerator.modelToJson(service, model: model))
                .addMethodSpec(MethodGenerator.generateJsonParsingInit(service, model: model))
                .includeDefaultInit()

            if !(model.fields.filter { $0.type == "date-iso8601" || $0.type == "date-time-iso8601" }).isEmpty {
                sb.addImport("CleanroomDateTime")
            }

            return sb.build().toFile()
        }
        models?.append(StructSpec.builder(service.name)
            .addFramework(service.name)
            .addModifier(.Public)
            .addDescription(service.description)
            .addImport("Foundation")
            .addFieldSpec(FieldSpec.builder("baseUrl", type: TypeName.StringType, construct: .MutableField)
                .addModifiers([.Public, .Static])
                .addInitializer(CodeBlock.builder().addLiteral("\"\(service.baseUrl ?? "")\"").build())
                .build())
            .build().toFile())

        return models
    }

    public static func generateParseModelJson(field: Field, service: Service?, rootJson: Bool = false) -> CodeBlock {
        if rootJson || field.required {
            return ModelGenerator.generateParseRequiredModelJson(field, service: service, rootJson: rootJson)
        } else {
            return ModelGenerator.generateParseOptionalModelJson(field, service: service)
        }
    }

    public static func generateParseModelJson(name: String, type: String, required: Bool, service: Service) -> CodeBlock {
        return ModelGenerator.generateParseModelJson(Field(name: name, type: type, description: nil, deprecation: nil, _default: nil, required: required, minimum: nil, maximum: nil, example: nil), service: service)
    }

    /*
    let fieldNameJson = try payload.requiredDictionary("field_name")
    let fieldName = (try) FieldType(payload: fieldNameJson)
    */
    private static func generateParseRequiredModelJson(field: Field, service: Service?, rootJson: Bool = false) -> CodeBlock {
        let model = service?.getModel(field.type)
        let jsonVarName = rootJson ? "payload" : "\(field.cammelCaseName)Json"
        let cb = CodeBlock.builder()
        let canThrowStr = service != nil && model?.canThrow(service!) == false ? "" : " try" // by default use try
        // TODO
        if !rootJson {
            cb.addCodeLine("let \(jsonVarName) = try payload.requiredDictionary(\"\(field.name)\")")
        }
        cb.addCodeLine("let \(field.cammelCaseName) =\(canThrowStr) \(field.cleanTypeName)(payload: \(jsonVarName))")

        return cb.build()
    }

    /*
    var fieldName: FieldType? = nil
    if let fieldNameJson = payload["field_name"] as? NSDictionary {
        fieldName = (try) FieldType([payload: fieldNameJson)
    }
    */
    private static func generateParseOptionalModelJson(field: Field, service: Service?) -> CodeBlock {
        let model = service?.getModel(field.type)
        let jsonVarName = "\(field.cammelCaseName)Json"
        let cb = CodeBlock.builder()
        let canThrowStr = service != nil && model?.canThrow(service!) == false ? "" : " try" // by default use try

        cb.addCodeLine("var \(field.cammelCaseName): \(field.cleanTypeName)? = nil")

        let left = CodeBlock.builder().addLiteral("let \(jsonVarName)").build()
        let right = CodeBlock.builder().addLiteral("payload[\"\(field.name)\"] as? NSDictionary").build()

        cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return CodeBlock.builder().addLiteral("\(field.cammelCaseName) =\(canThrowStr) \(field.cleanTypeName)(payload: \(jsonVarName))").build()
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
