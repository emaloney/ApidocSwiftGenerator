//
//  ApidocGenerator.swift
//  Cleanroom Project
//
//  Created by Kyle Dorman on 1/4/16.
//  Copyright (c) 2016 Gilt Groupe. All rights reserved.
//

import CleanroomLogger
import SwiftPoet
import Foundation

public struct ApidocGenerator: Generator {
    public typealias ResultType = Application

    public static func generate(service: Service) -> Application {
        return Application(
            enums: EnumGenerator.generate(service),
            models: ModelGenerator.generate(service),
            resources: nil,
            unions: nil
        )
    }
}

public struct Application {
    let enums: [Apidoc.FileName : EnumSpec]?
    let models: [Apidoc.FileName : StructSpec]?
    let resources: [Apidoc.FileName : StructSpec]?
    let unions: [Apidoc.FileName : ProtocolSpec]?
}
