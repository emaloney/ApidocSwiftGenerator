//
//  FileBuilder.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public class FileBuilder {

    public func createFile(fileName: String, fileType: String, atPath path: String, contents: String) throws {
        guard let urlPath = NSURL(string: path) else {
            throw FileSystemError.InvalidFolderName(path)
        }
        try createFile(fileName, fileType: fileType, atUrlPath: urlPath, contents: contents)
    }

    public func createFile(fileName: String, fileType: String, atUrlPath path: NSURL, contents: String) throws {
        let fullFileName = fileName + "." + fileType
        guard let fileUrl = NSURL(string: fullFileName, relativeToURL: path) else {
            throw FileSystemError.InvalidFileName(fullFileName)
        }

        guard let fileData = contents.dataUsingEncoding(NSUTF8StringEncoding) else {
            throw FileSystemError.InvalidFileContents
        }

        guard NSFileManager.defaultManager().createFileAtPath(fileUrl.path!, contents: fileData, attributes: nil) else {
            throw FileSystemError.FileCreationError(fileUrl.path!)
        }
    }
}
