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
            return SimpleTypeGenerator.generateParseJsonDictionary(field)
        default: return CodeBlock.builder().build()
        }
    }

    private static func generateParseJsonGeneric(field: Field, requiredType: String, type: String) -> CodeBlock {
        /*
        let fieldName = try payload.required`requiredType`(field_name)
        */
        if field.required {
            return CodeBlock.builder().addLiteral("let \(field.cammelCaseName) = try payload.required\(requiredType)(\"\(field.name)\")").build()
        } else {
        /*
        let fieldName = payload["field_name"] as? Type
        */
            return CodeBlock.builder().addLiteral("let \(field.cammelCaseName) = payload[\"\(field.name)\"] as? \(type)").build()
        }
    }

    public static func generateParseJsonBool(field: Field) -> CodeBlock {
        let requiredType = "Bool"
        /*
        let fieldName = try payload.requiredBool(field_name)
        */
        if field.required {
            return CodeBlock.builder().addLiteral("let \(field.cammelCaseName) = try payload.required\(requiredType)(\"\(field.name)\")").build()
        } else {
        /*
        let fieldName = payload.optionalBool(field_name)
        */
            return CodeBlock.builder().addLiteral("let \(field.cammelCaseName) = payload.optional\(requiredType)(\"\(field.name)\")").build()
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
        return CodeBlock.builder().addLiteral("let \(field.cammelCaseName) = nil").build()
    }

    public static func generateParseJsonGuid(field: Field) -> CodeBlock {
        let fieldNameStr = "\(field.cammelCaseName)Str"
        /*
        let fieldName = try payload.requiredGUID(field_name)
        */
        if field.required {
            return CodeBlock.builder().addLiteral("let \(field.cammelCaseName) = try payload.requiredGUID(\"\(field.name)\")").build()
        } else {
            /*
            let fieldNameStr = payload["field_name"] as? String
            var fieldName = NSUUID? = nil
            if let fieldNameStr = fieldNameStr {
                fieldName = NSUUID(string: fieldNameStr)
            }
            */
            let cb = CodeBlock.builder()
            cb.addCodeLine("let \(fieldNameStr) = payload[\"\(field.name)\"] as? String")

            cb.addCodeLine("var \(field.cammelCaseName): NSUUID? = nil")

            let left = CodeBlock.builder().addLiteral("let \(fieldNameStr)").build()
            let right = CodeBlock.builder().addLiteral(fieldNameStr).build()

            cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
                return CodeBlock.builder().addLiteral("\(field.cammelCaseName) = NSUUID(UUIDString: \(fieldNameStr))").build()
            })

            return cb.build()
        }
    }

    public static func generateParseJsonDate(field: Field) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)

        if field.required {
            /*
                let fieldName = try payload.requiredISO8601Date(field_name)
            */
            return CodeBlock.builder().addLiteral("let \(cammelCaseName) = try payload.requiredISO8601Date(\"\(field.name)\")").build()
        } else {
            /*
            let fieldName = (payload["field_name"] as? String)?.asDateISO8601()
            */
            return CodeBlock.builder().addLiteral("let \(cammelCaseName) = (payload[\"\(field.name)\"] as? String)?.asDateISO8601()").build()
        }
    }

    public static func generateParseJsonDateTime(field: Field) -> CodeBlock {
        return SimpleTypeGenerator.generateParseJsonDate(field) // TODO add DateTime to CleanroomDateTime
    }

    public static func generateParseJsonObject(field: Field) -> CodeBlock {
        if field.required {
            return CodeBlock.builder()
                .addLiteral("let \(field.cammelCaseName) = try payload.requiredDictionary(\"\(field.name)\")")
                .build()
        } else {
            return CodeBlock.builder()
                .addLiteral("let \(field.cammelCaseName) = payload[\"\(field.name)\"] as? NSDictionary")
                .build()
        }
    }

    public static func generateParseJsonDictionary(field: Field) -> CodeBlock {
        if field.required {
            return SimpleTypeGenerator.generateParseJsonDictionaryRequired(field)
        } else {
            return SimpleTypeGenerator.generateParseJsonDictionaryOptional(field)
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
    private static func generateParseJsonDictionaryRequired(field: Field) -> CodeBlock {
        let cb = CodeBlock.builder()
        let capitalizedType: String
        switch SwiftType(apidocType: field.type, imports: nil)! {
        case .Dictionary(let leftType, _):
            capitalizedType = PoetUtil.cleanTypeName(leftType.swiftTypeString)
        default:
            capitalizedType = field.cleanTypeName
        }

        cb.addCodeLine("var \(field.cammelCaseName) = [\(capitalizedType) : \(capitalizedType)]()")

        cb.addCodeBlock(ControlFlow.forInControlFlow("(key, value)", iterable: "try payload.requiredDictionary(\"\(field.name)\")") {
            let innerCB = CodeBlock.builder()
            let leftOne = CodeBlock.builder().addLiteral("let kType").build()
            let rightOne = CodeBlock.builder().addLiteral("key as? \(capitalizedType)").build()
            let comparisonOne = ComparisonListItem(comparison: Comparison(lhs: leftOne, comparator: .OptionalCheck, rhs: rightOne))

            let leftTwo = CodeBlock.builder().addLiteral("let vType").build()
            let rightTwo = CodeBlock.builder().addLiteral("value as? \(capitalizedType)").build()
            let comparisonTwo = ComparisonListItem(comparison: Comparison(lhs: leftTwo, comparator: .OptionalCheck, rhs: rightTwo), requirement: Requirement.OptionalList)

            let comparisons = ComparisonList(list: [comparisonOne, comparisonTwo])


            innerCB
                // IF
                .addCodeBlock(ControlFlow.ifControlFlow(comparisons) {
                    return CodeBlock.builder().addLiteral("\(field.cammelCaseName)[kType] = vType").build()
                })
                // ELSE
                .addCodeBlock(ControlFlow.elseControlFlow(nil) {
                    return CodeBlock.builder().addLiteral("throw DataTransactionError.FormatError(\"Error creating field \(field.name). Expected a \(capitalizedType) found \\(key) and\\(value)\")").build()
                })

            return innerCB.build()
        })

        return cb.build()
    }

    /*
    var fieldName: [Type : Type]? = nil
    if let dict = payload["field_name"] as? NSDictionary {
        fieldName = [TypeName : TypeName]()
        for (key, value) in dict {
            if let kType = key as? Type, let vType = value as? Type {
                fieldName[kType] = vType
            }
        }
    }
    */
    private static func generateParseJsonDictionaryOptional(field: Field) -> CodeBlock {
        let cb = CodeBlock.builder()
        let capitalizedType: String
        switch SwiftType(apidocType: field.type, imports: nil)! {
        case .Dictionary(let leftType, _):
            capitalizedType = PoetUtil.cleanTypeName(leftType.swiftTypeString)
        default:
            capitalizedType = field.cleanTypeName
        }

        cb.addCodeLine("var \(field.cammelCaseName): [\(capitalizedType) : \(capitalizedType)]? = nil")

        let left = CodeBlock.builder().addLiteral("let dict").build()
        let right = CodeBlock.builder().addLiteral("payload[\"\(field.name)\"] as? NSDictionary").build()

        // if let dict = payload["field_name"] as? NSDictionary
        cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            let cb = CodeBlock.builder()
                .addCodeLine("\(field.cammelCaseName) = [\(capitalizedType) : \(capitalizedType)]()")

            //for (key, value) in dict {
            cb.addCodeBlock(ControlFlow.forInControlFlow("(key, value)", iterable: "dict") {

                let leftOne = CodeBlock.builder().addLiteral("let kType").build()
                let rightOne = CodeBlock.builder().addLiteral("key as? \(capitalizedType)").build()
                let comparisonOne = ComparisonListItem(comparison: Comparison(lhs: leftOne, comparator: .OptionalCheck, rhs: rightOne))

                let leftTwo = CodeBlock.builder().addLiteral("let vType").build()
                let rightTwo = CodeBlock.builder().addLiteral("value as? \(capitalizedType)").build()
                let comparisonTwo = ComparisonListItem(comparison: Comparison(lhs: leftTwo, comparator: .OptionalCheck, rhs: rightTwo), requirement: Requirement.OptionalList)

                let comparisons = ComparisonList(list: [comparisonOne, comparisonTwo])

                // if let kType = key as? Type, let vType = value as? Type
                return ControlFlow.ifControlFlow(comparisons) {
                    //  fieldName[kType] = vType
                    CodeBlock.builder().addLiteral("\(field.cammelCaseName)?[kType] = vType").build()
                }
            })

            return cb.build()
        })

        return cb.build()
    }

    public static func toJsonCodeBlock(field: Field, swiftType: SwiftType) -> CodeBlock {
        let rightSide = SimpleTypeGenerator.toString(swiftType)
        let rightSideStr = rightSide == nil ? field.cammelCaseName : "\(field.cammelCaseName).\(rightSide!)"
        return ToJsonFunctionGenerator.generate(field) { field in
            return SimpleTypeGenerator.requiredToJsonCodeBlock(field.name, rightSide: rightSideStr)
        }
    }

    private static func requiredToJsonCodeBlock(fieldName: String, rightSide: String) -> CodeBlock {
        return CodeBlock.builder().addLiteral("\(MethodGenerator.toJSONVarName)[\"\(fieldName)\"] = \(rightSide)").build()
    }

    public static func toString(swiftType: SwiftType) -> String? {
        switch swiftType {
        case .UUID: return "UUIDString"
        case .DateISO8601, .DateTimeISO8601: return "asISO8601()"
        default: return nil
        }
    }
}
