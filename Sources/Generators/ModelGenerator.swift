//
//  ModelGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/12/16.
//
//

import Foundation
import SwiftPoet

internal struct ModelGenerator: Generator {
    internal typealias ResultType = [PoetFile]?

    internal static func generate(service: Service) -> ResultType {
        var models: [PoetFile]? = service.models?.map { model in
            let sb = StructSpec.builder(model.name)
                .addFramework(service.name)
                .addModifier(.Public)
                .addDescription(model.description)
                .addProtocol(TypeName(keyword: "JSONDataModel"))
                .addProtocol(TypeName(keyword: "BinaryDataModel"))
                .addImports(["CleanroomDataTransactions", "Foundation"])
                .addFieldSpecs(FieldGenerator.generate(model.fields, service: service))
                .addMethodSpec(MethodGenerator.toJsonFunction(model, service: service))
                .addMethodSpec(MethodGenerator.jsonParsingInit(model, service: service))
                .includeDefaultInit()

            if model.fields.contains({ $0.type == "date-iso8601" || $0.type == "date-time-iso8601" }) {
                sb.addImport("CleanroomDateTime")
            }

            return sb.build().toFile()
        }

        // include global service struct with baseUrl information
        let baseUrlValue = (service.baseUrl ?? "").escapedString()
        models?.append(StructSpec.builder(service.name)
            .addFramework(service.name)
            .addModifier(.Public)
            .addDescription(service.description)
            .addImport("Foundation")
            .addFieldSpec(FieldSpec.builder("baseUrl", type: TypeName.StringType, construct: .MutableField)
                .addModifiers([.Static, .Public])
                .addInitializer(baseUrlValue.toCodeBlock())
                .build())
            .build().toFile())

        return models
    }
}

// MARK: JSONParse
extension ModelGenerator {

    // convinience
    internal static func jsonParseCodeBlock(field: Field, service: Service) -> CodeBlock {
        return ModelGenerator.jsonParseCodeBlock(field.cammelCaseName,
            keyName: field.name.escapedString(),
            typeName: field.typeName,
            required: field.required,
            service: service)
    }

    internal static func jsonParseCodeBlock(paramName: String, keyName: String, typeName: String, required: Bool, service: Service) -> CodeBlock {
        if required {
            return ModelGenerator.jsonParseCodeBlockRequired(paramName, keyName: keyName, typeName: typeName, service: service)
        } else {
            return ModelGenerator.jsonParseCodeBlockOptional(paramName, keyName: keyName, typeName: typeName, service: service)
        }
    }

    /*
    let paramNameJson = try payload.requiredDictionary(keyName)
    (let) paramName = (try) TypeName(payload: paramNameJson)
    */
    private static func jsonParseCodeBlockRequired(paramName: String, keyName: String, typeName: String, service: Service) -> CodeBlock {
        let paramNameJson = "\(paramName)Json"

        return CodeBlock.builder()
            .addLiteral("let \(paramNameJson) = try payload.requiredDictionary(\(keyName))")
            .addCodeBlock(ModelGenerator.toModelCodeBlock(paramName, typeName: typeName, jsonParamName: paramNameJson, service: service))
            .build()
    }

    /*
    var paramName: TypeName? = nil
    if let paramNameJson = payload[keyName] as? NSDictionary {
        paramName = (try) TypeName(payload: paramNameJson)
    }
    */
    private static func jsonParseCodeBlockOptional(paramName: String, keyName: String, typeName: String, service: Service) -> CodeBlock {
        let paramNameJson = "\(paramName)Json"
        let requiredType = TypeName(keyword: typeName.substringToIndex(typeName.characters.endIndex.predecessor())).literalValue()

        let cb = CodeBlock.builder()
            .addCodeLine("var \(paramName): \(typeName) = nil")

        let left = "let \(paramNameJson)".toCodeBlock()
        let right = "payload[\(keyName)] as? NSDictionary".toCodeBlock()

        cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return ModelGenerator.toModelCodeBlock(paramName, typeName: requiredType, jsonParamName: paramNameJson, service: service, initalize: false)
        })

        return cb.build()
    }

    // (let) paramName = (try) TypeName(payload: jsonParamName)
    internal static func toModelCodeBlock(paramName: String, typeName: String, jsonParamName: String, service: Service, initalize: Bool = true) -> CodeBlock {
        let initializeStr = initalize ? "let " : ""

        return "\(initializeStr)\(paramName) = \(ModelGenerator.jsonToModelCodeBlock(typeName, jsonParamName: jsonParamName, service: service))".toCodeBlock()
    }

    // (try) TypeName(payload: jsonParamName)
    internal static func jsonToModelCodeBlock(typeName: String, jsonParamName: String, service: Service) -> String {
        let canThrow = service.getModel(typeName)?.canThrow(service) != false
        let tryStr = canThrow ? "try " : ""
        return "\(tryStr)\(typeName)(payload: \(jsonParamName))"
    }
}

// MARK: toJSON
extension ModelGenerator {
    /*
    switch paramName.toJSON() {
    case .Succeeded(let json):
        dictName[keyName] = json
    case .Failed:
        return .Failed(DataTransactionError.DataFormatError("Invalid typeName data"))
    }
    */
    internal static func toJsonCodeBlock(paramName: String, dictName: String, keyName: String, required: Bool, typeName: String) -> CodeBlock {
        return ToJsonFunctionGenerator.generate(paramName, required: required) {
            return ControlFlow.switchControlFlow(
                "\(paramName).toJSON()",
                cases: [
                    (".Succeeded(let json)", ModelGenerator.toJsonSucceededCodeBlock(dictName, keyName: keyName)),
                    (".Failed", ModelGenerator.toJsonFailedCodeBlock(typeName))
                ])
        }
    }

    internal static func toJsonCodeBlock(field: Field) -> CodeBlock {
        return ModelGenerator.toJsonCodeBlock(field.cammelCaseName,
            dictName: ToJsonFunctionGenerator.varName,
            keyName: field.name.escapedString(),
            required: field.required,
            typeName: field.typeName)
    }

    private static func toJsonSucceededCodeBlock(dictName: String, keyName: String) -> CodeBlock {
        return "\(dictName)[\(keyName)] = json".toCodeBlock()
    }

    private static func toJsonFailedCodeBlock(typeName: String) -> CodeBlock {
        return "return .Failed(DataTransactionError.DataFormatError(\"Invalid \(typeName) data\"))".toCodeBlock()
    }
}
