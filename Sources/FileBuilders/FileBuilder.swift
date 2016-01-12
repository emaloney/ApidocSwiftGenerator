//
//  FileBuilder.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation
import SwiftPoet

public class FileBuilder {

    public init() {}

    public func createFile(fileName: String, atPath path: String, contents: String) throws {
        guard let urlPath = NSURL(string: path) else {
            throw FileSystemError.InvalidFolderName(path)
        }
        try createFile(fileName, atUrlPath: urlPath, contents: contents)
    }

    public func createFile(fileName: String, atUrlPath path: NSURL, contents: String) throws {
        let fullFileName = PoetUtil.cleanTypeName(fileName) + ".swift"
        guard let fileUrl = NSURL(string: fullFileName, relativeToURL: path) else {
            throw FileSystemError.InvalidFileName(fullFileName)
        }

        print(fileUrl)

        guard let fileData = contents.dataUsingEncoding(NSUTF8StringEncoding) else {
            throw FileSystemError.InvalidFileContents
        }

        guard NSFileManager.defaultManager().createFileAtPath(fileUrl.path!, contents: fileData, attributes: nil) else {
            throw FileSystemError.FileCreationError(fileUrl.path!)
        }
    }
}
