//
//  ToJsonFunctionGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/20/16.
//
//

import Foundation
import SwiftPoet

public struct ToJsonFunctionGenerator {
    internal static let functionName = "toJSON"
    /*
    // if required
    requiredBlock

    // else
    if let fieldName = fieldName {
        requiredBlock
    }
    */
    internal static func generate(field: Field, requiredBlockGen: (Field) -> CodeBlock) -> CodeBlock {
        let cammelCaseName = PoetUtil.cleanCammelCaseString(field.name)

        let requiredCodeBlock = requiredBlockGen(field)

        let optionalCodeBlock = ToJsonFunctionGenerator.optionalGenerator(requiredCodeBlock, cammelCaseName: cammelCaseName)

        return ToJsonFunctionGenerator.dualGenerator(field, requiredCodeBlock: requiredCodeBlock, optionalCodeBlock: optionalCodeBlock)
    }

    private static func dualGenerator(field: Field, requiredCodeBlock: CodeBlock, optionalCodeBlock: CodeBlock) -> CodeBlock {
        let cb = CodeBlock.builder()
        if field.required {
            cb.addCodeBlock(requiredCodeBlock)
        } else {
            cb.addCodeBlock(optionalCodeBlock)
        }
        return cb.build()
    }

    private static func optionalGenerator(body: CodeBlock, cammelCaseName: String) -> CodeBlock {
        let cb = CodeBlock.builder()

        let left = CodeBlock.builder().addEmitObject(.Literal, any: "let \(cammelCaseName)").build()
        let right = CodeBlock.builder().addEmitObject(.Literal, any: cammelCaseName).build()
        let compare = ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)

        let controlFlow = ControlFlow.ifControlFlow(body, compare)
        
        return cb.addEmitObjects(controlFlow.emittableObjects).build()
    }
}
