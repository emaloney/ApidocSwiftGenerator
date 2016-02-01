//
//  DummyService.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 2/1/16.
//
//

import Foundation
@testable import ApidocSwiftGenerator

struct DummyService {
    static func create() -> Service {
        let apidoc = "aidoc"
        let name = "name"
        let organization = Organization(key: "test")
        let application = Application(key: "test")
        let namespace = "apidoc"
        let version = "1.0"
        let baseUrl = "apidoc.test"
        let description: String? = nil
        let imports: [Import]? = nil
        let enums: [Enum]? = nil
        let unions: [Union]? = nil
        let models: [Model]? = nil
        let resources: [Resource]? = nil

        return Service(apidoc: apidoc,
            name: name,
            organization: organization,
            application: application,
            namespace: namespace,
            version: version,
            baseUrl: baseUrl,
            description: description,
            imports: imports,
            enums: enums,
            unions: unions,
            models: models,
            resources: resources)
    }
}
