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
        let type = SwiftType(apidocType: "string", service: DummyService.create()) // dictionary generator takes left type
        let cb = DictionaryGenerator.jsonParseCodeBlock(field, valueType: type, service: DummyService.create())

        let result =
        "\nvar testFieldName = [String : String]()\n" +
        "for (key, value) in try payload.requiredDictionary(\"test_field_name\") {\n" +
        "    \n" +
        "    guard let kType = key as? String, let vType = value as? String else {\n" +
        "        throw DataTransactionError.DataFormatError(\"Error creating field test_field_name. Expected a String found \\(key) and \\(value)\")\n" +
        "    }\n" +
        "    testFieldName[kType] = vType\n" +
        "}"

//        print(cb.toString())
//        print(result)

        XCTAssertEqual(result, cb.toString())
    }

    func testObjectOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "map[string]", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "string", service: DummyService.create())
        let cb = DictionaryGenerator.jsonParseCodeBlock(field, valueType: type, service: DummyService.create())

        let result =
        "\nvar testFieldName: [String : String]? = nil\n" +
        "if let dict = payload[\"test_field_name\"] as? NSDictionary {\n" +
        "    \n" +
        "    testFieldName = [String : String]()\n" +
        "    for (key, value) in dict {\n" +
        "        if let kType = key as? String, let vType = value as? String {\n" +
        "            testFieldName?[kType] = vType\n" +
        "        }\n" +
        "    }\n" +
        "}"

//        print(cb.toString())
//        print(result)

        XCTAssertEqual(cb.toString(), result)
    }

    func testDictionaryModelGenerationRequired() {
        let field = DummyField.create("test_field_name", type: "map[totally_awesome]")
//        let type = SwiftType(apidocType: "string", service: DummyService.create())
        let cb = FieldGenerator.jsonParseCodeBlock(field, service: DummyService.create())

        let result =
        "\nvar testFieldName = [String : TotallyAwesome]()\n" +
            "for (key, value) in try payload.requiredDictionary(\"test_field_name\") {\n" +
            "    \n" +
            "    guard let kType = key as? String, let vType = value as? NSDictionary else {\n" +
            "        throw DataTransactionError.DataFormatError(\"Error creating field test_field_name. Expected a NSDictionary found \\(key) and \\(value)\")\n" +
            "    }\n" +
            "    testFieldName[kType] = try TotallyAwesome(payload: vType)\n" +
        "}"

//                print(cb.toString())
//                print(result)

        XCTAssertEqual(cb.toString(), result)
    }

    func testDictionaryModelGenerationOptional() {
        let field = DummyField.create("test_field_name", type: "map[totally_awesome]", required: false)
        let cb = FieldGenerator.jsonParseCodeBlock(field, service: DummyService.create())

        let result =
        "\nvar testFieldName: [String : TotallyAwesome]? = nil\n" +
            "if let dict = payload[\"test_field_name\"] as? NSDictionary {\n" +
            "    \n" +
            "    testFieldName = [String : TotallyAwesome]()\n" +
            "    for (key, value) in dict {\n" +
            "        if let kType = key as? String, let vType = value as? NSDictionary {\n" +
            "            testFieldName?[kType] = try TotallyAwesome(payload: vType)\n" +
            "        }\n" +
            "    }\n" +
        "}"

//        print(cb.toString())
//        print(result)

        XCTAssertEqual(cb.toString(), result)
    }


    func testBoolRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "boolean", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "boolean", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = try payload.requiredBool(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testBoolOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "boolean", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "boolean", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = payload.optionalBool(\"test_field_name\")"

//        print(result)
//        print(test)

        XCTAssertEqual(result, test)
    }

    func testIntRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "integer", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "integer", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = try payload.requiredInt(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testIntOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "integer", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "integer", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = payload[\"test_field_name\"] as? Int"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testDoubleRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "double", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "double", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = try payload.requiredDouble(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testDoubleOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "double", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "double", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = payload[\"test_field_name\"] as? Double"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testStringRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "string", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "string", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = try payload.requiredString(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testStringOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "string", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "string", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = payload[\"test_field_name\"] as? String"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testUnitGeneration() {
        let field = Field(name: "test_field_name", type: "unit", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "unit", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = nil"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testGuidRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "uuid", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "uuid", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = try payload.requiredGUID(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testGuidOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "uuid", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "uuid", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()

        let test =
        "\nvar testFieldName: NSUUID? = nil\n" +
        "if let testFieldNameStr = payload[\"test_field_name\"] as? String {\n" +
        "    testFieldName = NSUUID(UUIDString: testFieldNameStr)\n" +
        "}"

//        print(result)
//        print(test)

        XCTAssertEqual(result, test)
    }

    func testDateRequiredGeneration() {
        let field = Field(name: "test_field_name", type: "date-iso8601", description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "date-iso8601", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = try payload.requiredISO8601Date(\"test_field_name\")"

//        print(result)

        XCTAssertEqual(result, test)
    }

    func testDateOptionalGeneration() {
        let field = Field(name: "test_field_name", type: "date-iso8601", description: nil, deprecation: nil, _default: nil, required: false, minimum: nil, maximum: nil, example: nil)
        let type = SwiftType(apidocType: "date-iso8601", service: DummyService.create())
        let result = SimpleTypeGenerator.parseJsonCodeBlock(field, swiftType: type).toString()
        let test = "let testFieldName = (payload[\"test_field_name\"] as? String)?.asDateISO8601()"

//        print(result)

        XCTAssertEqual(result, test)
    }

}
