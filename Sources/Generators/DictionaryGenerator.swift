//
//  DictionaryGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/28/16.
//
//

import Foundation
import SwiftPoet

public struct DictionaryGenerator {

    /*
    var fieldNameJson = [String: AnyObject]()
    for (key, value) in try fieldName {
        if let kType = key as? String, vType = value as? Type {
            fieldName[kType] = vType
        } else {
            throw DataTransactionError.DataFormatError("Error creating for fieldName. Expected a string found \(key) and \(value)")
        }
    }
    resultJson["field_name"] = fieldNameJson
    */
    public static func toJsonCodeBlock(field: Field, rightType: SwiftType) -> CodeBlock {
        let cb = CodeBlock.builder().addLiteral("var \(field.cammelCaseName)Json = [String: AnyObject]()")

        cb.addCodeBlock(ControlFlow.forInControlFlow("(key, value)", iterable: field.cammelCaseName) {
            switch rightType {
            case .ExternalType(let typeName):
                return ModelGenerator.toJsonFunction("\(field.cammelCaseName)Json", mapValue: "value", mapKey: "key", fieldType: typeName, required: true)
            case .ImportedType(_, let typeName):
                return ModelGenerator.toJsonFunction("\(field.cammelCaseName)Json", mapValue: "value", mapKey: "key", fieldType: typeName, required: true)
            case .Array:
                fatalError()
            case .Dictionary:
                fatalError()
            default:
                return SimpleTypeGenerator.toJsonCodeBlock("value", swiftType: rightType, required: true)
            }
        })

        cb.addCodeLine("\(MethodGenerator.toJSONVarName)[\"\(field.name)\"] = \(field.cammelCaseName)Json")
        return cb.build()

    }

    public static func generateParseJsonDictionary(field: Field, swiftType: SwiftType) -> CodeBlock {
        if field.required {
            return DictionaryGenerator.generateParseJsonDictionaryRequired(field, swiftType: swiftType)
        } else {
            return DictionaryGenerator.generateParseJsonDictionaryOptional(field, swiftType: swiftType)
        }
    }

    /*
    var fieldName = [String : Type]()
    for (key, value) in try payload.requiredDictionary(field_name) {
        if let kType = key as? String, vType = value as? Type {
            fieldName[kType] = vType
        } else {
            throw DataTransactionError.DataFormatError("Error creating for fieldName. Expected a string found \(key) and \(value)")
        }
    }
    */
    private static func generateParseJsonDictionaryRequired(field: Field, swiftType: SwiftType) -> CodeBlock {
        let cb = CodeBlock.builder()
        let capitalizedType: String
        switch swiftType {
        case .Dictionary(_, let rightType):
            capitalizedType = PoetUtil.cleanTypeName(rightType.swiftTypeString)
        default:
            capitalizedType = field.cleanTypeName
        }

        cb.addCodeLine("var \(field.cammelCaseName) = [String : \(capitalizedType)]()")

        cb.addCodeBlock(ControlFlow.forInControlFlow("(key, value)", iterable: "try payload.requiredDictionary(\"\(field.name)\")") {
            let innerCB = CodeBlock.builder()
            let leftOne = CodeBlock.builder().addLiteral("let kType").build()
            let rightOne = CodeBlock.builder().addLiteral("key as? String").build()
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
                    return CodeBlock.builder().addLiteral("throw DataTransactionError.DataFormatError(\"Error creating field \(field.name). Expected a \(capitalizedType) found \\(key) and\\(value)\")").build()
                    })

            return innerCB.build()
            })

        return cb.build()
    }

    /*
    var fieldName: [String : Type]? = nil
    if let dict = payload["field_name"] as? NSDictionary {
        fieldName = [String : TypeName]()
        for (key, value) in dict {
            if let kType = key as? String, let vType = value as? Type {
                fieldName[kType] = vType
            }
        }
    }
    */
    private static func generateParseJsonDictionaryOptional(field: Field, swiftType: SwiftType) -> CodeBlock {
        let cb = CodeBlock.builder()
        let capitalizedType: String
        switch swiftType {
        case .Dictionary(let leftType, _):
            capitalizedType = PoetUtil.cleanTypeName(leftType.swiftTypeString)
        default:
            capitalizedType = field.cleanTypeName
        }

        cb.addCodeLine("var \(field.cammelCaseName): [String : \(capitalizedType)]? = nil")

        let left = CodeBlock.builder().addLiteral("let dict").build()
        let right = CodeBlock.builder().addLiteral("payload[\"\(field.name)\"] as? NSDictionary").build()

        // if let dict = payload["field_name"] as? NSDictionary
        cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            let cb = CodeBlock.builder()
                .addCodeLine("\(field.cammelCaseName) = [String : \(capitalizedType)]()")

            //for (key, value) in dict {
            cb.addCodeBlock(ControlFlow.forInControlFlow("(key, value)", iterable: "dict") {

                let leftOne = CodeBlock.builder().addLiteral("let kType").build()
                let rightOne = CodeBlock.builder().addLiteral("key as? String)").build()
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
}