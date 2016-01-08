//
//  FolderBuilder.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public class FolderBuilder {

//    public typealias FileSystemResult = Result<String, FileSystemError>

    public init() {}

    public func createFolder(folderName: String, atPath path: String, overwriteStyle: OverwriteStyle = .Parallel) throws {
        let folderURL = NSURL(fileURLWithPath: path, isDirectory: true)
        try createFolder(folderName, atUrlPath: folderURL, overwriteStyle: overwriteStyle)
    }

    public func createFolder(folderName: String, atUrlPath url: NSURL, overwriteStyle: OverwriteStyle = .Parallel) throws {
        let manager = NSFileManager.defaultManager()

        let contents = try discoverRootFolder(atUrlPath: url)

        guard contents.count == 0 || overwriteStyle != .FailIfNotEmpty else {
            throw FileSystemError.DirectoryContainsFiles
        }

        guard let newFolderURL = NSURL(string: folderName, relativeToURL: url) else {
            throw FileSystemError.InvalidFolderName(folderName)
        }

        try manager.createDirectoryAtURL(newFolderURL, withIntermediateDirectories: false, attributes: nil)

        if contents.count > 0 && overwriteStyle == .Overwrite {
            try deleteFiles(contents)
        }
    }

    public func discoverRootFolder(atUrlPath url: NSURL) throws -> [NSURL] {
        do {
            let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants)
            return contents
        }
        catch {
            throw FileSystemError.DirectoryNotFound(error)
        }
    }

    public func discoverRootFolder(atPath path: String) throws -> [NSURL] {
        guard let url = NSURL(string: path) else {
            throw FileSystemError.InvalidFolderName(path)
        }
        return try discoverRootFolder(atUrlPath: url)
    }

    private func deleteFiles(fileUrls: [NSURL]) throws {
        let manager = NSFileManager.defaultManager()

        for url in fileUrls {
            try manager.removeItemAtURL(url)
        }
    }
}

public enum FileSystemError: ErrorType {
    case DirectoryContainsFiles
    case DirectoryNotFound(ErrorType)
    case OSXError(ErrorType)
    case InvalidFolderName(String)
    case InvalidFileName(String)
    case InvalidFileContents
    case FileCreationError(String)

    public var description: String {
        switch self {
        case .DirectoryContainsFiles: return "Directory contains a file"
        case .DirectoryNotFound(let error): return "Directory not found \(error)"
        case .OSXError(let error): return "OSXError \(error)"
        case .InvalidFolderName(let str): return "Invalid folder name \(str)"
        case .InvalidFileName(let str): return "Invalid file name \(str)"
        case .InvalidFileContents: return "Invalid file contents"
        case .FileCreationError(let str): return "Error creating file \(str)"
        }
    }
}

public enum OverwriteStyle {
    case Overwrite
    case Parallel
    case FailIfNotEmpty
}