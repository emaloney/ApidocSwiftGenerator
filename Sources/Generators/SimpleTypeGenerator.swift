//
//  SimpleTypeGenerator.swift
//  SwiftPoet
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation
import SwiftPoet

internal struct SimpleTypeGenerator {}

// MARK: parseJSON
extension SimpleTypeGenerator {
    internal static func parseJsonCodeBlock(field: Field, swiftType: SwiftType) -> CodeBlock {
        switch swiftType.type {
        case .Boolean:
            return SimpleTypeGenerator.parseJsonCodeBlockBool(field.cammelCaseName,
                keyName: field.name.escapedString(),
                required: field.required)
        case .DateISO8601:
            return SimpleTypeGenerator.parseJsonCodeBlockDate(field.cammelCaseName,
                keyName: field.name.escapedString(),
                required: field.required)
        case .DateTimeISO8601:
            return SimpleTypeGenerator.parseJsonCodeBlockDateTime(field.cammelCaseName,
                keyName: field.name.escapedString(),
                required: field.required)
        case .Decimal:
            return SimpleTypeGenerator.parseJsonCodeBlockGeneric(field.cammelCaseName,
                keyName: field.name.escapedString(),
                typeName: "Double",
                required: field.required)
        case .Double:
            return SimpleTypeGenerator.parseJsonCodeBlockGeneric(field.cammelCaseName,
                keyName: field.name.escapedString(),
                typeName: "Double",
                required: field.required)
        case .Integer:
            return SimpleTypeGenerator.parseJsonCodeBlockGeneric(field.cammelCaseName,
                keyName: field.name.escapedString(),
                typeName: "Int",
                required: field.required)
        case .Long:
            return SimpleTypeGenerator.parseJsonCodeBlockGeneric(field.cammelCaseName,
                keyName: field.name.escapedString(),
                typeName: "Int",
                required: field.required)
        case .Object:
            return SimpleTypeGenerator.parseJsonCodeBlockObject(field.cammelCaseName,
                keyName: field.name.escapedString(),
                required: field.required)
        case .SwiftString:
            return SimpleTypeGenerator.parseJsonCodeBlockGeneric(field.cammelCaseName,
                keyName: field.name.escapedString(),
                typeName: "String",
                required: field.required)
        case .Unit:
            return SimpleTypeGenerator.parseJsonCodeBlockUnit(field.cammelCaseName)
        case .UUID:
            return SimpleTypeGenerator.parseJsonCodeBlockGuid(field.cammelCaseName,
                keyName: field.name.escapedString(),
                required: field.required)
        default: fatalError()
        }
    }

    private static func parseJsonCodeBlockGeneric(paramName: String, keyName: String, typeName: String, required: Bool) -> CodeBlock {
        /*
        let paramName = try payload.required`TypeName`(keyName)
        */
        if required {
            return "let \(paramName) = try payload.required\(typeName)(\(keyName))".toCodeBlock()
        } else {
        /*
        let paramName = payload[keyName] as? Type
        */
            return "let \(paramName) = payload[\(keyName)] as? \(typeName)".toCodeBlock()
        }
    }

    internal static func parseJsonCodeBlockBool(paramName: String, keyName: String, required: Bool) -> CodeBlock {
        let functionType = required ? "required" : "optional"
        let tryStr = required ? " try" : ""
        /*
        let paramName = try payload.requiredBool(keyName)
        let paramName =     payload.optionalBool(keyName)
        */
        return "let \(paramName) =\(tryStr) payload.\(functionType)Bool(\(keyName))".toCodeBlock()
    }

    /*
        let fieldName = nil
    */
    internal static func parseJsonCodeBlockUnit(paramName: String) -> CodeBlock {
        return "let \(paramName) = nil".toCodeBlock()
    }

    internal static func parseJsonCodeBlockGuid(paramName: String, keyName: String, required: Bool) -> CodeBlock {
        /*
        let paramName = try payload.requiredGUID(keyName)
        */
        if required {
            return "let \(paramName) = try payload.requiredGUID(\(keyName))".toCodeBlock()
        } else {
            /*
            var paramName: NSUUID? = nil
            if let paramNameStr = payload["field_name"] as? String {
                paramName = NSUUID(UUIDString: paramName)
            }
            */
            let paramNameStr = "\(paramName)Str"
            let cb = CodeBlock.builder()
                .addCodeLine("var \(paramName): NSUUID? = nil")

            let left = "let \(paramNameStr)".toCodeBlock()
            let right = "payload[\(keyName)] as? String".toCodeBlock()

            cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
                return "\(paramName) = NSUUID(UUIDString: \(paramNameStr))".toCodeBlock()
            })

            return cb.build()
        }
    }

    internal static func parseJsonCodeBlockDate(paramName: String, keyName: String, required: Bool) -> CodeBlock {
        if required {
            /*
                let paramName = try payload.requiredISO8601Date(keyName)
            */
            return "let \(paramName) = try payload.requiredISO8601Date(\(keyName))".toCodeBlock()
        } else {
            /*
            let paramName = (payload[keyName] as? String)?.asDateISO8601()
            */
            return "let \(paramName) = (payload[\(keyName)] as? String)?.asDateISO8601()".toCodeBlock()
        }
    }

    internal static func parseJsonCodeBlockDateTime(paramName: String, keyName: String, required: Bool) -> CodeBlock {
        return SimpleTypeGenerator.parseJsonCodeBlockDate(paramName, keyName: keyName, required: required) // TODO add DateTime to CleanroomDateTime
    }

    internal static func parseJsonCodeBlockObject(paramName: String, keyName: String, required: Bool) -> CodeBlock {
        if required {
            return "let \(paramName) = try payload.requiredDictionary(\(keyName))".toCodeBlock()
        } else {
            return "let \(paramName) = payload[\(keyName)] as? NSDictionary".toCodeBlock()
        }
    }
}


// MARK: toJSON
extension SimpleTypeGenerator {
    internal static func toJsonCodeBlock(paramName: String, keyName: String, swiftType: SwiftType, mapName: String = ToJsonFunctionGenerator.varName) -> CodeBlock {
        let rightSide = swiftType.asRequiredType().toString(paramName)

        return ToJsonFunctionGenerator.generate(paramName, required: !swiftType.optional) {
            return SimpleTypeGenerator.requiredtoJsonCodeBlock(keyName, rightSide: rightSide, mapName: mapName)
        }
    }

    private static func requiredtoJsonCodeBlock(keyName: String, rightSide: String, mapName: String = ToJsonFunctionGenerator.varName) -> CodeBlock {
        return "\(mapName)[\(keyName)] = \(rightSide)".toCodeBlock()
    }

    internal static func toJsonCodeBlock(field: Field, swiftType: SwiftType) -> CodeBlock {
        return SimpleTypeGenerator.toJsonCodeBlock(field.cammelCaseName, keyName: field.name.escapedString(), swiftType: swiftType)
    }
}
