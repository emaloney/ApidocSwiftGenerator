//
//  FileBuilderTests.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import XCTest
@testable import ApidocSwiftGenerator

class FileBuilderTests: XCTestCase {
    
    var documentsUrl: NSURL?
    let testFolderName = "swiftGeneratorFolderTest"
    var testFolderUrl: NSURL?
    let testFileName = "swiftGeneratorFileTest"

    let testFolderContents = "/** SwiftGeneratorFileTest.swift */ \n import Foundation \n public static class SwiftGeneratorFileTest { \n public init() {} \n } \n"

    override func setUp() {
        super.setUp()

        do {
            documentsUrl = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: false)
            testFolderUrl = try FolderBuilder().createFolder(testFolderName, atUrlPath: documentsUrl!)
        } catch {
            documentsUrl = nil
        }
    }

    override func tearDown() {
        do {
            let createdFileUrl = NSURL(string: testFolderName, relativeToURL: documentsUrl)!
            try NSFileManager.defaultManager().removeItemAtURL(createdFileUrl)
        } catch {
            print("File " + testFolderName + " has not been created yet")
        }

        documentsUrl = nil
        super.tearDown()
    }

    
    func testCreateFileSuccess() {
        guard let testFolderUrl = testFolderUrl else {
            XCTAssertTrue(false, "Failed to find test folder")
            return
        }

        do {
            try FileBuilder().createFile(testFileName, atUrlPath: testFolderUrl, contents: testFolderContents)
            XCTAssertTrue(true, "File created")
        }
        catch {
            if let error = error as? FileSystemError {
                XCTAssertTrue(false, error.description)
            } else {
                XCTAssertTrue(false, "Unknown error \(error)")
            }
        }
    }

    func testCreateFileFailure() {
        guard let testFolderUrl = testFolderUrl else {
            XCTAssertTrue(false, "Failed to find test folder")
            return
        }

        do {
            try FileBuilder().createFile("/////" + testFileName, atUrlPath: testFolderUrl, contents: testFolderContents)
            XCTAssertTrue(false, "Unexpected: file created")
        }
        catch {
            if let error = error as? FileSystemError {
                switch error {
                case .FileCreationError:
                    XCTAssertTrue(true, error.description)
                    break
                default:
                    XCTAssertTrue(false, "Unexpected error \(error.description)")
                    break
                }
            } else {
                XCTAssertTrue(false, "Unknown error \(error)")
            }
        }
    }
}
