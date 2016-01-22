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
    // if field.required
    requiredBlock

    // else
    if let fieldName = fieldName {
        requiredBlock
    }
    */
    internal static func generate(field: Field, requiredBlockGen: (Field) -> CodeBlock) -> CodeBlock {
        let requiredCodeBlock = requiredBlockGen(field)
        let optionalCodeBlock = ToJsonFunctionGenerator.optionalGenerator(requiredCodeBlock, cammelCaseName: field.cammelCaseName)

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
        let left = CodeBlock.builder().addLiteral("let \(cammelCaseName)").build()
        let right = CodeBlock.builder().addLiteral(cammelCaseName).build()

        return ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return body
        }
    }
}
