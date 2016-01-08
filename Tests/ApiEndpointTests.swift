//
//  ApiEndpointTests.swift
//  Cleanroom Project
//
//  Created by Kyle Dorman on 1/4/16.
//  Copyright (c) 2016 Gilt Groupe. All rights reserved.
//

import XCTest
@testable import ApidocSwiftGenerator
import Alamofire

class ApiEndpointTests: XCTestCase {

    let token = "9Rcw92CkB9FqnkI4u4AAHP5V7zZrNaOmmdZsya4ObAzX91NiPhaoJCgLVHIRppgKA7NyLJqQZk1sGUet"
    let email = "swift-generator-test@googlegroups.com"
    let password = "swiftgeneratortest"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testPublicAccess() {
//        let readyExpectation = expectationWithDescription("ready")
//
//        let url = URLConstructor.create("bryzek", applicationKey: "apidoc-api", version: nil)!
//
//        let loader = ApidocURLLoader(url: url)
//
//        loader.load { result in
//            switch result {
//            case .Failed(let error):
//                print(error)
//            case .Succeeded(let data):
////                print(data)
//                readyExpectation.fulfill()
//            }
//        }
//
//        waitForExpectationsWithTimeout(5) { error in
//            XCTAssertNil(error, "Error")
//        }
//    }

//    func testPrivateAccess() {
//        let readyExpectation = expectationWithDescription("ready")
//
//        let projectUrl = URLConstructor.create("swift-test", applicationKey: "apidoc-api-swift-test", version: nil)!
//
//        let loader = ApidocURLLoader(url: projectUrl, token: token, email: email, password: password)
//
//        loader.load{ result in
//            switch result {
//            case .Failed(let error):
//                print(error)
//            case .Succeeded(let data):
//                if let json = data as? NSDictionary {
////                    print(json["service"]!)
//                    print("********************")
//                    for (k, v) in json {
//                        print(k)
//                    }
//                }
//
//                readyExpectation.fulfill()
//            }
//        }
//
//        waitForExpectationsWithTimeout(5) { error in
//            XCTAssertNil(error, "Error")
//        }
//    }

    func testParseJson() {
        let readyExpectation = expectationWithDescription("ready")

        let g = ApidocSwiftGenerator()
        g.generate {
            readyExpectation.fulfill()
        }


        waitForExpectationsWithTimeout(3) { error in
            XCTAssertNil(error, "Error")
        }
    }

    
}
