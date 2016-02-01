//
//  UnionGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/25/16.
//
//

import Foundation
import SwiftPoet

internal struct UnionGenerator: Generator {
    internal typealias ResultType = [PoetFile]?

    /*
    public protocol Union {}

    internal struct UnionImpl {
        static func toModel(payload: NSDictionary) throws -> Union {
            if let payload = payload["simple_type"] as? NSDictionary {
                return payload["value"] as! UnionType // simple type
            }
            do {
                return ExternalTypeEnum(rawValue: payload["union_type_name"] as! String)!
            }
            catch {
                // Do nothing
            }
            do {
                return ExternalTypeEnum(rawValue: payload["union_type_name"] as! String)!
            }
            catch {
                // Do nothing
            }
            throw DataTransactionError.DataFormatError("Invalid Union")
        }
    }

    extension Int: ResponseCode {}

    extension ResponseCodeOption: ResponseCode {}
    */
    internal static func generate(service: Service) -> ResultType {
        return service.unions?.map { union in
            let file = PoetFile(list: [], framework: service.name)

            file.append(UnionGenerator.generateProtocol(union))
            file.append(UnionGenerator.unionImpl(union, service: service))
            UnionGenerator.unionTypeExtensions(union).forEach { file.append($0) }

            return file
        }
    }

    private static func unionImpl(union: Union, service: Service) -> StructSpec {
        return StructSpec.builder("\(union.name)Impl")
            .addModifier(.Internal)
            .addFramework(service.name)
            .addImports(["Foundation", "CleanroomDataTransactions"])
            .addMethodSpec(UnionGenerator.toModelFunction(union, service: service))
            .build()
    }

    private static func toModelFunction(union: Union, service: Service) -> MethodSpec {
        let mb = MethodSpec.builder("toModel")
            .addParameter(ParameterSpec.builder("payload", type: TypeName.NSDictionary).build())
            .addReturnType(TypeName(keyword: union.name))
            .canThrowError()

        let cb = CodeBlock.builder()
        union.types.forEach { unionType in
            let swiftType = SwiftType(apidocType: unionType.type, service: service)
            switch swiftType.type {
            case .ServiceDefinedType, .ImportedType:
                cb.addCodeBlock(UnionGenerator.externalTypeCodeBlock(unionType, swiftType: swiftType, service: service))
            default:
                cb.addCodeBlock(UnionGenerator.simpleTypeCodeBlock(unionType))
            }
        }
        cb.addCodeLine("throw DataTransactionError.DataFormatError(\"Invalid \(union.name)\")")
        mb.addCode(cb.build())

        return mb.build()
    }

    /*
    if let payload = payload["simple_type"] as? NSDictionary {
        return payload["value"] as! UnionType // simple type
    }
    */
    private static func simpleTypeCodeBlock(unionType: UnionType) -> CodeBlock {
        let left = CodeBlock.builder().addLiteral("let payload").build()
        let right = CodeBlock.builder().addLiteral("payload[\"\(unionType.type)\"] as? NSDictionary").build()
        return ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return CodeBlock.builder().addLiteral("return payload[\"value\"] as! \(PoetUtil.cleanTypeName(unionType.type))").build()
        }
    }

    /*
    do {
        return ExternalTypeEnum(rawValue: payload["union_type_name"] as! String)!
    }
    catch {
        // Do nothing
    }
    */
    private static func externalTypeCodeBlock(unionType: UnionType, swiftType: SwiftType, service: Service) -> CodeBlock {
        let field = Field(name: unionType.type, type: unionType.type, description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)

        let doBlock = FieldGenerator.jsonParseCodeBlock(field, service: service)

        return ControlFlow.doCatchControlFlow({
            return CodeBlock.builder()
                .addCodeBlock(doBlock)
                .addCodeLine("return \(field.cammelCaseName)")
                .build()
        }) {
            return CodeBlock.builder().addLiteral("// Do nothing").build()
        }
    }

    private static func unionTypeExtensions(union: Union) -> [ExtensionSpec] {
        return union.types.map { type in
            return ExtensionSpec.builder(type.type).addSuperType(TypeName(keyword: union.name)).build()
        }
    }

    private static func generateProtocol(union: Union) -> ProtocolSpec {
        return ProtocolSpec.builder(union.name)
            .addDescription(union.description)
            .addModifier(.Public)
            .build()
    }
}

// MARK jsonParse
extension UnionGenerator {

    // Convienience
    internal static func jsonParseCodeBlock(field: Field) -> CodeBlock {
        return UnionGenerator.jsonParseCodeBlock(field.cammelCaseName,
            typeName: field.typeName,
            keyName: field.name.escapedString(),
            required: field.required)
    }

    internal static func jsonParseCodeBlock(paramName: String, typeName: String, keyName: String, required: Bool) -> CodeBlock {
        if required {
            return UnionGenerator.jsonParseCodeBlockRequired(paramName, typeName: typeName, keyName: keyName)
        } else {
            return UnionGenerator.jsonParseCodeBlockOptional(paramName, typeName: typeName, keyName: keyName)
        }
    }

    /*
    let paramNameJson = try payload.requiredDictionary(keyName)
    let paramName = try TypeNameImpl.toModel(payload: paramNameJson)
    */
    internal static func jsonParseCodeBlockRequired(paramName: String, typeName: String, keyName: String) -> CodeBlock {
        let paramNameJson = "\(paramName)Json"
        return CodeBlock.builder()
            .addLiteral("let \(paramNameJson) = try payload.requiredDictionary(\(keyName))")
            .addLiteral(UnionGenerator.toUnionCodeBlock(paramName, typeName: typeName, paramNameJson: paramNameJson).toString())
            .build()
    }

    /*
    let paramName: TypeName? = nil
    if let paramNameJson = payload[keyName] as? NSDictionary {
        paramName = try TypeNameImpl.toModel(payload: paramNameJson)
    }

    */
    internal static func jsonParseCodeBlockOptional(paramName: String, typeName: String, keyName: String) -> CodeBlock {
        let paramNameJson = "\(paramName)Json"
        let cb = CodeBlock.builder()
            .addLiteral("let \(paramName): \(typeName)? = nil")

        let left = "let \(paramNameJson)".toCodeBlock()
        let right = "payload[\(keyName)] as? NSDictionary".toCodeBlock()

        cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return UnionGenerator.toUnionCodeBlock(paramName, typeName: typeName, paramNameJson: paramNameJson, initalize: false)
        })

        return cb.build()
    }

    // (let) paramName = try TypeNameImpl.toModel(payload: paramNameJson)
    internal static func toUnionCodeBlock(paramName: String, typeName: String, paramNameJson: String, initalize: Bool = true) -> CodeBlock {
        let initalizeStr = initalize ? "let " : ""
        return "\(initalizeStr)\(paramName) = try \(typeName)Impl.toModel(payload: \(paramNameJson))".toCodeBlock()
    }
}

// MARK: toJSON
extension UnionGenerator {
    internal static func toJsonCodeBlock(field: Field) -> CodeBlock {
        return UnionGenerator.toJsonCodeBlock(field.cammelCaseName,
            dictName: ToJsonFunctionGenerator.varName,
            keyName: field.name.escapedString(),
            required: field.required,
            typeName: field.typeName)
    }

    internal static func toJsonCodeBlock(paramName: String, dictName: String, keyName: String, required: Bool, typeName: String) -> CodeBlock {
        // TODO how should this work?
        return ToJsonFunctionGenerator.generate(paramName, required: required) {
            return paramName.toCodeBlock()
        }
    }
}
