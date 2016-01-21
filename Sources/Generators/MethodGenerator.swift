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
        lastLineCB.addEmitObject(.Literal, any: "self.init(")

        var first = true
        model.fields.forEach { field in
            if !first {
                lastLineCB.addEmitObject(.Literal, any: ",")
            }
            lastLineCB.addEmitObject(.Literal, any: PoetUtil.cleanCammelCaseString(field.name))
            lastLineCB.addEmitObject(.Literal, any: ":")
            lastLineCB.addEmitObject(.Literal, any: PoetUtil.cleanCammelCaseString(field.name))
            first = false
        }

        lastLineCB.addEmitObject(.Literal, any: ")")
        cb.addCodeBlock(lastLineCB.build())
        mb.addCode(cb.build())
        return mb.build()
    }

    public static func modelToJson(service: Service, model: Model) -> MethodSpec {
        let mb = MethodSpec.builder(ToJsonFunctionGenerator.functionName)

        mb.addReturnType(TypeName(keyword: "JSONEncoderResult<AnyObject>"))

        let cb = CodeBlock.builder()

        cb.addCodeBlock(CodeBlock.builder().addEmitObject(.Literal, any:
            "var \(MethodGenerator.toJSONVarName) = [String : AnyObject]()"
        ).build())

        model.fields.forEach { field in
            cb.addCodeBlock(FieldGenerator.toJsonCodeBlock(field, service: service))
        }

        cb.addCodeBlock(CodeBlock.builder().addEmitObject(.Literal, any:
            "return .Succeeded(\(MethodGenerator.toJSONVarName))"
        ).build())

        mb.addCode(cb.build())
        return mb.build()
    }
}
