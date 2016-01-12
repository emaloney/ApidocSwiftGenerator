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
    public let organization: String//: Organization
    public let application: String
    public let namespace: String
    public let version: String
    public let baseUrl: String?
    public let description: String?
//    public let info: Info
//    public let headers: [Header]?
//    public let imports: [Import]?
    public let enums: [Enum]?
    public let unions: [Union]?
    public let models: [Model]?
    public let resources: [Resource]?

    public init(apidoc: String, name: String, organization: String, application: String, namespace: String, version: String, baseUrl: String?, description: String?, enums: [Enum]?, unions: [Union]?, models: [Model]? = nil, resources: [Resource]? = nil) {
        self.apidoc = apidoc
        self.name = name
        self.organization = organization
        self.application = application
        self.namespace = namespace
        self.version = version
        self.baseUrl = baseUrl
        self.description = description
        self.enums = enums
        self.unions = unions
        self.models = models
        self.resources = resources
    }

    public init(payload: NSDictionary) {
        let apidoc = (payload["apidoc"] as! NSDictionary)["version"] as! String
        let name = payload["name"] as! String
        let organization = (payload["organization"] as! NSDictionary)["key"] as! String
        let application = (payload["application"] as! NSDictionary)["key"] as! String
        let namespace = payload["namespace"] as! String
        let version = payload["version"] as! String
        let description = payload["description"] as? String
        let baseUrl = payload["base_url"] as? String

        let unions: [Union]? = nil
//        if let unionsJson = payload["unions"] as? [AnyObject] {
//            unions = unionsJson.flatMap { u in
//                if let dict = u as? NSDictionary {
//                    return Union(u)
//                }
//                else {
//                    return nil
//                }
//
//            }
//        } else {
//            unions = nil
//        }

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

        self.init(apidoc: apidoc, name: name, organization: organization, application: application, namespace: namespace, version: version, baseUrl: baseUrl, description: description, enums: enums, unions: unions, models: models)
//
    }
}