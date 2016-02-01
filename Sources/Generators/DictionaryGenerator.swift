//
//  DictionaryGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/28/16.
//
//

import Foundation
import SwiftPoet

internal struct DictionaryGenerator {}

// MARK: toJSON
extension DictionaryGenerator {
    /*
    var paramNameJson = [String: AnyObject]()
    for (key, value) in try paramName {
        switch value.toJSON() {
        case .Succeeded(let json):
            dictName[key] = json
        case .Failed:
            return .Failed(DataTransactionError.DataFormatError("Invalid typeName data"))
        }
    }
    resultJson["field_name"] = fieldNameJson
    */
    internal static func toJsonCodeBlock(paramName: String, keyName: String, dictName: String, valueType: SwiftType, required: Bool, service: Service) -> CodeBlock {

        return ToJsonFunctionGenerator.generate(paramName, required: required) {

            let paramNameJson = "\(paramName)Json"

            return CodeBlock.builder().addLiteral("var \(paramNameJson) = [String: AnyObject]()")

                .addCodeBlock(ControlFlow.forInControlFlow("(key, value)", iterable: paramName) {
                    switch valueType.type {
                    case .ServiceDefinedType(let typeName):

                        if service.contains(.Enum, typeName: typeName) {
                            return EnumGenerator.toJsonCodeBlock("value",
                                dictName: paramNameJson,
                                keyName: "key",
                                required: !valueType.optional)
                        } else if service.contains(.Model, typeName: typeName) {
                            return ModelGenerator.toJsonCodeBlock("value",
                                dictName: paramNameJson,
                                keyName: "key",
                                required: !valueType.optional,
                                typeName: typeName)
                        } else if service.contains(.Union, typeName: typeName) {
                            return UnionGenerator.toJsonCodeBlock("value",
                                dictName: paramNameJson,
                                keyName: "key",
                                required: !valueType.optional,
                                typeName: typeName)

                        } else {
                            fatalError()
                        }

                    case .ImportedType(let namespace, let typeName):
                        if service.contains(.Enum, typeName: typeName, namespace: namespace) {
                            return EnumGenerator.toJsonCodeBlock("value",
                                dictName: paramNameJson,
                                keyName: "key",
                                required: !valueType.optional)
                        } else if service.contains(.Model, typeName: typeName, namespace: namespace) {
                            return ModelGenerator.toJsonCodeBlock("value",
                                dictName: paramNameJson,
                                keyName: "key",
                                required: !valueType.optional,
                                typeName: typeName)
                        } else if service.contains(.Union, typeName: typeName, namespace: namespace) {
                            return UnionGenerator.toJsonCodeBlock("value",
                                dictName: paramNameJson,
                                keyName: "key",
                                required: !valueType.optional,
                                typeName: typeName)

                        } else {
                            fatalError()
                        }

                    case .Array:
                        fatalError()
                    case .Dictionary:
                        fatalError()
                    default:
                        return SimpleTypeGenerator.toJsonCodeBlock("value", keyName: "key", swiftType: valueType, mapName: paramNameJson)
                    }
                })
                .addCodeLine("\(dictName)[\(keyName.escapedString())] = \(paramNameJson)")
                .build()
        }
    }

    // Convenience
    internal static func toJsonCodeBlock(field: Field, rightType: SwiftType, service: Service) -> CodeBlock {
        return DictionaryGenerator.toJsonCodeBlock(field.cammelCaseName,
            keyName: field.name,
            dictName: ToJsonFunctionGenerator.varName,
            valueType: rightType,
            required: field.required,
            service: service)
    }

}


// MARK: parseJSON
extension DictionaryGenerator {

    internal static func jsonParseCodeBlock(field: Field, swiftType: SwiftType) -> CodeBlock {
        if field.required {
            return DictionaryGenerator.jsonParseCodeBlockRequired(field, swiftType: swiftType)
        } else {
            return DictionaryGenerator.jsonParseCodeBlockOptional(field, swiftType: swiftType)
        }
    }

    /*
    var fieldName = [String : Type]()
    for (key, value) in try payload.requiredDictionary(field_name) {
    
        guard let kType = key as? String else {
            throw DataTransactionError.DataFormatError("Unexpected key type. Expected String for value \(key)")
        }
    
        TODO!!!
        fieldName[kType] =

        if let kType = key as? String, vType = value as? Type {
            fieldName[kType] = vType
        } else {
            throw DataTransactionError.DataFormatError("Error creating for fieldName. Expected a string found \(key) and \(value)")
        }
    }
    */
    private static func jsonParseCodeBlockRequired(field: Field, swiftType: SwiftType) -> CodeBlock {
        let cb = CodeBlock.builder()
        let capitalizedType = swiftType.swiftTypeString

        cb.addCodeLine("var \(field.cammelCaseName) = [String : \(capitalizedType)]()")

        cb.addCodeBlock(ControlFlow.forInControlFlow("(key, value)", iterable: "try payload.requiredDictionary(\(field.name.escapedString()))") {
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
                    return CodeBlock.builder().addLiteral("throw DataTransactionError.DataFormatError(\"Error creating field \(field.name). Expected a \(capitalizedType) found \\(key) and \\(value)\")").build()
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
    private static func jsonParseCodeBlockOptional(field: Field, swiftType: SwiftType) -> CodeBlock {
        let cb = CodeBlock.builder()
        let capitalizedType = swiftType.swiftTypeString

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
                let rightOne = CodeBlock.builder().addLiteral("key as? String").build()
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