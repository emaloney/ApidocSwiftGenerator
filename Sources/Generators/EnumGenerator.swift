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
        let globalCB = CodeBlock.builder()
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)
        let strVariable = "\(cammelCaseName)Str"
        let optionalVariable = "\(cammelCaseName)Optional"
        let capitalizeName = PoetUtil.cleanTypeName(field.name)

        globalCB.addCodeBlock(
            CodeBlock.builder()
                .addEmitObject(
                    .Literal,
                    any: "let \(strVariable) = try payload.requiredString(\(field.name))").build())

        let cb = CodeBlock.builder()
        cb.addEmitObject(
            .Literal,
            any: "let \(optionalVariable) = \(capitalizeName)(rawValue: \(strVariable))")

        let left = CodeBlock.builder().addEmitObject(.Literal, any: "let \(cammelCaseName)").build()
        let right = CodeBlock.builder().addEmitObject(.Literal, any: optionalVariable).build()
        let compare = ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)
        let body = CodeBlock.builder().addEmitObject(.Literal,
            any: "throw DataTransactionError.FormatError(\"Error creating \(capitalizeName) with key \\(\(strVariable))\")").build()
        let controlFlow = ControlFlow.guardControlFlow(body, compare)

        cb.addCodeBlock(controlFlow)
        globalCB.addCodeBlock(cb.build())


        return globalCB.build()
    }

    /*
    let fieldNameStr = payload[fieldName] as? String
    let fieldName: Enum?
    if let fieldNameStr = fieldNameStr {
        fieldName = Enum(rawValue: fieldNameStr)
    } else {
        fieldName = nil
    }
    */
    private static func generateEnumParseJsonBlockOptional(field: Field) -> CodeBlock {
        let globalCB = CodeBlock.builder()
        let strVariable = "\(PoetUtil.cleanCammelCaseString(field.name))Str"
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)
        let capitalizeName = PoetUtil.cleanTypeName(field.name)

        globalCB.addCodeBlock(
            CodeBlock.builder()
                .addEmitObject(
                    .Literal,
                    any: "let \(strVariable) = try payload[\(field.name)] as? String").build())

        let cb = CodeBlock.builder()
        cb.addCodeBlock(CodeBlock.builder().addEmitObject(
            .Literal,
            any: "let \(cammelCaseName) = \(capitalizeName)(rawValue: \(strVariable))!").build())

        let left = CodeBlock.builder().addEmitObject(.Literal, any: "let \(strVariable)").build()
        let right = CodeBlock.builder().addEmitObject(.Literal, any: strVariable).build()
        let ifCompare = ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)

        let ifBody = CodeBlock.builder().addEmitObject(.Literal,
            any: "\(cammelCaseName) = \(capitalizeName)(rawValue: \(strVariable))").build()

        let ifControlFlow = ControlFlow.ifControlFlow(ifBody, ifCompare)

        let elseBody = CodeBlock.builder().addEmitObject(.Literal, any: "\(cammelCaseName) = nil").build()
        let controlFlowElse = ControlFlow.elseControlFlow(elseBody, nil)

        cb.addCodeBlock(ifControlFlow)
        cb.addCodeBlock(controlFlowElse)
        globalCB.addCodeBlock(cb.build())
        
        return globalCB.build()
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
        return CodeBlock.builder().addEmitObject(.Literal, any:
            "\(MethodGenerator.toJSONVarName)[\(fieldName)] = \(cammelCaseName).rawValue"
            ).build()
    }
}
