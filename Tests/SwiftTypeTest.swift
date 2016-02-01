//
//  SwiftTypeTest.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/14/16.
//
//

import XCTest
@testable import ApidocSwiftGenerator

class SwiftTypeTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDictionary() {
        let type = SwiftType(apidocType: "map[string]", service: nil)

        switch type.type {
        case .Dictionary(let leftType, let rightType):
            XCTAssertEqual(leftType.swiftTypeString, SwiftType.StringType.swiftTypeString)
            XCTAssertEqual(rightType.swiftTypeString, SwiftType.StringType.swiftTypeString)
        default:
            XCTAssertTrue(false, "unexpected type \(type.swiftTypeString)")
        }
    }

    func testArray() {
        let type = SwiftType(apidocType: "[integer]", service: nil)

        switch type.type {
        case .Array(let innerType):
            XCTAssertEqual(innerType.swiftTypeString, SwiftType.Integer.swiftTypeString)
        default:
            XCTAssertTrue(false, "unexpected type \(type.swiftTypeString)")
        }
    }
}
