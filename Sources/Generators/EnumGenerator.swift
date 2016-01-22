//
//  EnumGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import SwiftPoet

public struct EnumGenerator: Generator {

    public typealias ResultType = [Apidoc.FileName : EnumSpec]?

    public static func generate(service: Service) -> ResultType {
        return service.enums?.reduce([String : EnumSpec]()) { (var dict, e) in
            let eb = EnumSpec.builder(e.name)
                .addSuperType(TypeName.StringType)
                .addModifier(.Public)
                .addDescription(e.deprecation)
                .addImport("Foundation")
                .addFieldSpecs(
                    e.values.map { value in
                        return FieldSpec.builder(value.name)
                            .addInitializer(CodeBlock.builder().addEmitObject(.EscapedString, any: value.name).build())
                            .addDescription(value.deprecation)
                            .build()
                    }
            )
            dict[PoetUtil.cleanCammelCaseString(e.name)] = eb.build()
            return dict
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
        throw DataTransactionError.FormatError("Error creating Enum with key \(fieldNameStr)")
    }
    */
    private static func generateEnumParseJsonBlockRequired(field: Field) -> CodeBlock {
        let strVariable = "\(field.cammelCaseName)Str"
        let optionalVariable = "\(field.cammelCaseName)Optional"

        let cb = CodeBlock.builder()

        cb.addCodeLine("let \(strVariable) = try payload.requiredString(\(field.name))")
        cb.addCodeLine("let \(optionalVariable) = \(field.cleanTypeName)(rawValue: \(strVariable))")

        let left = CodeBlock.builder().addLiteral("let \(field.cammelCaseName)").build()
        let right = CodeBlock.builder().addLiteral(optionalVariable).build()

        cb.addCodeBlock(ControlFlow.guardControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return CodeBlock.builder().addLiteral("throw DataTransactionError.FormatError(\"Error creating \(field.cleanTypeName) with key \\(\(strVariable))\")").build()
        })

        return cb.build()
    }

    /*
    let fieldNameStr = payload["field_name"] as? String
    let fieldName: FieldType? = nil
    if let fieldNameStr = fieldNameStr {
        fieldName = FieldType(rawValue: fieldNameStr)
    }
    */
    private static func generateEnumParseJsonBlockOptional(field: Field) -> CodeBlock {
        let strVariable = "\(field.cammelCaseName)Str"
        let cb = CodeBlock.builder()

        cb.addCodeLine("let \(strVariable) = try payload[\"\(field.name)\"] as? String")
        cb.addCodeLine("let \(field.cammelCaseName): \(field.cleanTypeName)? = nil")

        let left = CodeBlock.builder().addLiteral("let \(strVariable)").build()
        let right = CodeBlock.builder().addLiteral(strVariable).build()

        cb.addCodeBlock(
            ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
                return CodeBlock.builder().addLiteral("let \(field.cammelCaseName) = \(field.cleanTypeName)(rawValue: \(strVariable))").build()
            })

        return cb.build()
    }

    /*
    resultJSON["field_name"] = json.rawValue
    */
    public static func toJsonFunction(field: Field) -> CodeBlock {
        return ToJsonFunctionGenerator.generate(field) { field in
            return EnumGenerator.toJsonCodeBlock(field.name)
        }
    }

    internal static func toJsonCodeBlock(fieldName: String) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(fieldName)
        return CodeBlock.builder().addLiteral("\(MethodGenerator.toJSONVarName)[\(fieldName)] = \(cammelCaseName).rawValue"
            ).build()
    }
}
