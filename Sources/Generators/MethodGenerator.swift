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
    public func generateJsonParsingInit(service: Service, model: Model) -> MethodSpec {
        let mb = MethodSpec.builder("init")

        mb.addParameter(ParameterSpec.builder("payload", type: TypeName.NSDictionary).build())
        mb.canThrowError()

        let cb = CodeBlock.builder()

        model.fields.forEach { field in
            cb.addCodeBlock(FieldGenerator.generateJsonParse(field, service: service))
        }

        let lastLineCB = CodeBlock.builder()
        lastLineCB.addEmitObject(.Literal, any: "self.init(")

        var first = true
        model.fields.forEach { field in
            if !first {
                lastLineCB.addEmitObject(.Literal, any: ", ")
                first = false
            }
            lastLineCB.addEmitObject(.Literal, any: PoetUtil.cleanCammelCaseString(field.name))
            lastLineCB.addEmitObject(.Literal, any: ": ")
            lastLineCB.addEmitObject(.Literal, any: PoetUtil.cleanCammelCaseString(field.name))
        }

        lastLineCB.addEmitObject(.Literal, any: ")")
        cb.addCodeBlock(lastLineCB.build())
        mb.addCode(cb.build())
        return mb.build()
    }
}
