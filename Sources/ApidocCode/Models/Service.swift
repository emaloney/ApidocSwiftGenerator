//
//  Service.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public struct Service {

    public let apidoc: String //apidoc version
    public let name: String
    public let organization: Organization
    public let application: Application
    public let namespace: String
    public let version: String
    public let baseUrl: String?
    public let description: String?
//    public let info: Info
//    public let headers: [Header]?
    public let imports: [Import]?
    public let enums: [Enum]?
    public let unions: [Union]?
    public let models: [Model]?
    public let resources: [Resource]?

    public init(apidoc: String, name: String, organization: Organization, application: Application, namespace: String, version: String, baseUrl: String?, description: String?, imports: [Import]?, enums: [Enum]?, unions: [Union]?, models: [Model]? = nil, resources: [Resource]? = nil) {
        self.apidoc = apidoc
        self.name = name
        self.organization = organization
        self.application = application
        self.namespace = namespace
        self.version = version
        self.baseUrl = baseUrl
        self.description = description
        self.imports = imports
        self.enums = enums
        self.unions = unions
        self.models = models
        self.resources = resources
    }

    public init(payload: NSDictionary) {
        let apidoc = (payload["apidoc"] as! NSDictionary)["version"] as! String
        let name = payload["name"] as! String
        let organization = Organization(payload: payload["organization"] as! NSDictionary)
        let application = Application(payload: payload["application"] as! NSDictionary)
        let namespace = payload["namespace"] as! String
        let version = payload["version"] as! String
        let description = payload["description"] as? String
        let baseUrl = payload["base_url"] as? String

        let imports: [Import]?
        if let importsJson = payload["imports"] as? [NSDictionary] {
            imports = importsJson.flatMap { i in
                return Import(payload: i)
            }
        } else {
            imports = nil
        }

        let unions: [Union]?
        if let unionsJson = payload["unions"] as? [NSDictionary] {
            unions = unionsJson.flatMap { u in
                return Union(payload: u)
            }
        } else {
            unions = nil
        }

        let enums: [Enum]?
        if let enumsJson = payload["enums"] as? [NSDictionary] {
            enums = enumsJson.flatMap { e in
                return Enum(payload: e)
            }
        } else {
            enums = nil
        }

        let models: [Model]?
        if let modelsJson = payload["models"] as? [NSDictionary] {
            models = modelsJson.flatMap { m in
                return Model(payload: m)
            }
        } else {
            models = nil
        }

        self.init(apidoc: apidoc, name: name, organization: organization, application: application, namespace: namespace, version: version, baseUrl: baseUrl, description: description, imports: imports, enums: enums, unions: unions, models: models)
    }
}