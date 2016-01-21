//
//  SimpleTypeGenerator.swift
//  SwiftPoet
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation
import SwiftPoet

public struct SimpleTypeGenerator {
    public static func generateParseJson(field: Field, swiftType: SwiftType) -> CodeBlock {
        switch swiftType {
        case .Boolean:
            return SimpleTypeGenerator.generateParseJsonBool(field)
        case .DateISO8601:
            return SimpleTypeGenerator.generateParseJsonDate(field)
        case .DateTimeISO8601:
            return SimpleTypeGenerator.generateParseJsonDate(field)
        case .Decimal:
            return SimpleTypeGenerator.generateParseJsonDecimal(field)
        case .Double:
            return SimpleTypeGenerator.generateParseJsonDouble(field)
        case .Integer:
            return SimpleTypeGenerator.generateParseJsonInteger(field)
        case .Long:
            return SimpleTypeGenerator.generateParseJsonLong(field)
        case .Object:
            return SimpleTypeGenerator.generateParseJsonObject(field)
        case .SwiftString:
            return SimpleTypeGenerator.generateParseJsonString(field)
        case .Unit:
            return SimpleTypeGenerator.generateParseJsonObject(field)
        case .UUID:
            return SimpleTypeGenerator.generateParseJsonGuid(field)
        case .Dictionary:
            return SimpleTypeGenerator.generateParseJsonObject(field)
        default: return CodeBlock.builder().build()
        }
    }

