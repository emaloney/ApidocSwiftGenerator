//
//  FileSystemError.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

public enum FileSystemError: ErrorType {
    case DirectoryCollision
    case DirectoryNotFound(ErrorType)
    case OSXError(ErrorType)
    case InvalidFolderName(String)
    case InvalidFileName(String)
    case InvalidFileContents
    case FileCreationError(String)

    public var description: String {
        switch self {
        case .DirectoryCollision: return "Directory collision"
        case .DirectoryNotFound(let error): return "Directory not found \(error)"
        case .OSXError(let error): return "OSXError \(error)"
        case .InvalidFolderName(let str): return "Invalid folder name \(str)"
        case .InvalidFileName(let str): return "Invalid file name \(str)"
        case .InvalidFileContents: return "Invalid file contents"
        case .FileCreationError(let str): return "Error creating file \(str)"
        }
    }
}
