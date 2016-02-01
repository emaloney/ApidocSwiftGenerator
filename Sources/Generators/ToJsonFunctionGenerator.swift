//
//  ToJsonFunctionGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/20/16.
//
//

import Foundation
import SwiftPoet

internal struct ToJsonFunctionGenerator {
    internal static let functionName = "toJSON"
    internal static let varName = "resultJSON"
    /*
    // required
    requiredBlock

    // optional
    if let paramName = paramName {
        requiredBlock
    }
    */
    internal static func generate(paramName: String, required: Bool, requiredBlockGen: () -> CodeBlock) -> CodeBlock {
        let requiredCodeBlock = requiredBlockGen()
        let optionalCodeBlock = ToJsonFunctionGenerator.optionalGenerator(requiredCodeBlock, paramName: paramName)

        return ToJsonFunctionGenerator.dualGenerator(required, requiredCodeBlock: requiredCodeBlock, optionalCodeBlock: optionalCodeBlock)
    }

    private static func dualGenerator(required: Bool, requiredCodeBlock: CodeBlock, optionalCodeBlock: CodeBlock) -> CodeBlock {
        if required {
            return requiredCodeBlock
        } else {
            return optionalCodeBlock
        }
    }

    private static func optionalGenerator(body: CodeBlock, paramName: String) -> CodeBlock {
        let left = CodeBlock.builder().addLiteral("let \(paramName)").build()
        let right = CodeBlock.builder().addLiteral(paramName).build()

        return ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
            return body
        }
    }
}
