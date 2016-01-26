//
//  ApidocGeneratorConstructor.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import Foundation
import CleanroomLogger
import SwiftPoet

public class ApidocGeneratorConstructor {

    let loader: ApidocURLLoader

    public init () {

        let token = "9Rcw92CkB9FqnkI4u4AAHP5V7zZrNaOmmdZsya4ObAzX91NiPhaoJCgLVHIRppgKA7NyLJqQZk1sGUet"
        let email = "swift-generator-test@googlegroups.com"
        let password = "swiftgeneratortest"


        let projectUrl = URLConstructor.create("swift-test", applicationKey: "apidoc-api-swift-test", version: nil)!

        loader = ApidocURLLoader(url: projectUrl, token: token, email: email, password: password)
    }

    public func generate(callback: () -> Void) {
        loader.load { result in
            switch result {
            case .Failed(_):
                Log.error?.trace()
            case .Succeeded(let data):
                if let json = data as? NSDictionary,
                    let serviceJson = json["service"] as? NSDictionary {

                        let service = Service(payload: serviceJson)

                        let app = ApidocGenerator.generate(service)

                        let folderBuilder = FolderBuilder()

                        do {
                            try folderBuilder.deleteFolder("/Users/kdorman/Documents/" + "SwiftGenerationTest")
                            print("Removed root folder")
                            try folderBuilder.createFolder("SwiftGenerationTest", atPath: "/Users/kdorman/Documents", overwriteStyle: .Overwrite)
                            print("Created root folder")

                            ApidocGeneratorConstructor.generateFiles(app.enums, type: .Enum)

                            ApidocGeneratorConstructor.generateFiles(app.models, type: .Model)

                            ApidocGeneratorConstructor.generateFiles(app.unions, type: .Union)

                            ApidocGeneratorConstructor.generateFiles(app.resources, type: .Resource)
                        } catch {
                            print("\(error)")
                        }

                        callback()
                        
                } else {
                    Log.error?.trace()
                }
            }
        }
        
    }

    private static func generateFiles(files: [PoetFile]?, type: ApidocRepresentation) {
        guard let files = files where !files.isEmpty else {
            print("Exiting early. Found an empty dataset for \(type.rawValue)")
            return
        }

        let folderBuilder = FolderBuilder()
        let fileBuilder = FileBuilder()

        do {
            let typeFolder = try folderBuilder.createFolder(type.rawValue, atPath: "/Users/kdorman/Documents/SwiftGenerationTest", overwriteStyle: .Overwrite)
            print("Created \(type.rawValue) folder")

            try files.forEach { file in
                guard let fileName = file.fileName else {
                    print("Unable to create file because it does not have a name")
                    return
                }
                try fileBuilder.createFile(fileName, atUrlPath: typeFolder, contents: file.fileContents)
                print("Created \(fileName).swift in folder \(type.rawValue)")
            }

        } catch {
            print("\(error)")
        }
    }

}

public struct Apidoc {
    public typealias Result = TransactionResult<AnyObject?>
    public typealias ApidocJsonHandler = (Result) -> Void
    public typealias FileName = String
}
