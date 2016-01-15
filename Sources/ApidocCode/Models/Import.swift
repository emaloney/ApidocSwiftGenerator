//
//  Import.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/13/16.
//
//

import Foundation

public struct Import {
    let uri: String
    let namespace: String
    let organization: Organization
    let application: Application
    let version: String
    let enums: [String]?
    let unions: [String]?
    let models: [String]?

    public init(uri: String, namespace: String, organization: Organization, application: Application, version: String, enums: [String]?, unions: [String]?, models: [String]?) {
        self.uri = uri
        self.namespace = namespace
        self.organization = organization
        self.application = application
        self.version = version
        self.enums = enums
        self.unions = unions
        self.models = models
    }

    public init(payload: NSDictionary) {
        let uri = payload["uri"] as! String
        let namespace = payload["namespace"] as! String
        let organization = Organization(payload: payload["organization"] as! NSDictionary)
        let application = Application(payload: payload["application"] as! NSDictionary)
        let version = payload["version"] as! String
        let enums = payload["enums"] as? [String]
        let unions = payload["unions"] as? [String]
        let models = payload["models"] as? [String]

        self.init(uri: uri, namespace: namespace, organization: organization, application: application, version: version, enums: enums, unions: unions, models: models)
    }
}
