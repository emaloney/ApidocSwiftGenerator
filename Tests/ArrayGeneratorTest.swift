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

        let cb = ArrayGenerator.generateParseArrayModelJson("Item", fieldName: "unshippable_items", required: true, canThrow: true)

        let result =
        "\nlet unshippableItems = try payload.requiredArrayWithType(\"unshippable_items\") {\n" +
        "    ( json: NSDictionary ) throws -> Item in\n" +
        "        try Item(payload: json)\n}"

//        print(cb.toString())
//        print(result)

        XCTAssertEqual(cb.toString(), result)
    }

    func testOptionalModel() {

        let cb = ArrayGenerator.generateParseArrayModelJson("PaymentMethodType", fieldName: "payment_method_types", required: false, canThrow: false)

        let result =
        "\nlet paymentMethodTypes = payload.optionalArrayWithType(\"payment_method_types\") {\n" +
        "    ( json: NSDictionary ) -> PaymentMethodType in\n" +
        "        PaymentMethodType(payload: json)\n}"

//        print(cb.toString())
//        print(result)

        XCTAssertEqual(cb.toString(), result)
    }

    func testRequiredEnum() {

        let cb = ArrayGenerator.generateParseArrayEnumJson("Item", fieldName: "unshippable_items", required: true)

        let result =
        "\nlet unshippableItems = try payload.requiredArrayWithType(\"unshippable_items\") {\n" +
        "    ( rawValue: NSString ) -> Item? in\n" +
        "        Item(rawValue: rawValue as String)\n}"
//
//        print(result)
//        print(cb.toString())

        XCTAssertEqual(cb.toString(), result)

    }

    func testOptionalEnum() {

        let cb = ArrayGenerator.generateParseArrayEnumJson("PaymentMethodType", fieldName: "payment_method_types", required: false)

        let result =
        "\nlet paymentMethodTypes = payload.optionalArrayWithType(\"payment_method_types\") {\n" +
        "    ( rawValue: NSString ) -> PaymentMethodType? in\n" +
        "        PaymentMethodType(rawValue: rawValue as String)\n}"

//        print(cb.toString())
//        print(result)

        XCTAssertEqual(cb.toString(), result)
        
    }

    func testRequiredSimpleType() {

        let cb = ArrayGenerator.generateParseArraySimpleTypeJson("Item", fieldName: "unshippable_items", required: true)

        let result = "let unshippableItems = try payload.requiredArray(\"unshippable_items\").flatMap { $0 as? Item }"

        print(result)
        print(cb.toString())

        XCTAssertEqual(cb.toString(), result)

    }

    func testOptionalSimpleType() {

        let cb = ArrayGenerator.generateParseArraySimpleTypeJson("String", fieldName: "payment_method_types", required: false)

        let result = "let paymentMethodTypes = payload[\"payment_method_types\"] as? [String]"

        print(cb.toString())
        print(result)

        XCTAssertEqual(cb.toString(), result)
        
    }

    func testRequiredModelParseJson() {
        let field = Field(name: "test_field_name", type: "test_type", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let cb = ModelGenerator.generateParseModelJson(field)
        let result =
        "\nlet testFieldNameJson = try payload.requiredDictionary(\"test_field_name\")\n" +
        "let testFieldName = try TestType(payload: testFieldNameJson)"

//        print(result)
//        print(cb.toString())

        XCTAssertEqual(cb.toString(), result)
    }

    func testOptionalModelParseJson() {
        let field = Field(name: "test_field_name", type: "test_type", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)

        let cb = ModelGenerator.generateParseModelJson(field)
        let result =
        "\nvar testFieldName: TestType? = nil\n" +
        "if let testFieldNameJson = payload[\"test_field_name\"] as? NSDictionary {\n" +
        "    testFieldName = TestType(payload: testFieldNameJson)\n}"

//        print(result)
//        print(ModelGenerator.generateParseModelJson(field).toString())

        XCTAssertEqual(cb.toString(), result)
    }
}
