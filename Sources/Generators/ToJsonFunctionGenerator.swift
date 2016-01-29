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
    internal static func generate(fieldName: String, required: Bool, requiredBlockGen: () -> CodeBlock) -> CodeBlock {
        let requiredCodeBlock = requiredBlockGen()
        let optionalCodeBlock = ToJsonFunctionGenerator.optionalGenerator(requiredCodeBlock, cammelCaseName: fieldName)

        return ToJsonFunctionGenerator.dualGenerator(required, requiredCodeBlock: requiredCodeBlock, optionalCodeBlock: optionalCodeBlock)
    }

    internal static func generate(field: Field, requiredBlockGen: (Field) -> CodeBlock) -> CodeBlock {
        let requiredCodeBlock = requiredBlockGen(field)
        let optionalCodeBlock = ToJsonFunctionGenerator.optionalGenerator(requiredCodeBlock, cammelCaseName: field.cammelCaseName)

        return ToJsonFunctionGenerator.dualGenerator(field.required, requiredCodeBlock: requiredCodeBlock, optionalCodeBlock: optionalCodeBlock)
    }

    private static func dualGenerator(required: Bool, requiredCodeBlock: CodeBlock, optionalCodeBlock: CodeBlock) -> CodeBlock {
        if required {
            return requiredCodeBlock
        } else {
            return optionalCodeBlock
        }
    }

    private static func optionalGenerator(body: CodeBlock, cammelCaseName: String) -> CodeBlock {
        let left = CodeBlock.builder().addLiteral("let \(cammelCaseName)").build()
        let right = CodeBlock.builder().addLiteral(cammelCaseName).build()

        return ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return body
        }
    }
}
