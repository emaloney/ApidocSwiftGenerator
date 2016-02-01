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

internal struct ApidocGenerator: Generator {
    internal typealias ResultType = GeneratorApplication

    internal static func generate(service: Service) -> GeneratorApplication {
        return GeneratorApplication(
            enums: EnumGenerator.generate(service),
            models: ModelGenerator.generate(service),
            resources: ResourceGenerator.generate(service),
            unions: UnionGenerator.generate(service)
        )
    }
}

internal struct GeneratorApplication {
    let enums: [PoetFile]?
    let models: [PoetFile]?
    let resources: [PoetFile]?
    let unions: [PoetFile]?
}
