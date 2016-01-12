//
//  FolderBuilder.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public class FolderBuilder {

    public init() {}

    public func createFolder(folderName: String, atPath path: String, overwriteStyle: OverwriteStyle = .FailOnCollision) throws -> NSURL {
        let folderURL = NSURL(fileURLWithPath: path, isDirectory: true)
        return try createFolder(folderName, atUrlPath: folderURL, overwriteStyle: overwriteStyle)
    }

    public func createFolder(folderName: String, atUrlPath url: NSURL, overwriteStyle: OverwriteStyle = .FailOnCollision) throws -> NSURL {
        let manager = NSFileManager.defaultManager()

        let contents = try discoverRootFolder(atUrlPath: url)

        let newFolderURL = NSURL.fileURLWithPath(url.path! + "/" + folderName, isDirectory: true)

        try contents.forEach { f in
            if newFolderURL == f {
                if overwriteStyle == .FailOnCollision {
                    throw FileSystemError.DirectoryCollision
                } else {
                    try deleteFolder(newFolderURL.path!)
                }
            }
        }

        try manager.createDirectoryAtURL(newFolderURL, withIntermediateDirectories: false, attributes: nil)

        return newFolderURL
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

    public func deleteFiles(fileUrls: [NSURL]) throws {
        let manager = NSFileManager.defaultManager()

        for url in fileUrls {
            try manager.removeItemAtURL(url)
        }
    }

    public func deleteFolder(path: String) throws {
        let manager = NSFileManager.defaultManager()
        let url = NSURL(fileURLWithPath: path, isDirectory: true)
        try manager.removeItemAtURL(url)
    }
}

public enum OverwriteStyle {
    case Overwrite
    case FailOnCollision
}
