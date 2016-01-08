//
//  FolderBuilderTests.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import XCTest
import Foundation
@testable import ApidocSwiftGenerator

class FolderBuilderTests: XCTestCase {

    var documentsUrl: NSURL?

    let testFolderName = "swiftGeneratorFolderTest"

    override func setUp() {
        super.setUp()

        do {
            documentsUrl = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: false)
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

    func testSuccessfullyDiscoverDocumentsDirectoryWithURL() {
        guard let documentsUrl = documentsUrl else {
            XCTAssertTrue(false, "Failed to find documents folder")
            return
        }

        do {
            try FolderBuilder().discoverRootFolder(atUrlPath: documentsUrl) //createFolder(testFolderName, atUrlPath: documentsUrl)
            XCTAssertTrue(true, "Found documents folder")
        }
        catch {
            if let error = error as? FileSystemError {
                XCTAssertTrue(false, error.description)
            } else {
                XCTAssertTrue(false, "Unknown error \(error)")
            }
        }
    }

    func testSuccessfullyDiscoverDocumentsDirectoryWithStringPath() {
        guard let documentsUrl = documentsUrl, let urlPath = documentsUrl.path else {
            XCTAssertTrue(false, "Failed to find document folder")
            return
        }

        do {
            try FolderBuilder().discoverRootFolder(atPath: urlPath)
            XCTAssertTrue(true, "Found documents folder")
        }
        catch {
            if let error = error as? FileSystemError {
                XCTAssertTrue(false, error.description)
            } else {
                XCTAssertTrue(false, "Unknown error \(error)")
            }
        }
    }

    func testFailToDiscoverDocumentsDirectory() {
        guard let documentsUrl = documentsUrl else {
            XCTAssertTrue(false, "Failed to find document folder")
            return
        }

        do {
            try FolderBuilder().discoverRootFolder(atPath: documentsUrl.absoluteString + "thisDirectoryIsHopefullyNotThere")
            XCTAssertTrue(false, "UNEXPECTED: found crazy folder name")
        }
        catch {
            if let error = error as? FileSystemError {
                switch error {
                case .DirectoryNotFound:
                    XCTAssertTrue(true)
                default:
                    XCTAssertTrue(false, error.description)
                }
            } else {
                XCTAssertTrue(false, "Unknown error \(error)")
            }
        }
    }

    func testCreateEmptyDirectory() {
        guard let documentsUrl = documentsUrl else {
            XCTAssertTrue(false, "Failed to find document folder")
            return
        }

        do {
            try FolderBuilder().createFolder(testFolderName, atUrlPath: documentsUrl)
            XCTAssertTrue(true, "Folder created")
        }
        catch {
            if let error = error as? FileSystemError {
                XCTAssertTrue(false, error.description)
            } else {
                XCTAssertTrue(false, "Unknown error \(error)")
            }
        }
    }

    
}