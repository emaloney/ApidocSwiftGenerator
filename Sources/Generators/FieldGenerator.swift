//
//  FieldGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation
import SwiftPoet

public struct FieldGenerator {
    public typealias ResultType = FieldSpec

    public static func generate(fields: [Field], imports: [Import]?) -> [ResultType] {
        return fields.map { field in
            FieldGenerator.generate(field, imports: imports)
        }
    }

    public static func generate(field: Field, imports: [Import]?) -> ResultType {
        let swiftType = SwiftType(apidocType: field.type, imports: imports)
        let typeStr = swiftType?.swiftTypeString ?? "nil"
        let typeName = TypeName(keyword: typeStr, optional: field.required)
        let fb = FieldSpec.builder(field.name, type: typeName)
            .addDescription(field.description)
            .addModifier(.Public)

        if let swiftType = swiftType {
            switch swiftType {
            case .ImportedType(let namespace, _):
                fb.addImport(namespace)
            default: break;
            }
        }
        return fb.build()
    }

    public static func generateJsonParse(field: Field, service: Service) -> CodeBlock {
        let cb = CodeBlock.builder()

        guard let swiftType = SwiftType(apidocType: field.type, imports: service.imports) else {
            return cb.build()
        }
        /*
case Boolean
case DateISO8601
case DateTimeISO8601
case Decimal
case Double
case Integer
case Long
case Object
case SwiftString
case Unit
case UUID
case Dictionary(SwiftType, SwiftType)
case Array(SwiftType)
case ExternalType(String)
case ImportedType(String, String) // Namespace, Name
*/
        switch swiftType {
        case .ExternalType(let typeName):
            if service.contains(.Enum, typeName: typeName) {
                cb.addCodeBlock(EnumGenerator.generateEnumParseJsonBlock(field))
            } else if service.contains(.Model, typeName: typeName) {
                cb.addCodeBlock(ModelGenerator.generateParseModelJson(field))
            }
            break
        case .ImportedType(_):
            // No need to add imports. This is taken care of be virtue of having these types as fields
            cb.addCodeBlock(ModelGenerator.generateParseModelJson(field))
        case .Boolean:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonBool(field))
        case .DateISO8601:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonDate(field))
        case .DateTimeISO8601:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonDate(field))
        case .Decimal:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonDecimal(field))
        case .Double:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonDouble(field))
        case .Integer:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonInteger(field))
        case .Long:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonLong(field))
        case .Object:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonObject(field))
        case .SwiftString:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonObject(field))
        case .Unit:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonObject(field))
        case .UUID:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonGuid(field))
        case .Dictionary:
            cb.addCodeBlock(SimpleTypeGenerator.generateParseJsonObject(field))
        case .Array(let internalType): break
            // TODO
        }

        return cb.build()
    }


}
