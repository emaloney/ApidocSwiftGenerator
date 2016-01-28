//
//  UnionGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/25/16.
//
//

import Foundation
import SwiftPoet

public struct UnionGenerator: Generator {
    public typealias ResultType = [PoetFile]?

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
    public static func generate(service: Service) -> ResultType {
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
            if let swiftType = SwiftType(apidocType: unionType.type, imports: service.imports) {
                switch swiftType {
                case .ExternalType, .ImportedType:
                    cb.addCodeBlock(UnionGenerator.externalTypeCodeBlock(unionType, swiftType: swiftType, service: service))
                default:
                    cb.addCodeBlock(UnionGenerator.simpleTypeCodeBlock(unionType))
                }
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

        let doBlock = FieldGenerator.generateJsonParse(field, service: service)

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

    public static func generateParseUnionJson(field: Field) -> CodeBlock {
        if field.required {
            return CodeBlock.builder()
                .addLiteral("let \(field.cammelCaseName)Json = try payload.requiredDictionary(\"\(field.name)\")")
                .addCodeLine("let \(field.cammelCaseName) = try \(field.cleanTypeName)Impl.toModel(payload: \(field.cammelCaseName)Json)")
                .build()
        } else {
            let left = CodeBlock.builder().addLiteral("\(field.cammelCaseName)Json").build()
            let right = CodeBlock.builder().addLiteral("pauload[\"\(field.name)\"]").build()

            return CodeBlock.builder()
                .addLiteral("var \(field.cammelCaseName): \(field.cleanTypeName)? = nil")
                .addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
                    return CodeBlock.builder().addLiteral("\(field.cammelCaseName) = \(field.cleanTypeName)(payload: \(field.cammelCaseName)Json)").build()
                })
                .build()
        }
    }
}
