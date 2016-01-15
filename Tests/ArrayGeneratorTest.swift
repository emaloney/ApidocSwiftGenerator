//
//  ArrayGeneratorTest.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/15/16.
//
//

import XCTest
@testable import ApidocSwiftGenerator
import SwiftPoet

class ArrayGeneratorTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testRequiredModel() {

        let cb = ArrayGenerator.generateParseArrayJson("Item", fieldName: "unshppable_items", required: true, isModel: true)

        print(cb.toString())
        
    }

    func testOptionalModel() {

        let cb = ArrayGenerator.generateParseArrayJson("PaymentMethodType", fieldName: "payment_method_types", required: false, isModel: true)

        print(cb.toString())

    }

    func testRequiredModelParseJson() {
        let field = Field(name: "test_field_name", type: "test_type", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)

        print(ModelGenerator.generateParseModelJson(field).toString())
    }

    func testOptionalModelParseJson() {
        let field = Field(name: "test_field_name", type: "test_type", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)

        print(ModelGenerator.generateParseModelJson(field).toString())
    }
}
