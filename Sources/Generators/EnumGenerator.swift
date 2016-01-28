//
//  EnumGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import SwiftPoet

public struct EnumGenerator: Generator {

    public typealias ResultType = [PoetFile]?

    public static func generate(service: Service) -> ResultType {
        return service.enums?.map { e in
            let eb = EnumSpec.builder(e.name)
                .addFramework(service.name)
                .addModifier(.Public)
                .addDescription(e.deprecation)
                .addImport("Foundation")
                .addSuperType(TypeName.StringType)
                .addFieldSpecs(
                    e.values.map { value in
                        return FieldSpec.builder(value.name)
                            .addInitializer(CodeBlock.builder().addLiteral("\"\(value.name)\"").build())
                            .addDescription(value.deprecation)
                            .build()
                    }
            )
            return eb.build().toFile()
        }
    }

    public static func generateEnumParseJsonBlock(field: Field) -> CodeBlock {
        if field.required {
            return EnumGenerator.generateEnumParseJsonBlockRequired(field)
        } else {
            return EnumGenerator.generateEnumParseJsonBlockOptional(field)
        }
    }

    /*
    let fieldNameStr = try payload.requiredString(fieldName)
    let fieldNameOptional = Enum(rawValue: fieldNameStr)
    guard let fieldName = fieldNameOptional else {
        throw DataTransactionError.DataFormatError("Error creating Enum with key \(fieldNameStr)")
    }
    */
    private static func generateEnumParseJsonBlockRequired(field: Field) -> CodeBlock {
        let strVariable = "\(field.cammelCaseName)Str"
        let optionalVariable = "\(field.cammelCaseName)Optional"

        let cb = CodeBlock.builder()

        cb.addCodeLine("let \(strVariable) = try payload.requiredString(\"\(field.name)\")")
        cb.addCodeLine("let \(optionalVariable) = \(field.cleanTypeName)(rawValue: \(strVariable))")

        let left = CodeBlock.builder().addLiteral("let \(field.cammelCaseName)").build()
        let right = CodeBlock.builder().addLiteral(optionalVariable).build()

        cb.addCodeBlock(ControlFlow.guardControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return CodeBlock.builder().addLiteral("throw DataTransactionError.DataFormatError(\"Error creating \(field.cleanTypeName) with key \\(\(strVariable))\")").build()
        })

        return cb.build()
    }

    /*
    let fieldNameStr = payload["field_name"] as? String
    var fieldName: FieldType? = nil
    if let fieldNameStr = fieldNameStr {
        fieldName = FieldType(rawValue: fieldNameStr)
    }
    */
    private static func generateEnumParseJsonBlockOptional(field: Field) -> CodeBlock {
        let strVariable = "\(field.cammelCaseName)Str"
        let cb = CodeBlock.builder()

        cb.addCodeLine("let \(strVariable) = payload[\"\(field.name)\"] as? String")
        cb.addCodeLine("var \(field.cammelCaseName): \(field.cleanTypeName)? = nil")

        let left = CodeBlock.builder().addLiteral("let \(strVariable)").build()
        let right = CodeBlock.builder().addLiteral(strVariable).build()

        cb.addCodeBlock(
            ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
                return CodeBlock.builder().addLiteral("\(field.cammelCaseName) = \(field.cleanTypeName)(rawValue: \(strVariable))").build()
            })

        return cb.build()
    }

    public static func toJsonFunction(field: Field) -> CodeBlock {
        return ToJsonFunctionGenerator.generate(field) { field in
            return CodeBlock.builder().addLiteral("\(MethodGenerator.toJSONVarName)[\"\(field.name)\"] = ").addLiteral(EnumGenerator.toJsonCodeBlock(field.name).toString()).build()
        }
    }

    /*
    $0.rawValue
    */
    internal static func toJsonCodeBlock(fieldName: String? = nil) -> CodeBlock {
        let cleanName = fieldName != nil ? PoetUtil.cleanCammelCaseString(fieldName!) : "$0"
        return CodeBlock.builder().addLiteral("\(cleanName).rawValue").build()
    }
}
