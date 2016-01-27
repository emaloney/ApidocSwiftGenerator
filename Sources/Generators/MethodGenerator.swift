//
//  MethodGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation
import SwiftPoet

public struct MethodGenerator {
    public static let toJSONVarName = "resultJSON"

    public static func generateJsonParsingInit(service: Service, model: Model) -> MethodSpec {
        let mb = MethodSpec.builder("init")

        mb.addParameter(ParameterSpec.builder("payload", type: TypeName.NSDictionary).build())
        if model.canThrow(service) {
            mb.canThrowError()
        }

        let cb = CodeBlock.builder()

        model.fields.forEach { field in
            cb.addCodeBlock(FieldGenerator.generateJsonParse(field, service: service))
        }

        let lastLineCB = CodeBlock.builder()
        lastLineCB.addLiteral("self.init(")

        var first = true
        model.fields.forEach { field in
            if !first {
                lastLineCB.addLiteral(",")
            }
            lastLineCB.addLiteral(field.cammelCaseName)
            lastLineCB.addLiteral(":")
            lastLineCB.addLiteral(field.cammelCaseName)
            first = false
        }

        lastLineCB.addLiteral(")")
        cb.addCodeBlock(lastLineCB.build())
        mb.addCode(cb.build())
        return mb.build()
    }

    public static func modelToJson(service: Service, model: Model) -> MethodSpec {
        let mb = MethodSpec.builder(ToJsonFunctionGenerator.functionName)
            .addReturnType(TypeName(keyword: "JSONEncoderResult<AnyObject>"))
            .addModifier(.Public)

        let cb = CodeBlock.builder()

        cb.addCodeLine("var \(MethodGenerator.toJSONVarName) = [String : AnyObject]()")

        model.fields.forEach { field in
            cb.addCodeBlock(FieldGenerator.toJsonCodeBlock(field, service: service))
        }

        cb.addCodeLine("return .Succeeded(\(MethodGenerator.toJSONVarName))")

        mb.addCode(cb.build())
        return mb.build()
    }
}
