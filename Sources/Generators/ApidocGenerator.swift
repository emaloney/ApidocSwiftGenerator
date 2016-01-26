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
    public typealias ResultType = GeneratorApplication

    public static func generate(service: Service) -> GeneratorApplication {
        return GeneratorApplication(
            enums: EnumGenerator.generate(service),
            models: ModelGenerator.generate(service),
            resources: ResourceGenerator.generate(service),
            unions: UnionGenerator.generate(service)
        )
    }
}

public struct GeneratorApplication {
    let enums: [Apidoc.FileName : EnumSpec]?
    let models: [Apidoc.FileName : StructSpec]?
    let resources: [Apidoc.FileName : ClassSpec]?
    let unions: [Apidoc.FileName : PrintableList]?
}