    private static func generateParseJsonGeneric(field: Field, requiredType: String, type: String) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)
        /*
        let fieldName = try payload.required`requiredType`(field_name)
        */
        if field.required {
            return CodeBlock.builder().addEmitObject(.Literal,
                any: "let \(cammelCaseName) = try payload.required\(requiredType)(\"\(field.name)\")").build()
        } else {
        /*
        let fieldName = payload["field_name"] as? Type
        */
            return CodeBlock.builder().addEmitObject(.Literal,
                any: "let \(cammelCaseName) = payload[\"\(field.name)\"] as? \(type)").build()
        }
    }

    public static func generateParseJsonBool(field: Field) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)
        let requiredType = "Bool"
        /*
        let fieldName = try payload.requiredBool(field_name)
        */
        if field.required {
            return CodeBlock.builder().addEmitObject(.Literal,
                any: "let \(cammelCaseName) = try payload.required\(requiredType)(\"\(field.name)\")").build()
        } else {
        /*
        let fieldName = payload.optionalBool(field_name)
        */
            return CodeBlock.builder().addEmitObject(.Literal,
                any: "let \(cammelCaseName) = try payload.optional\(requiredType)(\"\(field.name)\")").build()
        }
    }

    public static func generateParseJsonDouble(field: Field) -> CodeBlock {
        return SimpleTypeGenerator.generateParseJsonGeneric(field, requiredType: "Double", type: "Double")
    }

    public static func generateParseJsonDecimal(field: Field) -> CodeBlock {
        return SimpleTypeGenerator.generateParseJsonGeneric(field, requiredType: "Double", type: "Double")
    }

    public static func generateParseJsonInteger(field: Field) -> CodeBlock {
        return SimpleTypeGenerator.generateParseJsonGeneric(field, requiredType: "Int", type: "Int")
    }

    public static func generateParseJsonLong(field: Field) -> CodeBlock {
        return SimpleTypeGenerator.generateParseJsonGeneric(field, requiredType: "Int", type: "Int")
    }

    public static func generateParseJsonString(field: Field) -> CodeBlock {
        return SimpleTypeGenerator.generateParseJsonGeneric(field, requiredType: "String", type: "String")
    }

    /*
        let fieldName = nil
    */
    public static func generateParseJsonUnit(field: Field) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)

        return CodeBlock.builder().addEmitObject(.Literal,
            any: "let \(cammelCaseName) = nil").build()
    }

    public static func generateParseJsonGuid(field: Field) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)
        let fieldNameStr = "\(cammelCaseName)Str"
        /*
        let fieldName = try payload.requiredGUID(field_name)
        */
        if field.required {
            return CodeBlock.builder().addEmitObject(.Literal,
                any: "let \(cammelCaseName) = try payload.requiredGUID(\"\(field.name)\")").build()
        } else {
            /*
            let fieldNameStr = payload["field_name"] as? String
            var fieldName = NSUUID? = nil
            if let fieldNameStr = fieldNameStr {
                fieldName = NSUUID(string: fieldNameStr)
            }
            */
            let globalCB = CodeBlock.builder()
            globalCB.addEmitObject(.Literal,
                any: "let \(fieldNameStr) = payload[\"\(field.name)\"] as? String")

            globalCB.addCodeBlock(CodeBlock.builder().addEmitObject(.Literal,
                any: "var \(cammelCaseName): NSUUID? = nil").build())

            let left = CodeBlock.builder().addEmitObject(.Literal, any: "let \(fieldNameStr)").build()
            let right = CodeBlock.builder().addEmitObject(.Literal, any: fieldNameStr).build()
            let ifCompare = ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)
            let ifBody = CodeBlock.builder().addEmitObject(.Literal,
                any: "\(cammelCaseName) = NSUUID(string: \(fieldNameStr))").build()

            let ifControlFlow = ControlFlow.ifControlFlow(ifBody, ifCompare)

            globalCB.addCodeBlock(ifControlFlow)
            return globalCB.build()
        }
    }

    public static func generateParseJsonDate(field: Field) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)

        if field.required {
            /*
                let fieldName = try payload.requiredISO8601Date(field_name)
            */
            return CodeBlock.builder().addEmitObject(.Literal,
                    any: "let \(cammelCaseName) = try payload.requiredISO8601Date(\"\(field.name)\")").build()
        } else {
            /*
            let fieldName = (payload["field_name"] as? String)?.asDateISO8601()
            */
            return CodeBlock.builder().addEmitObject(.Literal,
                    any: "let \(cammelCaseName) = (payload[\"\(field.name)\"] as? String)?.asDateISO8601()").build()
        }
    }

    public static func generateParseJsonDateTime(field: Field) -> CodeBlock {
        return SimpleTypeGenerator.generateParseJsonDate(field) // TODO add DateTime to CleanroomDateTime
    }

    public static func generateParseJsonObject(field: Field) -> CodeBlock {
        if field.required {
            return SimpleTypeGenerator.generateParseJsonObjectRequired(field)
        } else {
            return SimpleTypeGenerator.generateParseJsonObjectOptional(field)
        }
    }

    /*
    var fieldName = [Type : Type]()
    for (key, value) in try payload.requiredDictionary(field_name) {
        if let kType = key as? Type, vType = value as? Type {
                fieldName[keyStr] = valueStr
        } else {
            throw DataTransactionError.FormatError("Error creating for fieldName. Expected a string found \(key) and \(value)")
        }
    }
    */
    private static func generateParseJsonObjectRequired(field: Field) -> CodeBlock {
        let globalCB = CodeBlock.builder()
        let cammelCaseType = PoetUtil.cleanCammelCaseString(field.name)
        let capitalizedType: String
        switch SwiftType(apidocType: field.type, imports: nil)! {
        case .Dictionary(let leftType, _):
            capitalizedType = PoetUtil.cleanTypeName(leftType.swiftTypeString)
        default:
            capitalizedType = PoetUtil.cleanTypeName(field.type)
        }

        globalCB.addCodeBlock(CodeBlock.builder()
            .addEmitObject(.Literal, any:
                "var \(cammelCaseType) = [\(capitalizedType) : \(capitalizedType)]()"
            ).build())

        let iterator = CodeBlock.builder().addEmitObject(.Literal, any: "(key, value)").build()
        let iterable = CodeBlock.builder().addEmitObject(.Literal, any: "try payload.requiredDictionary(\(field.name))").build()

        let leftOne = CodeBlock.builder().addEmitObject(.Literal, any: "let kType").build()
        let rightOne = CodeBlock.builder().addEmitObject(.Literal, any: "key as? \(capitalizedType)").build()
        let comparisonOne = ComparisonListItem(comparison: Comparison(lhs: leftOne, comparator: .OptionalCheck, rhs: rightOne))

        let leftTwo = CodeBlock.builder().addEmitObject(.Literal, any: "let vType").build()
        let rightTwo = CodeBlock.builder().addEmitObject(.Literal, any: "value as? \(capitalizedType)").build()
        let comparisonTwo = ComparisonListItem(comparison: Comparison(lhs: leftTwo, comparator: .OptionalCheck, rhs: rightTwo), requirement: Requirement.OptionalList)

        let body = CodeBlock.builder().addEmitObject(.Literal, any: "\(cammelCaseType)[kType] = vType").build()
        let comparisons = ComparisonList(list: [comparisonOne, comparisonTwo])
        let ifControlFlow = ControlFlow.ifControlFlow(body, comparisons)

        let elseBody = CodeBlock.builder().addEmitObject(.Literal,
            any: "throw DataTransactionError.FormatError(\"Error creating field \(field.name). Expected a \(capitalizedType) found \\(key) and\\(value)\"").build()
        let elseControlFlow = ControlFlow.elseControlFlow(elseBody, nil)

        let forIn = ControlFlow.forInControlFlow(iterator, iterable: iterable, execution: CodeBlock.builder().addCodeBlock(ifControlFlow).addCodeBlock(elseControlFlow).build())
        globalCB.addCodeBlock(forIn)
        return globalCB.build()
    }

    /*
    var fieldName: [Type : Type]?
    if let dict = payload["field_name"] as? NSDictionary {
        for (key, value) in dict {
            if let kType = key as? Type, let vType = value as? Type {
                fieldName[kType] = vType
            }
        }
    } else {
        fieldName = nil
    }
    */
    private static func generateParseJsonObjectOptional(field: Field) -> CodeBlock {
        let globalCB = CodeBlock.builder()
        let cammelCaseType = PoetUtil.cleanCammelCaseString(field.name)
        let capitalizedType: String
        switch SwiftType(apidocType: field.type, imports: nil)! {
        case .Dictionary(let leftType, _):
            capitalizedType = PoetUtil.cleanTypeName(leftType.swiftTypeString)
        default:
            capitalizedType = PoetUtil.cleanTypeName(field.type)
        }

        globalCB.addCodeBlock(CodeBlock.builder()
            .addEmitObject(.Literal, any:
                "var \(cammelCaseType) = [\(capitalizedType) : \(capitalizedType)]?"
            ).build())

        // if let dict = payload["field_name"] as? NSDictionary
        let left = CodeBlock.builder().addEmitObject(.Literal, any: "let dict").build()
        let right = CodeBlock.builder().addEmitObject(.Literal, any: "payload[\"\(field.name)\"] as? NSDictionary").build()
        let ifCompare = ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)

        //for loop
        let iterator = CodeBlock.builder().addEmitObject(.Literal, any: "(key, value)").build()
        let iterable = CodeBlock.builder().addEmitObject(.Literal, any: "dict").build()

        // if let kType = key as? Type, let vType = value as? Type
        let leftOne = CodeBlock.builder().addEmitObject(.Literal, any: "let kType").build()
        let rightOne = CodeBlock.builder().addEmitObject(.Literal, any: "key as? \(capitalizedType)").build()
        let comparisonOne = ComparisonListItem(comparison: Comparison(lhs: leftOne, comparator: .OptionalCheck, rhs: rightOne))

        let leftTwo = CodeBlock.builder().addEmitObject(.Literal, any: "let vType").build()
        let rightTwo = CodeBlock.builder().addEmitObject(.Literal, any: "value as? \(capitalizedType)").build()
        let comparisonTwo = ComparisonListItem(comparison: Comparison(lhs: leftTwo, comparator: .OptionalCheck, rhs: rightTwo), requirement: Requirement.OptionalList)

        let body = CodeBlock.builder().addEmitObject(.Literal, any: "\(cammelCaseType)[kType] = vType").build()
        let comparisons = ComparisonList(list: [comparisonOne, comparisonTwo])
        let innerIfControlFlow = ControlFlow.ifControlFlow(body, comparisons)

        let forIn = ControlFlow.forInControlFlow(iterator, iterable: iterable, execution: innerIfControlFlow)

        let ifControlFlow = ControlFlow.ifControlFlow(forIn, ifCompare)
        globalCB.addCodeBlock(ifControlFlow)

        let elseBody = CodeBlock.builder().addEmitObject(.Literal,
            any: "\(cammelCaseType) = nil").build()
        let elseControlFlow = ControlFlow.elseControlFlow(elseBody, nil)
        globalCB.addCodeBlock(elseControlFlow)

        return globalCB.build()
    }

    public static func toJsonCodeBlock(field: Field, swiftType: SwiftType) -> CodeBlock {
        let rightSide = SimpleTypeGenerator.toString(swiftType)
        let rightSideStr = rightSide == nil ? field.cammelCaseName : "\(field.cammelCaseName).\(rightSide!)"
        return SimpleTypeGenerator.requiredToJsonCodeBlock(field.name, rightSide: rightSideStr)
    }

    private static func requiredToJsonCodeBlock(fieldName: String, rightSide: String) -> CodeBlock {
        return CodeBlock.builder().addEmitObject(.Literal, any:
            "\(MethodGenerator.toJSONVarName)[\"\(fieldName)\"] = \(rightSide)"
            ).build()
    }

    public static func toString(swiftType: SwiftType) -> String? {
        switch swiftType {
        case .UUID: return "UUIDString"
        case .DateISO8601, .DateTimeISO8601: return "toasISO8601()"
        default: return nil
        }
    }
}
