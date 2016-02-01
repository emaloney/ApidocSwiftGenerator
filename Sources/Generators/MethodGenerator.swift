//
//  MethodGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation
import SwiftPoet

internal struct MethodGenerator {
    internal static func jsonParsingInit(model: Model, service: Service) -> MethodSpec {
        let mb = MethodSpec.builder("init")
            .addModifier(.Public)
            .addParameter(ParameterSpec.builder("payload", type: TypeName.NSDictionary).build())

        if model.canThrow(service) {
            mb.canThrowError()
        }

        let cb = CodeBlock.builder()

        model.fields.forEach { field in
            cb.addCodeBlock(FieldGenerator.jsonParseCodeBlock(field, service: service))
        }

        cb.addEmitObject(.NewLine)
        cb.addCodeLine("self.init(")

        let paramStrings: [String] = model.fields.map { field -> String in
            return "\(field.cammelCaseName) : \(field.cammelCaseName)"
        }

        cb.addLiteral(paramStrings.joinWithSeparator(", ")).addLiteral(")")

        mb.addCode(cb.build())
        return mb.build()
    }

    internal static func toJsonFunction(model: Model, service: Service) -> MethodSpec {
        let mb = MethodSpec.builder(ToJsonFunctionGenerator.functionName)
            .addReturnType(TypeName(keyword: "ApidocJSONEncoderResult<AnyObject>"))
            .addModifier(.Public)

        let cb = CodeBlock.builder()
            .addCodeLine("var \(ToJsonFunctionGenerator.varName) = [String : AnyObject]()")

        model.fields.forEach { field in
            cb.addCodeBlock(FieldGenerator.toJsonCodeBlock(field, service: service))
        }

        cb.addCodeLine("return .Succeeded(\(ToJsonFunctionGenerator.varName))")

        mb.addCode(cb.build())
        return mb.build()
    }
}
