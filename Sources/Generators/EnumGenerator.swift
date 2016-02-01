//
//  EnumGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import SwiftPoet

internal struct EnumGenerator: Generator {

    internal typealias ResultType = [PoetFile]?

    internal static func generate(service: Service) -> ResultType {
        return service.enums?.map { e in
            EnumSpec.builder(e.name)
                .addFramework(service.name)
                .addModifier(.Public)
                .addDescription(e.deprecation)
                .addImport("Foundation")
                .addSuperType(TypeName.StringType)
                .addFieldSpecs(
                    e.values.map { value in
                        return FieldSpec.builder(value.name)
                            .addInitializer(value.name.escapedString().toCodeBlock())
                            .addDescription(value.deprecation)
                            .build()
                    }
            ).build().toFile()
        }
    }
}

// MARK: JSONParse
extension EnumGenerator {

    internal static func jsonParseCodeBlock(field: Field) -> CodeBlock {
        if field.required {
            return EnumGenerator.jsonParseCodeBlockRequired(field)
        } else {
            return EnumGenerator.jsonParseCodeBlockOptional(field)
        }
    }

    /*
    let fieldNameStr = try payload.requiredString(fieldName)
    guard let fieldName = Enum(rawValue: fieldNameStr) else {
        throw DataTransactionError.DataFormatError("Error creating Enum with key \(fieldNameStr)")
    }
    */
    private static func jsonParseCodeBlockRequired(field: Field) -> CodeBlock {
        let strVariable = "\(field.cammelCaseName)Str"

        let cb = CodeBlock.builder()
            .addCodeLine("let \(strVariable) = try payload.requiredString(\"\(field.name)\")")

        let left = "let \(field.cammelCaseName)".toCodeBlock()
        let right = EnumGenerator.toEnumCodeBlock(field.typeName, paramName: strVariable).toCodeBlock()

        cb.addCodeBlock(ControlFlow.guardControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return "throw DataTransactionError.DataFormatError(\"Error creating \(field.typeName) with key \\(\(strVariable))\")".toCodeBlock()
        })

        return cb.build()
    }

    /*
    var fieldName: FieldType? = nil
    if let fieldNameStr = payload["field_name"] as? String {
        fieldName = FieldType(rawValue: fieldNameStr)
    }
    */
    private static func jsonParseCodeBlockOptional(field: Field) -> CodeBlock {
        let strVariable = "\(field.cammelCaseName)Str"
        let cb = CodeBlock.builder()
            .addCodeLine("var \(field.cammelCaseName): \(field.typeName) = nil")

        let left = "let \(strVariable)".toCodeBlock()
        let right = "payload[\"\(field.name)\"] as? String".toCodeBlock()

        cb.addCodeBlock(
            ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
                return "\(field.cammelCaseName) = \(EnumGenerator.toEnumCodeBlock(field.requiredTypeName, paramName: strVariable))".toCodeBlock()
            })

        return cb.build()
    }

    // Enum(rawValue: fieldNameStr)
    internal static func toEnumCodeBlock(typeName: String, paramName: String) -> String {
        return "\(typeName)(rawValue: \(paramName))"
    }

}


// MARK: toJSON
extension EnumGenerator {
    /*
    // required
    dictName = paramName.rawValue

    // optional
    if let paramName = paramName {
        dictName[keyName] = paramName.rawValue
    }
    */
    internal static func toJsonCodeBlock(paramName: String, dictName: String, keyName: String, required: Bool) -> CodeBlock {
        return ToJsonFunctionGenerator.generate(paramName, required: required) { field in
            return CodeBlock.builder()
                .addLiteral("\(dictName)[\(keyName)] = ")
                .addLiteral(EnumGenerator.toJsonCodeBlock(paramName).toString())
                .build()
        }
    }

    internal static func toJsonCodeBlock(field: Field) -> CodeBlock {
        return EnumGenerator.toJsonCodeBlock(field.cammelCaseName,
            dictName: ToJsonFunctionGenerator.varName,
            keyName: field.name.escapedString(),
            required: field.required)
    }

    /*
    $0.rawValue || paramName.rawValue
    */
    internal static func toJsonCodeBlock(paramName: String? = nil) -> CodeBlock {
        let cleanName = paramName != nil ? PoetUtil.cleanCammelCaseString(paramName!) : "$0"
        return CodeBlock.builder().addLiteral("\(cleanName).rawValue").build()
    }
}
