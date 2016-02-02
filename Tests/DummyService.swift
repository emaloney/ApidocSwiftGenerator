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
        let models: [Model]? = [Model(name: "totally_awesome", plural: "totally_awesome_sauce", description: nil, deprecation: nil, fields: [DummyField.create("awesome_score", type: "integer")])]
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

struct DummyField {
    static func create(name: String = "test_field", type: String = "string", required: Bool = true) -> Field {
        return Field(name: name, type: type, description: nil, deprecation: nil, _default: nil, required: required, minimum: nil, maximum: nil, example: nil)
    }
}
