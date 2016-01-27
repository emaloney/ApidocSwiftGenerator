//
//  SimpleGeneratorTest.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/14/16.
//
//

import XCTest
@testable import ApidocSwiftGenerator
import SwiftPoet

class SimpleGeneratorTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testObjectRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "map[string]", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        print(SimpleTypeGenerator.generateParseJsonObject(field).toString())

        XCTAssertTrue(true)
    }

    func testObjectOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "map[string]", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        print(SimpleTypeGenerator.generateParseJsonObject(field).toString())

        XCTAssertTrue(true)
    }


    func testBoolRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "bool", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonBool(field).toString()
        let test = "let testFieldName = try payload.requiredBool(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testBoolOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "bool", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonBool(field).toString()
        let test = "let testFieldName = payload.optionalBool(\"test_field_name\")"

//        print(result)
//        print(test)

        XCTAssertEqual(result, test)
    }

    func testIntRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "integer", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonInteger(field).toString()
        let test = "let testFieldName = try payload.requiredInt(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testIntOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "integer", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonInteger(field).toString()
        let test = "let testFieldName = payload[\"test_field_name\"] as? Int"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testDoubleRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "double", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonDouble(field).toString()
        let test = "let testFieldName = try payload.requiredDouble(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testDoubleOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "double", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonDouble(field).toString()
        let test = "let testFieldName = payload[\"test_field_name\"] as? Double"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testStringRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "string", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonString(field).toString()
        let test = "let testFieldName = try payload.requiredString(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testStringOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "string", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonString(field).toString()
        let test = "let testFieldName = payload[\"test_field_name\"] as? String"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testUnitGeneration() {
        let field = Field(name: "test_field_name", type: "unit", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonUnit(field).toString()
        let test = "let testFieldName = nil"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testGuidRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "uuid", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonGuid(field).toString()
        let test = "let testFieldName = try payload.requiredGUID(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testGuidOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "uuid", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonGuid(field).toString()

        let test =
        "\nlet testFieldNameStr = payload[\"test_field_name\"] as? String\n" +
        "var testFieldName: NSUUID? = nil\n" +
        "if let testFieldNameStr = testFieldNameStr {\n" +
        "    testFieldName = NSUUID(UUIDString: testFieldNameStr)\n" +
        "}"

        print(result)
        print(test)

        XCTAssertEqual(result, test)
    }

    func testDateRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "date-iso8601", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonDate(field).toString()
        let test = "let testFieldName = try payload.requiredISO8601Date(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testDateOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "date-iso8601", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let result = SimpleTypeGenerator.generateParseJsonDate(field).toString()
        let test = "let testFieldName = (payload[\"test_field_name\"] as? String)?.asDateISO8601()"

//        print(result)

        XCTAssertEqual(result, test)
    }

}
