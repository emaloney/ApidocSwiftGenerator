//
//  ApidocSwiftGenerator.swift
//  Cleanroom Project
//
//  Created by Kyle Dorman on 1/4/16.
//  Copyright (c) 2016 Gilt Groupe. All rights reserved.
//

import CleanroomLogger
import SwiftPoet
import Foundation

public class ApidocSwiftGenerator
{

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

                    print(service.apidoc)

                    callback()

                } else {
                    Log.error?.trace()
                }
            }
        }

    }
}

public struct Apidoc {
    public typealias Result = TransactionResult<AnyObject?>
    public typealias ApidocJsonHandler = (Result) -> Void
}
